import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../data/video_info.dart';
import 'playback_proxy.dart';

/// A downloaded video: its file and the info to show while it plays offline.
class LocalVideo {
  const LocalVideo(this.path, this.info);

  final String path;
  final VideoInfo info;
}

/// How the current video is being played.
enum VideoSource { dash, muxed, hls, file }

/// The one video player of the app (docs/playback.md): ExoPlayer through `video_player`, fed a local DASH manifest
/// (HD), YouTube's muxed 360p stream, a live HLS playlist, or a downloaded file. It keeps playing in the background,
/// and [YouPipeAudioHandler] mirrors it to the media notification.
class VideoPlayerService {
  VideoPlayerService(this.infos);

  final VideoInfoService infos;

  /// The media session; set just after the first frame (main.dart), long before anything can play.
  YouPipeAudioHandler? handler;

  final controller = ValueNotifier<VideoPlayerController?>(null);
  final info = ValueNotifier<VideoInfo?>(null);
  final error = ValueNotifier<Object?>(null);

  /// The video being loaded or played (set before its info arrives).
  final videoId = ValueNotifier<String?>(null);
  VideoSource? source;
  int maxHeight = 1080;

  /// Fires the id of a video that played to its end (autoplay listens).
  final _completed = StreamController<String>.broadcast();
  Stream<String> get completed => _completed.stream;

  /// A downloaded copy of a video, played instead of streaming (set by the download manager).
  LocalVideo? Function(String videoId)? localVideo;

  /// Notification/headset next, previous and stop; set by the playback controller.
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  Future<void> Function()? onStop;

  int _loads = 0;

  /// The last load that failed, and why (so a recovery can tell a failure from being replaced by a newer [open]).
  (int, Object)? _failure;

  /// ExoPlayer can stall forever on a bad stream; give up and fall back instead.
  static const _initTimeout = Duration(seconds: 20);

  /// Re-resolves a video may use in a row before its error is shown (see [nextRecovery]).
  static const maxRecoveries = 3;

  /// How long to wait between tries while the device is offline (about 5 minutes in all).
  static const _offlineBackoff = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 60),
    Duration(seconds: 60),
    Duration(seconds: 60),
  ];

  /// The re-resolve count after one more mid-play failure at [at], or null to give up and show the error. [used]
  /// re-resolves were spent since the load that started at [from]; playing a minute past that point earns a fresh
  /// budget, so a long video can recover many times but a broken stream doesn't loop.
  @visibleForTesting
  static int? nextRecovery(int used, {required Duration from, required Duration at}) {
    final spent = at - from >= const Duration(minutes: 1) ? 0 : used;
    return spent < maxRecoveries ? spent + 1 : null;
  }

  static const _system = MethodChannel('youpipe/system');
  bool _awake = false;

  /// While a video plays the screen stays on and Wi-Fi stays out of power save (`youpipe/system` → `playing`).
  void _keepAwake(bool on) {
    if (on == _awake) return;
    _awake = on;
    _system.invokeMethod<void>('playing', {'playing': on}).catchError((Object e) {
      debugPrint('YouPipe: keep awake unavailable: $e');
    });
  }

  /// Loads [id] and starts it. Returns false when a newer [open] took over or loading failed (see [error]).
  /// [recoveries] counts the re-resolves already spent on this video (see [nextRecovery]).
  Future<bool> open(
    String id, {
    int? maxHeight,
    Duration start = Duration.zero,
    bool autoplay = true,
    double speed = 1,
    bool recovering = false,
    int recoveries = 0,
  }) async {
    final load = ++_loads;
    if (maxHeight != null) this.maxHeight = maxHeight;
    final height = this.maxHeight;
    error.value = null;
    _failure = null;
    videoId.value = id;
    if (!recovering) info.value = null;
    await _release();
    try {
      final sw = Stopwatch()..start();
      // A downloaded copy plays without touching the network.
      final local = localVideo?.call(id);
      final i = local != null && File(local.path).existsSync()
          ? local.info
          : await infos.get(id, maxHeight: height, forceRefresh: recovering).timeout(const Duration(seconds: 45));
      if (load != _loads) return false;
      info.value = i;
      final (c, s) = await _openController(i);
      debugPrint('YouPipe: player $id ready (${s.name}) after ${sw.elapsedMilliseconds}ms');
      if (load != _loads) {
        await c.dispose();
        return false;
      }
      source = s;
      controller.value = c;
      var failed = false;
      var finished = false;
      // Where playback got to. An error replaces the controller's value with one at 0:00 and speed 1, so a recovery
      // resumes from these (still the start point if it failed before the start seek landed).
      var lastPosition = start;
      var lastSpeed = speed;
      c.addListener(() {
        if (load != _loads) return;
        final v = c.value;
        handler?.sync(c, i);
        _keepAwake(v.isPlaying && !v.isCompleted && !v.hasError);
        if (!v.hasError && v.isInitialized) {
          if (v.position > Duration.zero) lastPosition = v.position;
          lastSpeed = v.playbackSpeed;
        }
        // A stream that fails mid-play (an expired or rejected URL, a stall, or the network dropping, often with the
        // screen off) gets fresh URLs, a few times in a row at most.
        if (v.hasError && !failed && s != VideoSource.file) {
          failed = true;
          final at = lastPosition;
          final next = nextRecovery(recoveries, from: start, at: at);
          debugPrint(
            'YouPipe: $id errored at ${at.inSeconds}s (${v.errorDescription}), '
            '${next == null ? 'giving up after $recoveries re-resolves' : 're-resolving ($next/$maxRecoveries)'}',
          );
          if (next != null) {
            unawaited(_recover(id, at, lastSpeed, next));
          } else {
            _showError(VideoUnavailable('PLAYBACK_FAILED', v.errorDescription ?? 'Playback failed'));
          }
          return;
        }
        if (v.isCompleted && !finished && !v.isLooping) {
          finished = true;
          _completed.add(id);
        } else if (!v.isCompleted) {
          finished = false;
        }
      });
      handler?.sync(c, i);
      if (speed != 1) await c.setPlaybackSpeed(speed);
      if (start > Duration.zero) await c.seekTo(start);
      if (autoplay) await c.play();
      return true;
    } catch (e) {
      if (load == _loads) {
        _failure = (load, e);
        // A recovery decides itself whether to show the error or wait for the network.
        if (!recovering) _showError(e);
      }
      debugPrint('YouPipe: open $id failed: $e');
      return false;
    }
  }

  void _showError(Object e) {
    error.value = e;
    _keepAwake(false);
  }

  /// Re-opens [id] at [at] after a mid-play failure. While the device is offline it keeps the video loading and
  /// tries again with backoff (the network often comes back when the screen turns on or Wi-Fi reconnects).
  Future<void> _recover(String id, Duration at, double speed, int recoveries) async {
    for (var attempt = 0; ; attempt++) {
      final ok = await open(id, start: at, speed: speed, recovering: true, recoveries: recoveries);
      if (ok) return;
      final failure = _failure;
      // Replaced by a newer open (another video, a tap on Retry): that one is in charge now.
      if (failure == null || failure.$1 != _loads) return;
      if (attempt >= _offlineBackoff.length || await _online()) {
        _showError(failure.$2);
        return;
      }
      debugPrint('YouPipe: offline, retrying $id in ${_offlineBackoff[attempt].inSeconds}s');
      handler?.waiting();
      await Future<void>.delayed(_offlineBackoff[attempt]);
      if (_loads != failure.$1) return;
    }
  }

  static Future<bool> _online() async {
    try {
      final r = await InternetAddress.lookup('www.youtube.com').timeout(const Duration(seconds: 5));
      return r.isNotEmpty;
    } on Object {
      return false;
    }
  }

  /// Test builds can skip the manifest to exercise the muxed stream and its relay
  /// (`--dart-define=FORCE_MUXED=true`, docs/testing.md).
  static const _forceMuxed = bool.fromEnvironment('FORCE_MUXED');

  /// A downloaded file first; then live → HLS; otherwise the HD manifest, falling back to the muxed stream if
  /// ExoPlayer rejects it.
  Future<(VideoPlayerController, VideoSource)> _openController(VideoInfo i) async {
    final options = VideoPlayerOptions(allowBackgroundPlayback: true);
    final local = localVideo?.call(i.videoId);
    if (local != null && File(local.path).existsSync()) {
      final c = VideoPlayerController.file(File(local.path), videoPlayerOptions: options);
      await c.initialize().timeout(_initTimeout);
      return (c, VideoSource.file);
    }
    if (i.isLive && i.hlsUrl != null) {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(i.hlsUrl!),
        formatHint: VideoFormat.hls,
        httpHeaders: {'User-Agent': i.hlsUserAgent},
        videoPlayerOptions: options,
      );
      await c.initialize().timeout(_initTimeout);
      return (c, VideoSource.hls);
    }
    if (i.manifestPath != null && !_forceMuxed) {
      // A file URI still goes through the plugin's HTTP data source, so the manifest's googlevideo requests carry
      // the User-Agent (docs/streaming.md).
      final c = VideoPlayerController.networkUrl(
        Uri.file(i.manifestPath!),
        formatHint: VideoFormat.dash,
        httpHeaders: {'User-Agent': i.dashUserAgent},
        videoPlayerOptions: options,
      );
      try {
        await c.initialize().timeout(_initTimeout);
        return (c, VideoSource.dash);
      } catch (e) {
        debugPrint('YouPipe: DASH failed for ${i.videoId}, using muxed: $e');
        unawaited(c.dispose());
      }
    }
    final url = i.muxedUrl ?? i.hlsUrl;
    if (url == null) throw VideoUnavailable('NO_STREAMS', 'Nothing playable for ${i.videoId}');
    // The progressive stream goes through the loopback relay, which fetches it in 1 MB ranges at full speed.
    final muxed = i.muxedUrl == null ? null : await PlaybackProxy.uriFor(i.muxedUrl!);
    final c = VideoPlayerController.networkUrl(
      muxed ?? Uri.parse(url),
      formatHint: i.muxedUrl == null ? VideoFormat.hls : null,
      httpHeaders: {'User-Agent': i.muxedUrl == null ? i.hlsUserAgent : i.muxedUserAgent},
      videoPlayerOptions: options,
    );
    await c.initialize().timeout(_initTimeout);
    return (c, i.muxedUrl == null ? VideoSource.hls : VideoSource.muxed);
  }

  /// Re-opens the current video at another quality, keeping position, speed and play state.
  Future<void> setMaxHeight(int height) async {
    final id = videoId.value;
    final c = controller.value;
    if (id == null) return;
    await open(
      id,
      maxHeight: height,
      start: c?.value.position ?? Duration.zero,
      autoplay: c?.value.isPlaying ?? true,
      speed: c?.value.playbackSpeed ?? 1,
    );
  }

  Future<void> _release() async {
    final c = controller.value;
    controller.value = null;
    source = null;
    await c?.dispose();
  }

  Future<void> stop() async {
    _loads++;
    info.value = null;
    videoId.value = null;
    error.value = null;
    _keepAwake(false);
    await _release();
    await handler?.cleared();
  }
}

/// Mirrors the video player to the media session: notification, lock screen, headset buttons, and keeps the
/// process in the foreground while a video plays in the background.
class YouPipeAudioHandler extends BaseAudioHandler with SeekHandler {
  YouPipeAudioHandler(this.service);

  final VideoPlayerService service;
  String? _itemId;

  VideoPlayerController? get _c => service.controller.value;

  void sync(VideoPlayerController c, VideoInfo info) {
    final v = c.value;
    if (_itemId != info.videoId || (mediaItem.value?.duration == null && v.duration > Duration.zero && !info.isLive)) {
      _itemId = info.videoId;
      mediaItem.add(
        MediaItem(
          id: info.videoId,
          title: info.title,
          artist: info.channelName,
          duration: info.isLive ? null : (v.duration > Duration.zero ? v.duration : info.duration),
          artUri: Uri.parse('https://i.ytimg.com/vi/${info.videoId}/hqdefault.jpg'),
        ),
      );
    }
    final AudioProcessingState state;
    if (v.hasError) {
      state = AudioProcessingState.error;
    } else if (!v.isInitialized) {
      state = AudioProcessingState.loading;
    } else if (v.isCompleted) {
      state = AudioProcessingState.completed;
    } else if (v.isBuffering) {
      state = AudioProcessingState.buffering;
    } else {
      state = AudioProcessingState.ready;
    }
    final playing = v.isPlaying && !v.isCompleted;
    final old = playbackState.value;
    // The listener fires many times a second; only push real changes plus a position update every second.
    if (old.playing == playing &&
        old.processingState == state &&
        old.speed == v.playbackSpeed &&
        (old.updatePosition - v.position).abs() < const Duration(seconds: 1)) {
      return;
    }
    playbackState.add(
      old.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: state,
        playing: playing,
        updatePosition: v.position,
        bufferedPosition: v.buffered.isEmpty ? v.position : v.buffered.last.end,
        speed: v.playbackSpeed,
      ),
    );
  }

  /// Waiting for the network to re-open the video: still "playing" (the service stays in the foreground).
  void waiting() {
    playbackState.add(playbackState.value.copyWith(playing: true, processingState: AudioProcessingState.buffering));
  }

  /// Nothing is playing any more: ends the session and removes the notification.
  Future<void> cleared() async {
    _itemId = null;
    final old = playbackState.value;
    if (old.playing) {
      // audio_service detaches the notification from the foreground service when playback stops, and Android applies
      // that a moment later. Going idle straight away cancelled the notification first, and the detach then brought
      // it back: a stale "Pause" notification after Stop, or after closing the mini player, while a video played.
      playbackState.add(old.copyWith(playing: false));
      await Future<void>.delayed(_detachDelay);
      // A new video started meanwhile.
      if (_itemId != null) return;
    }
    playbackState.add(playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.idle));
  }

  static const _detachDelay = Duration(milliseconds: 500);

  @override
  Future<void> play() async => _c?.play();

  @override
  Future<void> pause() async => _c?.pause();

  @override
  Future<void> seek(Duration position) async => _c?.seekTo(position);

  @override
  Future<void> skipToNext() async => service.onNext?.call();

  @override
  Future<void> skipToPrevious() async => service.onPrevious?.call();

  @override
  Future<void> fastForward() async {
    final c = _c;
    if (c != null) await c.seekTo(c.value.position + const Duration(seconds: 10));
  }

  @override
  Future<void> rewind() async {
    final c = _c;
    if (c != null) await c.seekTo(c.value.position - const Duration(seconds: 10));
  }

  /// Notification Stop closes the video like the mini player's close button. [cleared] ends the session, so
  /// [BaseAudioHandler.stop], which goes idle straight away, isn't called.
  @override
  Future<void> stop() async => await (service.onStop ?? service.stop)();

  /// Swiping the app away in Recents closes the video, like YouTube (audio_service's default does nothing, so the
  /// foreground service kept it playing).
  @override
  Future<void> onTaskRemoved() => stop();
}

/// Picture-in-picture (`youpipe/pip`, MainActivity.kt). While armed, leaving the app shrinks it to a PiP window.
class Pip {
  Pip._() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'changed':
          active.value = call.arguments == true;
        case 'closed':
          onClosed?.call();
      }
    });
  }

  static final instance = Pip._();
  static const _channel = MethodChannel('youpipe/pip');

  /// Whether the app is in a PiP window right now; the app then shows only the video.
  final active = ValueNotifier(false);

  /// The PiP window was closed (not expanded back into the app); set in main.dart to stop the video.
  VoidCallback? onClosed;

  Future<void> arm(bool enabled, {Size aspect = const Size(16, 9)}) => _channel.invokeMethod('arm', {
    'enabled': enabled,
    'width': aspect.width.round(),
    'height': aspect.height.round(),
  });

  Future<bool> enter() async => await _channel.invokeMethod<bool>('enter') ?? false;
}
