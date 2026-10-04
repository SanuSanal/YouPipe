import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'cast.dart';

/// DLNA (UPnP AV) casting, for smart TVs and speakers without Google Cast (docs/cast.md).
///
/// Renderers are found with SSDP and driven over SOAP (AVTransport, RenderingControl). The audio
/// comes from the phone's relay (CastProxy.kt), as for Chromecast.
const _avTransport = 'urn:schemas-upnp-org:service:AVTransport:1';
const _renderingControl = 'urn:schemas-upnp-org:service:RenderingControl:1';

/// Must match CastProxy.DLNA_FEATURES: byte seeking allowed, streaming transfer.
const _dlnaFeatures = 'DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000';

@immutable
class DlnaRenderer {
  const DlnaRenderer({required this.udn, required this.name, required this.avTransport, this.renderingControl});

  final String udn;
  final String name;
  final Uri avTransport;
  final Uri? renderingControl;

  /// Finds MediaRenderers on the LAN (SSDP M-SEARCH) and reads their device descriptions.
  static Future<List<DlnaRenderer>> discover({Duration timeout = const Duration(seconds: 3)}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final locations = <String>{};
    final location = RegExp(r'^location:\s*(\S+)', caseSensitive: false, multiLine: true);
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final match = location.firstMatch(utf8.decode(datagram.data, allowMalformed: true));
      if (match != null) locations.add(match.group(1)!);
    });
    final search = utf8.encode(
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 2\r\n'
      'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n',
    );
    final group = InternetAddress('239.255.255.250');
    socket.send(search, group, 1900);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    socket.send(search, group, 1900); // UDP may drop the first one
    await Future<void>.delayed(timeout);
    socket.close();

    final renderers = await Future.wait(locations.map(_describe));
    final seen = <String>{};
    return [
      for (final r in renderers)
        if (r != null && seen.add(r.udn)) r,
    ];
  }

  static Future<DlnaRenderer?> _describe(String location) async {
    try {
      final doc = XmlDocument.parse(await _get(Uri.parse(location)));
      String? text(XmlElement e, String name) => e.getElement(name)?.innerText.trim();
      final urlBase = doc.findAllElements('URLBase').firstOrNull?.innerText.trim();
      final base = Uri.parse(urlBase == null || urlBase.isEmpty ? location : urlBase);
      Uri? control(String type) {
        for (final s in doc.findAllElements('service')) {
          final url = text(s, 'controlURL');
          if (text(s, 'serviceType') == type && url != null) return base.resolve(url);
        }
        return null;
      }

      final av = control(_avTransport);
      if (av == null) return null;
      final device = doc.findAllElements('device').first;
      return DlnaRenderer(
        udn: text(device, 'UDN') ?? location,
        name: text(device, 'friendlyName') ?? base.host,
        avTransport: av,
        renderingControl: control(_renderingControl),
      );
    } catch (e) {
      debugPrint('YouPipe: DLNA device at $location: $e');
      return null;
    }
  }
}

/// A connection to one renderer, following it by polling (renderers can't push to us here).
class DlnaSession implements RemotePlayback {
  DlnaSession(this.renderer, {required this.onEnded})
    : _status = ValueNotifier(CastStatus(state: CastState.connecting, device: renderer.name));

  final DlnaRenderer renderer;

  /// The renderer stopped answering (turned off, left the network).
  final VoidCallback onEnded;

  final ValueNotifier<CastStatus> _status;
  final _player = StreamController<RemotePlayer>.broadcast();
  Timer? _poll;
  bool _polling = false;
  int _failures = 0;
  int _ticks = 0;

  String? _url;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _sawPlaying = false;

  /// Renderers only seek once playing, so a start position waits for that.
  Duration? _pendingSeek;

  @override
  ValueListenable<CastStatus> get status => _status;

  @override
  Stream<RemotePlayer> get player => _player.stream;

  Future<void> connect() async {
    try {
      await _transportState();
    } catch (e) {
      debugPrint('YouPipe: ${renderer.name} is not answering: $e');
      onEnded();
      return;
    }
    await CastRelay.start();
    final volume = await _volume();
    _status.value = CastStatus(
      state: CastState.connected,
      device: renderer.name,
      volume: volume ?? 0,
      volumeControl: volume != null && await _canSetVolume(volume),
    );
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  Future<void> close() async {
    _poll?.cancel();
    _poll = null;
    try {
      await _av('Stop');
    } catch (_) {}
    await CastRelay.stop();
    _status.value = const CastStatus();
    await _player.close();
  }

  @override
  Future<String?> load({
    required MediaItem item,
    String? localPath,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async {
    final relay = await CastRelay.url(item.id, localPath);
    _url = relay.url;
    _sawPlaying = false;
    _position = position;
    _duration = item.duration;
    _pendingSeek = position > Duration.zero ? position : null;
    try {
      await _av('Stop');
    } catch (_) {}
    await _av('SetAVTransportURI', {
      'CurrentURI': relay.url,
      'CurrentURIMetaData': _didl(item, relay.url, relay.contentType),
    });
    if (autoplay) await play();
    return relay.url;
  }

  @override
  Future<void> play() async => _av('Play', {'Speed': '1'});

  @override
  Future<void> pause() async => _av('Pause');

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    await _av('Seek', {'Unit': 'REL_TIME', 'Target': _hms(position)});
  }

  @override
  Future<void> setVolume(double volume) async {
    final control = renderer.renderingControl;
    if (control == null) return;
    final v = volume.clamp(0.0, 1.0);
    await _soap(control, _renderingControl, 'SetVolume', {
      'InstanceID': '0',
      'Channel': 'Master',
      'DesiredVolume': '${(v * 100).round()}',
    });
    _status.value = _status.value.copyWith(volume: v);
  }

  Future<void> _refresh() async {
    if (_polling || _poll == null) return;
    _polling = true;
    try {
      final state = await _transportState();
      final info = await _av('GetPositionInfo');
      _failures = 0;
      if (++_ticks % 5 == 0) {
        final volume = await _volume();
        if (volume != null) _status.value = _status.value.copyWith(volume: volume);
      }
      final RemotePlayer update;
      switch (state) {
        case 'PLAYING' || 'PAUSED_PLAYBACK':
          final playing = state == 'PLAYING';
          if (playing) _sawPlaying = true;
          _position = _parseTime(_text(info, 'RelTime')) ?? _position;
          _duration = _parseTime(_text(info, 'TrackDuration')) ?? _duration;
          final pending = _pendingSeek;
          if (playing && pending != null) {
            _pendingSeek = null;
            unawaited(seek(pending).catchError((Object e) => debugPrint('YouPipe: DLNA seek failed: $e')));
          }
          update = RemotePlayer(
            state: playing ? RemoteState.playing : RemoteState.paused,
            position: _position,
            duration: _duration,
            url: _url,
          );
        case 'TRANSITIONING':
          update = RemotePlayer(state: RemoteState.buffering, position: _position, duration: _duration, url: _url);
        default:
          // STOPPED or NO_MEDIA_PRESENT. Right after playing near the end means the video finished;
          // otherwise it was stopped on the TV.
          final duration = _duration;
          final nearEnd = duration != null && _position >= duration - const Duration(seconds: 5);
          update = RemotePlayer(
            state: RemoteState.idle,
            idleReason: _sawPlaying ? (nearEnd ? 'finished' : 'canceled') : null,
            position: _position,
            duration: _duration,
            url: _url,
          );
      }
      // A poll that was already running when the session closed has nowhere to report.
      if (_poll != null) _player.add(update);
    } catch (e) {
      if (++_failures >= 5) {
        debugPrint('YouPipe: lost ${renderer.name}: $e');
        onEnded();
      }
    } finally {
      _polling = false;
    }
  }

  /// Sets the volume it already has, to find out whether the renderer allows it at all.
  Future<bool> _canSetVolume(double current) async {
    try {
      await setVolume(current);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _transportState() async =>
      _text(await _av('GetTransportInfo'), 'CurrentTransportState') ?? 'NO_MEDIA_PRESENT';

  Future<double?> _volume() async {
    final control = renderer.renderingControl;
    if (control == null) return null;
    try {
      final doc = await _soap(control, _renderingControl, 'GetVolume', {'InstanceID': '0', 'Channel': 'Master'});
      final v = int.tryParse(_text(doc, 'CurrentVolume') ?? '');
      return v == null ? null : v / 100;
    } catch (_) {
      return null;
    }
  }

  Future<XmlDocument> _av(String action, [Map<String, String> args = const {}]) =>
      _soap(renderer.avTransport, _avTransport, action, {'InstanceID': '0', ...args});
}

/// DIDL-Lite metadata, so the TV shows the title, channel and thumbnail.
String _didl(MediaItem item, String url, String contentType) {
  final artist = item.artist;
  final album = item.album;
  final art = httpArt(item);
  final duration = item.duration == null ? '' : ' duration="${_hms(item.duration!)}.000"';
  return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
      '<item id="0" parentID="-1" restricted="1">'
      '<dc:title>${_escape(item.title)}</dc:title>'
      '${artist == null ? '' : '<dc:creator>${_escape(artist)}</dc:creator><upnp:artist>${_escape(artist)}</upnp:artist>'}'
      '${album == null ? '' : '<upnp:album>${_escape(album)}</upnp:album>'}'
      '${art == null ? '' : '<upnp:albumArtURI>${_escape(art)}</upnp:albumArtURI>'}'
      '<upnp:class>object.item.videoItem.movie</upnp:class>'
      '<res protocolInfo="http-get:*:$contentType:$_dlnaFeatures"$duration>${_escape(url)}</res>'
      '</item></DIDL-Lite>';
}

Future<XmlDocument> _soap(Uri control, String service, String action, Map<String, String> args) async {
  final body =
      '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
      's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
      '<u:$action xmlns:u="$service">'
      '${args.entries.map((e) => '<${e.key}>${_escape(e.value)}</${e.key}>').join()}'
      '</u:$action></s:Body></s:Envelope>';
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  try {
    final request = await client.postUrl(control);
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/xml; charset="utf-8"')
      ..set('SOAPACTION', '"$service#$action"');
    request.add(utf8.encode(body));
    final response = await request.close().timeout(const Duration(seconds: 6));
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw HttpException('$action: HTTP ${response.statusCode}', uri: control);
    return XmlDocument.parse(text);
  } finally {
    client.close(force: true);
  }
}

Future<String> _get(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  try {
    final response = await (await client.getUrl(url)).close().timeout(const Duration(seconds: 6));
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}

String? _text(XmlDocument doc, String name) => doc.findAllElements(name).firstOrNull?.innerText.trim();

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String _hms(Duration d) =>
    '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// `H:MM:SS[.fff]`; null for missing or `NOT_IMPLEMENTED` values.
Duration? _parseTime(String? s) {
  final m = RegExp(r'^(\d+):(\d{1,2}):(\d{1,2})(?:\.(\d+))?').firstMatch(s ?? '');
  if (m == null) return null;
  final ms = int.parse((m.group(4) ?? '0').padRight(3, '0').substring(0, 3));
  return Duration(
    hours: int.parse(m.group(1)!),
    minutes: int.parse(m.group(2)!),
    seconds: int.parse(m.group(3)!),
    milliseconds: ms,
  );
}

@visibleForTesting
Duration? parseDlnaTime(String? s) => _parseTime(s);

@visibleForTesting
String formatDlnaTime(Duration d) => _hms(d);
