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

  /// Notification/headset next and previous; set by the playback controller.
  VoidCallback? onNext;
  VoidCallback? onPrevious;

  int _loads = 0;

  /// ExoPlayer can stall forever on a bad stream; give up and fall back instead.
  static const _initTimeout = Duration(seconds: 20);

  /// Loads [id] and starts it. Returns false when a newer [open] took over or loading failed (see [error]).
  Future<bool> open(
    String id, {
    int? maxHeight,
    Duration start = Duration.zero,
    bool autoplay = true,
    double speed = 1,
    bool recovering = false,
  }) async {
    final load = ++_loads;
    if (maxHeight != null) this.maxHeight = maxHeight;
    final height = this.maxHeight;
    error.value = null;
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
      var recovered = recovering;
      var finished = false;
      c.addListener(() {
        if (load != _loads) return;
        final v = c.value;
        handler?.sync(c, i);
        // A stream that fails mid-play (usually a 403 on expired or rejected URLs) gets fresh URLs once.
        if (v.hasError && !recovered && s != VideoSource.file) {
          recovered = true;
          final at = v.position;
          debugPrint('YouPipe: $id errored at ${at.inSeconds}s (${v.errorDescription}), re-resolving');
          open(id, start: at, autoplay: true, speed: v.playbackSpeed, recovering: true);
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
      if (load == _loads) error.value = e;
      debugPrint('YouPipe: open $id failed: $e');
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
    await _release();
    handler?.cleared();
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

  void cleared() {
    _itemId = null;
    playbackState.add(playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.idle));
  }

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

  @override
  Future<void> stop() async {
    await service.stop();
    await super.stop();
  }
}

/// Picture-in-picture (`youpipe/pip`, MainActivity.kt). While armed, leaving the app shrinks it to a PiP window.
class Pip {
  Pip._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') active.value = call.arguments == true;
    });
  }

  static final instance = Pip._();
  static const _channel = MethodChannel('youpipe/pip');

  /// Whether the app is in a PiP window right now; the app then shows only the video.
  final active = ValueNotifier(false);

  Future<void> arm(bool enabled, {Size aspect = const Size(16, 9)}) => _channel.invokeMethod('arm', {
    'enabled': enabled,
    'width': aspect.width.round(),
    'height': aspect.height.round(),
  });

  Future<bool> enter() async => await _channel.invokeMethod<bool>('enter') ?? false;
}
