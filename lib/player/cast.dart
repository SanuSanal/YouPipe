import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'dlna.dart';

/// Casting to Chromecast (Google Cast SDK) and DLNA renderers such as smart TVs (docs/cast.md).
enum CastState {
  /// Nothing to cast to.
  none,

  /// Devices found, not casting.
  available,
  connecting,
  connected,
}

@immutable
class CastStatus {
  const CastStatus({this.state = CastState.none, this.device, this.volume = 0, this.volumeControl = true});

  factory CastStatus.fromMap(Map<Object?, Object?> m) => CastStatus(
    state: CastState.values.byName(m['state'] as String? ?? 'none'),
    device: m['device'] as String?,
    volume: (m['volume'] as num?)?.toDouble() ?? 0,
  );

  final CastState state;

  /// The receiver's name while connected, e.g. "Living Room TV".
  final String? device;

  /// Receiver volume, 0..1.
  final double volume;

  /// Whether the receiver lets us set its volume (many Samsung TVs refuse it over DLNA).
  final bool volumeControl;

  bool get connected => state == CastState.connected;

  CastStatus copyWith({CastState? state, String? device, double? volume, bool? volumeControl}) => CastStatus(
    state: state ?? this.state,
    device: device ?? this.device,
    volume: volume ?? this.volume,
    volumeControl: volumeControl ?? this.volumeControl,
  );

  @override
  bool operator ==(Object other) =>
      other is CastStatus &&
      other.state == state &&
      other.device == device &&
      other.volume == volume &&
      other.volumeControl == volumeControl;

  @override
  int get hashCode => Object.hash(state, device, volume, volumeControl);
}

enum RemoteState { idle, buffering, playing, paused }

/// One status update from the receiver's player.
@immutable
class RemotePlayer {
  const RemotePlayer({required this.state, this.idleReason, this.position = Duration.zero, this.duration, this.url});

  factory RemotePlayer.fromMap(Map<Object?, Object?> m) => RemotePlayer(
    state: RemoteState.values.byName(m['state'] as String? ?? 'idle'),
    idleReason: m['idleReason'] as String?,
    position: Duration(milliseconds: (m['positionMs'] as num?)?.toInt() ?? 0),
    duration: switch ((m['durationMs'] as num?)?.toInt()) {
      final ms? when ms > 0 => Duration(milliseconds: ms),
      _ => null,
    },
    url: m['url'] as String?,
  );

  final RemoteState state;

  /// Why the player went idle: `finished`, `error`, `canceled` or `interrupted`.
  final String? idleReason;
  final Duration position;
  final Duration? duration;

  /// The relay URL of the loaded video (as returned by [RemotePlayback.load]).
  final String? url;

  bool get playing => state == RemoteState.playing;
  bool get finished => state == RemoteState.idle && idleReason == 'finished';
  bool get failed => state == RemoteState.idle && idleReason == 'error';

  /// How the notification and the rest of the app should see this state.
  AudioProcessingState get processingState => switch (state) {
    RemoteState.buffering => AudioProcessingState.buffering,
    RemoteState.playing || RemoteState.paused => AudioProcessingState.ready,
    RemoteState.idle when failed => AudioProcessingState.error,
    RemoteState.idle when finished => AudioProcessingState.completed,
    RemoteState.idle => AudioProcessingState.loading,
  };
}

/// What the audio handler needs from a cast session; [CastController] in the app, a fake in tests.
abstract class RemotePlayback {
  ValueListenable<CastStatus> get status;
  Stream<RemotePlayer> get player;

  /// Loads one video on the receiver; returns its relay URL, which [RemotePlayer.url] repeats.
  Future<String?> load({
    required MediaItem item,
    String? localPath,
    Duration position = Duration.zero,
    bool autoplay = true,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
}

enum CastKind { chromecast, dlna }

/// A device in the Cast sheet.
@immutable
class CastDevice {
  const CastDevice({required this.id, required this.name, required this.kind, this.dlna});

  final String id;
  final String name;
  final CastKind kind;

  /// Set for DLNA devices.
  final DlnaRenderer? dlna;

  @override
  bool operator ==(Object other) => other is CastDevice && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// The phone-side audio relay (CastProxy.kt), shared by Chromecast and DLNA.
abstract final class CastRelay {
  static const channel = MethodChannel('youpipe/cast');

  /// Starts the relay and keeps Wi-Fi and the CPU awake while casting.
  static Future<void> start() => channel.invokeMethod('relayStart');

  static Future<void> stop() => channel.invokeMethod('relayStop');

  /// A URL on this phone that serves the video to devices on the LAN, and its content type.
  static Future<({String url, String contentType})> url(String videoId, String? localPath) async {
    final r = await channel.invokeMapMethod<String, Object?>('relayUrl', {'videoId': videoId, 'localPath': localPath});
    return (url: r!['url'] as String, contentType: r['contentType'] as String);
  }
}

/// Chromecast through CastChannel.kt.
class _Chromecast {
  _Chromecast() {
    _events.receiveBroadcastStream().listen((e) {
      final m = e as Map<Object?, Object?>;
      switch (m['type']) {
        case 'state':
          status.value = CastStatus.fromMap(m);
        case 'player':
          player.add(RemotePlayer.fromMap(m));
        case 'routes':
          devices.value = [
            for (final r in (m['routes'] as List).cast<Map<Object?, Object?>>())
              CastDevice(id: r['id'] as String, name: r['name'] as String, kind: CastKind.chromecast),
          ];
      }
    }, onError: (Object e) => debugPrint('YouPipe: cast events failed: $e'));
  }

  static const _events = EventChannel('youpipe/cast/events');
  static const _methods = CastRelay.channel;

  final status = ValueNotifier(const CastStatus());
  final devices = ValueNotifier<List<CastDevice>>(const []);
  final player = StreamController<RemotePlayer>.broadcast();

  Future<void> connect(CastDevice device) => _methods.invokeMethod('selectRoute', {'id': device.id});
  Future<void> disconnect() => _methods.invokeMethod('disconnect');

  Future<String?> load({
    required MediaItem item,
    String? localPath,
    required Duration position,
    required bool autoplay,
  }) => _methods.invokeMethod<String>('load', {
    'videoId': item.id,
    'localPath': localPath,
    'title': item.title,
    'artist': item.artist,
    'album': item.album,
    'artUrl': httpArt(item),
    'durationMs': item.duration?.inMilliseconds,
    'positionMs': position.inMilliseconds,
    'autoplay': autoplay,
  });

  Future<void> play() => _methods.invokeMethod('play');
  Future<void> pause() => _methods.invokeMethod('pause');
  Future<void> seek(Duration p) => _methods.invokeMethod('seek', {'positionMs': p.inMilliseconds});
  Future<void> setVolume(double v) => _methods.invokeMethod('setVolume', {'volume': v.clamp(0.0, 1.0)});
}

/// Artwork a receiver can fetch (local artwork paths mean nothing to it).
String? httpArt(MediaItem item) => item.artUri?.scheme.startsWith('http') == true ? item.artUri.toString() : null;

/// Everything casting in one place: the device list (Chromecast and DLNA), the connection, and the
/// [RemotePlayback] the cast bridge drives. Only one device is connected at a time.
class CastController with WidgetsBindingObserver implements RemotePlayback {
  CastController() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _chromecast = _Chromecast();
    _chromecast!.status.addListener(_update);
    _chromecast!.devices.addListener(_update);
    _chromecast!.player.stream.listen((p) {
      if (_chromecast!.status.value.connected) _player.add(p);
    });
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  _Chromecast? _chromecast;
  DlnaSession? _dlna;
  StreamSubscription<RemotePlayer>? _dlnaPlayer;
  List<CastDevice> _dlnaDevices = const [];
  bool _searching = false;

  final _status = ValueNotifier(const CastStatus());
  final _player = StreamController<RemotePlayer>.broadcast();

  /// Devices for the Cast sheet, Chromecasts first.
  final devices = ValueNotifier<List<CastDevice>>(const []);

  /// The device being cast to, if any.
  final connectedDevice = ValueNotifier<CastDevice?>(null);

  @override
  ValueListenable<CastStatus> get status => _status;

  @override
  Stream<RemotePlayer> get player => _player.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// Looks for DLNA renderers again (Chromecasts are found by the Cast SDK while the app is open).
  Future<void> refresh() async {
    if (_searching) return;
    _searching = true;
    try {
      final found = await DlnaRenderer.discover();
      _dlnaDevices = [for (final r in found) CastDevice(id: r.udn, name: r.name, kind: CastKind.dlna, dlna: r)];
      _update();
    } catch (e) {
      debugPrint('YouPipe: DLNA discovery failed: $e');
    } finally {
      _searching = false;
    }
  }

  Future<void> connect(CastDevice device) async {
    if (connectedDevice.value == device) return;
    await disconnect();
    connectedDevice.value = device;
    if (device.kind == CastKind.chromecast) {
      await _chromecast?.connect(device);
      return;
    }
    final session = DlnaSession(device.dlna!, onEnded: _onDlnaEnded);
    _dlna = session;
    session.status.addListener(_update);
    _dlnaPlayer = session.player.listen(_player.add);
    _update();
    await session.connect();
  }

  Future<void> disconnect() async {
    final dlna = _dlna;
    _dlna = null;
    if (dlna != null) {
      dlna.status.removeListener(_update);
      await _dlnaPlayer?.cancel();
      _dlnaPlayer = null;
      await dlna.close();
    }
    if (_chromecast?.status.value.state case CastState.connected || CastState.connecting) {
      await _chromecast?.disconnect();
    }
    connectedDevice.value = null;
    _update();
  }

  void _onDlnaEnded() => unawaited(disconnect());

  void _update() {
    final chromecast = _chromecast?.status.value ?? const CastStatus();
    final dlna = _dlna?.status.value;
    devices.value = [...?_chromecast?.devices.value, ..._dlnaDevices];
    if (chromecast.state == CastState.connected || chromecast.state == CastState.connecting) {
      _status.value = chromecast;
      if (connectedDevice.value?.kind != CastKind.chromecast) {
        connectedDevice.value = devices.value
            .where((d) => d.kind == CastKind.chromecast && d.name == chromecast.device)
            .firstOrNull;
      }
    } else if (dlna != null) {
      _status.value = dlna;
    } else {
      if (connectedDevice.value?.kind == CastKind.chromecast) connectedDevice.value = null;
      _status.value = CastStatus(state: devices.value.isEmpty ? CastState.none : CastState.available);
    }
  }

  RemotePlayback? get _active =>
      _dlna ?? (_chromecast?.status.value.connected == true ? _ChromecastPlayback(this) : null);

  @override
  Future<String?> load({
    required MediaItem item,
    String? localPath,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async => _active?.load(item: item, localPath: localPath, position: position, autoplay: autoplay);

  @override
  Future<void> play() => _command('play', (p) => p.play());

  @override
  Future<void> pause() => _command('pause', (p) => p.pause());

  /// Some renderers refuse seeking (Samsung TVs over DLNA); the video then carries on where it was.
  @override
  Future<void> seek(Duration position) => _command('seek', (p) => p.seek(position));

  @override
  Future<void> setVolume(double volume) => _command('volume', (p) => p.setVolume(volume.clamp(0.0, 1.0)));

  /// Transport commands never throw: a device that refuses one just keeps its state, which the
  /// next status update shows.
  Future<void> _command(String name, Future<void> Function(RemotePlayback p) run) async {
    final active = _active;
    if (active == null) return;
    try {
      await run(active);
    } catch (e) {
      debugPrint('YouPipe: cast $name failed: $e');
    }
  }
}

/// The Chromecast side of [CastController] as a [RemotePlayback].
class _ChromecastPlayback implements RemotePlayback {
  _ChromecastPlayback(this._c);

  final CastController _c;

  _Chromecast get _cc => _c._chromecast!;

  @override
  ValueListenable<CastStatus> get status => _cc.status;

  @override
  Stream<RemotePlayer> get player => _cc.player.stream;

  @override
  Future<String?> load({
    required MediaItem item,
    String? localPath,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) => _cc.load(item: item, localPath: localPath, position: position, autoplay: autoplay);

  @override
  Future<void> play() => _cc.play();

  @override
  Future<void> pause() => _cc.pause();

  @override
  Future<void> seek(Duration position) => _cc.seek(position);

  @override
  Future<void> setVolume(double volume) => _cc.setVolume(volume);
}
