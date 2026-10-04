import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../data/video_info.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/layout.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../util/format.dart';
import 'player_settings.dart';
import 'seek_bar.dart';

/// Just the video picture, letterboxed in black (also used by the mini player and PiP).
class VideoSurface extends ConsumerWidget {
  const VideoSurface({super.key, this.fit = BoxFit.contain});

  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(playerControllerProvider);
    final playing = ref.watch(playbackProvider);
    return ColoredBox(
      color: Colors.black,
      child: c == null || !c.value.isInitialized
          ? (playing == null
                ? const SizedBox.expand()
                : Image.network(
                    playing.video.thumbnailOrDefault,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => const SizedBox.expand(),
                  ))
          : SizedBox.expand(
              child: FittedBox(
                fit: fit,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
              ),
            ),
    );
  }
}

/// The player with YouTube's controls.
class PlayerView extends ConsumerStatefulWidget {
  const PlayerView({super.key, required this.onMinimize, this.fullscreen = false});

  final VoidCallback onMinimize;
  final bool fullscreen;

  @override
  ConsumerState<PlayerView> createState() => _PlayerViewState();
}

/// Set by the cast feature: what the player area shows while casting.
Widget Function(BuildContext context, WidgetRef ref, RemoteControls remote, VideoItem? video)? castingViewBuilder;

/// The Cast button for the player's top row (set by the cast feature).
Widget Function()? playerCastButton;

class _PlayerViewState extends ConsumerState<PlayerView> {
  bool _visible = true;
  Timer? _hide;
  // Double-tap seek feedback.
  int _seekSide = 0;
  int _seekSeconds = 0;
  Timer? _seekReset;
  bool _boost = false;

  /// A short message over the video ("Autoplay is on"), like YouTube's.
  String? _flash;
  Timer? _flashReset;

  /// The player itself, focused while its controls are hidden (TV remote, keyboards); see [_onKey].
  final _playerFocus = FocusNode(debugLabel: 'player');
  final _playPauseFocus = FocusNode(debugLabel: 'play/pause');

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    _seekReset?.cancel();
    _flashReset?.cancel();
    _playerFocus.dispose();
    _playPauseFocus.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      final c = ref.read(playerControllerProvider);
      if (!mounted || !(c?.value.isPlaying ?? false)) return;
      // A control with focus is about to be hidden: give focus back to the player, so the remote keeps working.
      final inControls = _playerFocus.hasFocus && !_playerFocus.hasPrimaryFocus;
      setState(() => _visible = false);
      if (inControls) _playerFocus.requestFocus();
    });
  }

  /// Shows the controls with play/pause focused (once they're focusable again, after this frame).
  void _showControls() {
    setState(() => _visible = true);
    _scheduleHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playPauseFocus.requestFocus();
    });
  }

  void _togglePlay() {
    final c = ref.read(playerControllerProvider);
    if (c == null) return;
    final v = c.value;
    if (v.isCompleted) {
      ref.read(upNextCountdownProvider.notifier).cancel();
      c.seekTo(Duration.zero);
      c.play();
    } else {
      v.isPlaying ? c.pause() : c.play();
    }
    _scheduleHide();
  }

  /// The remote and keyboards (docs/ui.md). Media keys always work. While the player itself has focus (controls
  /// hidden): Select shows the controls, Left/Right seek 10 s, Up (and Down in fullscreen) show the controls; Down
  /// on the watch page moves on to the details. While a control has focus, any key keeps the controls up.
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    final c = ref.read(playerControllerProvider);
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay || key == LogicalKeyboardKey.mediaPause) {
      key == LogicalKeyboardKey.mediaPlay ? c?.play() : c?.pause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaRewind) {
      _seekStep(key == LogicalKeyboardKey.mediaFastForward ? 1 : -1);
      return KeyEventResult.handled;
    }
    if (!node.hasPrimaryFocus) {
      if (_visible) _scheduleHide();
      return KeyEventResult.ignored;
    }
    final select =
        key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.gameButtonA;
    if (select || key == LogicalKeyboardKey.arrowUp || (key == LogicalKeyboardKey.arrowDown && widget.fullscreen)) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (!_visible && (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight)) {
      _seekStep(key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _toggle() {
    setState(() => _visible = !_visible);
    if (_visible) _scheduleHide();
  }

  void _showFlash(String message) {
    setState(() => _flash = message);
    _flashReset?.cancel();
    _flashReset = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  /// YouTube's Autoplay switch in the player (docs/playback.md); off also cancels a running countdown.
  void _toggleAutoplay() {
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(s.copyWith(autoplay: !s.autoplay));
    if (s.autoplay) ref.read(upNextCountdownProvider.notifier).cancel();
    _showFlash(s.autoplay ? 'Autoplay is off' : 'Autoplay is on');
    _scheduleHide();
  }

  void _doubleTap(TapDownDetails d, double width) => _seekStep(d.localPosition.dx < width / 2 ? -1 : 1);

  /// Seeks 10 s back (-1) or forward (1), with YouTube's ripple counting up on repeats.
  void _seekStep(int side) {
    final c = ref.read(playerControllerProvider);
    if (c == null) return;
    final seconds = side == _seekSide ? _seekSeconds + 10 : 10;
    setState(() {
      _seekSide = side;
      _seekSeconds = seconds;
    });
    c.seekTo(c.value.position + Duration(seconds: 10 * side));
    _seekReset?.cancel();
    _seekReset = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _seekSide = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = remoteControlsOf?.call(ref);
    if (remote != null && castingViewBuilder != null) {
      return castingViewBuilder!(context, ref, remote, ref.watch(playbackProvider)?.video);
    }
    final c = ref.watch(playerControllerProvider);
    final error = ref.watch(playerErrorProvider);
    final countdown = ref.watch(upNextCountdownProvider);
    // A cancelled countdown leaves the ended video with its controls (and replay button) showing, like YouTube.
    ref.listen(upNextCountdownProvider, (before, now) {
      if (before == null && now != null) {
        // The card hides the controls: a control with focus hands it to the player first, so excluding the controls
        // doesn't drop focus over the card's Play now request (seen on the TV).
        if (_playerFocus.hasFocus && !_playerFocus.hasPrimaryFocus) _playerFocus.requestFocus();
        return;
      }
      if (before == null || now != null) return;
      if (ref.read(playerControllerProvider)?.value.isCompleted ?? false) {
        _showControls();
      } else if (DeviceInfo.current.tv) {
        // The next video started: the remote's focus goes back to the player (Play now has gone).
        _playerFocus.requestFocus();
      }
    });
    // The Up next card covers the controls.
    final controlsShown = _visible && countdown == null;
    return Focus(
      focusNode: _playerFocus,
      // On a TV (and in fullscreen) the player takes focus, so the remote controls it straight away.
      autofocus: widget.fullscreen || DeviceInfo.current.tv,
      // Under the Up next card the arrows move between its buttons only (the player, as wide as the screen, is
      // otherwise the nearest thing to the left of Play now).
      skipTraversal: countdown != null,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          onDoubleTapDown: (d) => _doubleTap(d, box.maxWidth),
          onDoubleTap: () {},
          // Hold for 2x speed, like YouTube.
          onLongPressStart: (_) {
            final v = c?.value;
            if (v == null || !v.isPlaying) return;
            setState(() => _boost = true);
            c!.setPlaybackSpeed(2);
          },
          onLongPressEnd: (_) {
            if (!_boost) return;
            setState(() => _boost = false);
            c?.setPlaybackSpeed(1);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              const VideoSurface(),
              if (c != null && c.value.isInitialized)
                CaptionOverlay(controller: c, bottom: _visible ? (widget.fullscreen ? 72 : 48) : 12),
              if (error != null)
                _ErrorOverlay(error: error)
              else if (c == null || !c.value.isInitialized)
                const Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  ),
                ),
              if (c != null && c.value.isInitialized)
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: c,
                  builder: (context, v, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      if (v.isBuffering && !_visible)
                        const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
                      AnimatedOpacity(
                        opacity: controlsShown ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        // Hidden controls take neither taps nor focus.
                        child: IgnorePointer(
                          ignoring: !controlsShown,
                          child: ExcludeFocus(excluding: !controlsShown, child: _controls(c, v)),
                        ),
                      ),
                      if (!_visible && !widget.fullscreen)
                        Positioned(left: 0, right: 0, bottom: 0, child: SeekBar(controller: c, minimal: true)),
                    ],
                  ),
                ),
              if (_seekSide != 0) _SeekRipple(side: _seekSide, seconds: _seekSeconds),
              if (_boost || _flash != null)
                Positioned(
                  // Below the top row while the controls show.
                  top: _visible ? 56 : 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Pill(
                      child: Text(_flash ?? '2x  ▶▶', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              if (countdown != null) _UpNextOverlay(countdown: countdown),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(VideoPlayerController c, VideoPlayerValue v) {
    final playback = ref.read(playbackProvider.notifier);
    final info = ref.watch(currentInfoProvider);
    final live = info?.isLive ?? false;
    final captions = ref.watch(captionsProvider);
    final pad = widget.fullscreen ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12) : EdgeInsets.zero;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Padding(
        padding: pad,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  _IconBtn(
                    widget.fullscreen ? Symbols.close_fullscreen : Symbols.keyboard_arrow_down,
                    onTap: widget.fullscreen
                        ? () => ref.read(fullscreenProvider.notifier).set(false)
                        : widget.onMinimize,
                  ),
                  if (widget.fullscreen && info != null)
                    Expanded(
                      child: Text(
                        info.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    const Spacer(),
                  _AutoplaySwitch(on: ref.watch(settingsProvider.select((s) => s.autoplay)), onTap: _toggleAutoplay),
                  if (info != null && info.captions.isNotEmpty)
                    _IconBtn(
                      captions == null ? Symbols.closed_caption_disabled : Symbols.closed_caption,
                      filled: captions != null,
                      onTap: () => toggleCaptions(context, ref),
                    ),
                  ?playerCastButton?.call(),
                  _IconBtn(Symbols.settings, onTap: () => showPlayerSettings(context, ref)),
                ],
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBtn(Symbols.skip_previous, size: 36, filled: true, onTap: playback.previous),
                  const SizedBox(width: 40),
                  FocusHighlight(
                    radius: 30,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        focusNode: _playPauseFocus,
                        onTap: _togglePlay,
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(
                            v.isCompleted
                                ? Symbols.replay
                                : v.isPlaying
                                ? Symbols.pause
                                : Symbols.play_arrow,
                            size: 44,
                            fill: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  _IconBtn(Symbols.skip_next, size: 36, filled: true, onTap: playback.next),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 0,
              bottom: widget.fullscreen ? 28 : 12,
              child: Row(
                children: [
                  if (live)
                    const _Pill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: YtColors.red),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${formatDuration(v.position)} / ${formatDuration(v.duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  const Spacer(),
                  _IconBtn(
                    widget.fullscreen ? Symbols.fullscreen_exit : Symbols.fullscreen,
                    onTap: () => ref.read(fullscreenProvider.notifier).set(!widget.fullscreen),
                  ),
                ],
              ),
            ),
            if (!live)
              Positioned(
                left: widget.fullscreen ? 0 : 0,
                right: 0,
                bottom: widget.fullscreen ? 8 : -6,
                child: SeekBar(controller: c, onDragging: (d) => d ? _hide?.cancel() : _scheduleHide()),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(this.icon, {required this.onTap, this.size = 24, this.filled = false});

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: size, color: Colors.white, fill: filled ? 1 : 0),
  );
}

/// YouTube's Autoplay switch: a small track with a play (on) or pause (off) thumb.
class _AutoplaySwitch extends StatelessWidget {
  const _AutoplaySwitch({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FocusHighlight(
    radius: 24,
    child: Semantics(
      label: 'Autoplay',
      toggled: on,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SizedBox(
              width: 36,
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: on ? 0.7 : 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: on ? Colors.white : const Color(0xFFBDBDBD),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(on ? Symbols.play_arrow : Symbols.pause, size: 14, fill: 1, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The end-of-video "Up next" card with its countdown, Cancel and Play now (docs/playback.md).
class _UpNextOverlay extends ConsumerStatefulWidget {
  const _UpNextOverlay({required this.countdown});

  final UpNextCountdown countdown;

  @override
  ConsumerState<_UpNextOverlay> createState() => _UpNextOverlayState();
}

class _UpNextOverlayState extends ConsumerState<_UpNextOverlay> with SingleTickerProviderStateMixin {
  late final _ring = AnimationController(vsync: this, duration: UpNextCountdownController.length);
  final _playNow = FocusNode(debugLabel: 'play now');

  @override
  void initState() {
    super.initState();
    _sync();
    // The remote lands on Play now, like YouTube for TV (autofocus wouldn't: the player already has focus).
    if (DeviceInfo.current.tv) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playNow.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_UpNextOverlay old) {
    super.didUpdateWidget(old);
    if (old.countdown != widget.countdown) _sync();
  }

  /// Runs the ring from wherever the countdown is now (it may have started before this player was built).
  void _sync() {
    final total = UpNextCountdownController.length.inMilliseconds;
    final left = widget.countdown.startsAt.difference(DateTime.now()).inMilliseconds.clamp(0, total);
    _ring
      ..value = 1 - left / total
      ..animateTo(1, duration: Duration(milliseconds: left));
  }

  @override
  void dispose() {
    _ring.dispose();
    _playNow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.countdown.video;
    final countdown = ref.read(upNextCountdownProvider.notifier);
    const white70 = TextStyle(color: Colors.white70, fontSize: 12);
    // Blocks taps from reaching the player underneath.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _ring,
                      builder: (context, _) {
                        final seconds = ((1 - _ring.value) * UpNextCountdownController.length.inSeconds).ceil();
                        return Text('Up next in $seconds', style: white70);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    if (video.channelName case final channel? when channel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(channel, maxLines: 1, overflow: TextOverflow.ellipsis, style: white70),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FocusHighlight(
                          radius: 18,
                          child: TextButton(
                            onPressed: countdown.cancel,
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 24),
                        FocusHighlight(
                          radius: 28,
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              focusNode: _playNow,
                              onTap: countdown.playNow,
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: AnimatedBuilder(
                                        animation: _ring,
                                        builder: (context, _) => CircularProgressIndicator(
                                          value: _ring.value,
                                          strokeWidth: 3,
                                          color: Colors.white,
                                          backgroundColor: Colors.white24,
                                        ),
                                      ),
                                    ),
                                    const Icon(Symbols.play_arrow, size: 32, fill: 1, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
    child: child,
  );
}

class _SeekRipple extends StatelessWidget {
  const _SeekRipple({required this.side, required this.seconds});

  final int side;
  final int seconds;

  @override
  Widget build(BuildContext context) => Align(
    alignment: side < 0 ? Alignment.centerLeft : Alignment.centerRight,
    child: FractionallySizedBox(
      widthFactor: 0.4,
      heightFactor: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: side < 0
              ? const BorderRadius.horizontal(right: Radius.circular(400))
              : const BorderRadius.horizontal(left: Radius.circular(400)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(side < 0 ? Symbols.fast_rewind : Symbols.fast_forward, color: Colors.white, fill: 1),
            const SizedBox(height: 4),
            Text('$seconds seconds', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

class _ErrorOverlay extends ConsumerWidget {
  const _ErrorOverlay({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = error is VideoUnavailable ? (error as VideoUnavailable).friendly : 'Something went wrong';
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.error, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final s = ref.read(playbackProvider);
                if (s != null) ref.read(playbackProvider.notifier).play(s.video, queue: s.queue, index: s.index);
              },
              child: const Text('Tap to retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
