import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../features/watch/player_view.dart';
import '../../features/watch/watch_details.dart';
import '../../player/video_player_service.dart';
import '../../providers.dart';
import '../theme/yt_theme.dart';
import '../widgets/common.dart';

/// Run once when the shell first shows (the launch update check).
final shellStartHooks = <void Function(BuildContext context, WidgetRef ref)>[];

/// The open panel under the player (Description, Comments, Queue).
final watchSheetProvider = NotifierProvider<WatchSheetController, WatchSheet>(WatchSheetController.new);

class WatchSheetController extends Notifier<WatchSheet> {
  @override
  WatchSheet build() {
    // A new video closes the panel.
    ref.watch(playbackProvider.select((p) => p?.video.id));
    return WatchSheet.none;
  }

  void show(WatchSheet sheet) => state = sheet;
  void close() => state = WatchSheet.none;
}

/// Bottom navigation plus the watch panel, which morphs between the mini player and the full watch page.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with TickerProviderStateMixin {
  late final _panel = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  /// How far (px) the mini player has been swiped down to close it.
  late final _dismiss = AnimationController.unbounded(vsync: this);

  /// The mini player's corner: 0 = bottom left, 1 = bottom right (dragged sideways, like YouTube's).
  late final _side = AnimationController(vsync: this, value: 1, duration: const Duration(milliseconds: 250));

  // Set by each layout: how far the video travels between mini and full, and between the corners.
  double _travel = 1;
  double _sideTravel = 1;
  double _miniHeight = 1;

  @override
  void initState() {
    super.initState();
    Pip.instance.active.addListener(_pipChanged);
    for (final hook in shellStartHooks) {
      hook(context, ref);
    }
  }

  @override
  void dispose() {
    Pip.instance.active.removeListener(_pipChanged);
    _panel.dispose();
    _dismiss.dispose();
    _side.dispose();
    super.dispose();
  }

  void _pipChanged() => setState(() {});

  /// Vertical drag on the video: up expands, down minimises; down on the mini player starts closing it.
  void _drag(double dy) {
    if (_panel.value == 0 && (_dismiss.value > 0 || dy > 0)) {
      _dismiss.value = math.max(0, _dismiss.value + dy);
    } else {
      _panel.value -= dy / _travel;
    }
  }

  void _dragEnd(double velocity) {
    if (_dismiss.value > 0) {
      if (_dismiss.value > _miniHeight * 0.35 || velocity > 600) {
        _dismiss
            .animateTo(_miniHeight * 1.5, duration: const Duration(milliseconds: 160), curve: Curves.easeIn)
            .whenComplete(() async {
              await ref.read(playbackProvider.notifier).stop();
              _dismiss.value = 0;
            });
      } else {
        _dismiss.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic);
      }
      return;
    }
    final expand = velocity < -300 || (velocity.abs() <= 300 && _panel.value > 0.3);
    ref.read(playerPanelProvider.notifier).set(expand);
    _panel.animateTo(expand ? 1 : 0, curve: Curves.easeOutCubic);
  }

  void _sideDrag(double dx) {
    if (_panel.value == 0) _side.value += dx / _sideTravel;
  }

  void _sideDragEnd(double velocity) {
    final target = velocity > 300 ? 1.0 : (velocity < -300 ? 0.0 : _side.value.roundToDouble());
    _side.animateTo(target, curve: Curves.easeOutCubic);
  }

  Future<void> _setFullscreen(bool on) async {
    if (on) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playerPanelProvider, (_, expanded) {
      _panel.animateTo(expanded ? 1 : 0, curve: Curves.easeOutCubic);
    });
    ref.listen(fullscreenProvider, (_, on) => _setFullscreen(on));
    // Arm picture-in-picture while a video plays (leaving the app then shrinks it into a window).
    ref.listen(playerControllerProvider, (_, c) => _armPip(c));

    final playing = ref.watch(playbackProvider);
    final fullscreen = ref.watch(fullscreenProvider);
    final tab = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(currentTabProvider.notifier).set(tab);
    });

    if (Pip.instance.active.value) {
      return const Scaffold(backgroundColor: Colors.black, body: VideoSurface());
    }

    final media = MediaQuery.of(context);
    final navHeight = YtSizes.navBarHeight + media.padding.bottom;
    // YouTube hides the mini player on the Shorts tab.
    final hideMini = tab == 1 && !ref.watch(playerPanelProvider);

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent == false) return false;
        if (ref.read(fullscreenProvider)) {
          ref.read(fullscreenProvider.notifier).set(false);
          return true;
        }
        if (_panel.value == 0) return false;
        if (ref.read(watchSheetProvider) != WatchSheet.none) {
          ref.read(watchSheetProvider.notifier).close();
          return true;
        }
        ref.read(playerPanelProvider.notifier).collapse();
        return true;
      },
      child: PopScope(
        canPop: widget.navigationShell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.navigationShell.goBranch(0);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          // An invisible stand-in for the nav bar (drawn in the Stack below), so toasts float above it like YouTube's.
          extendBody: true,
          bottomNavigationBar: fullscreen ? null : IgnorePointer(child: SizedBox(height: navHeight)),
          body: fullscreen && playing != null
              ? const ColoredBox(
                  color: Colors.black,
                  child: PlayerView(fullscreen: true, onMinimize: _noop),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    // The original insets: extendBody would add the stand-in nav bar to the bottom padding.
                    return MediaQuery(
                      data: media,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_panel, _dismiss, _side]),
                        builder: (context, _) {
                          final t = playing == null ? 0.0 : _panel.value;
                          // The mini player floats over the content (it reserves no space), like YouTube's.
                          const m = YtSizes.miniPlayerMargin;
                          final miniW = (size.width * YtSizes.miniPlayerWidthFraction).roundToDouble();
                          final miniH = miniW * 9 / 16;
                          final miniTop = size.height - navHeight - miniH - m;
                          final full = Rect.fromLTWH(0, media.padding.top, size.width, size.width * 9 / 16);
                          _miniHeight = miniH;
                          _travel = miniTop - full.top;
                          _sideTravel = size.width - miniW - 2 * m;
                          final mini = Rect.fromLTWH(
                            m + _sideTravel * _side.value,
                            miniTop + _dismiss.value,
                            miniW,
                            miniH,
                          );
                          return Stack(
                            children: [
                              Positioned.fill(
                                bottom: navHeight,
                                // Pages end with room for the floating mini player (lists read this as their bottom
                                // padding; sliver pages add a SliverBottomInset), so their last item can scroll clear.
                                child: MediaQuery(
                                  data: media.copyWith(
                                    padding: media.padding.copyWith(
                                      bottom: playing != null && !hideMini ? miniH + 2 * m : 0,
                                    ),
                                  ),
                                  child: widget.navigationShell,
                                ),
                              ),
                              if (playing != null && !hideMini)
                                Positioned.fill(
                                  // Over the expanded player the status bar is black with light icons, like YouTube.
                                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                                    value: t > 0.5 ? SystemUiOverlayStyle.light : _themeOverlay(context),
                                    child: _WatchPanel(
                                      t: t,
                                      video: Rect.lerp(mini, full, t)!,
                                      fullHeight: size.height,
                                      fade: (1 - _dismiss.value / miniH).clamp(0.0, 1.0),
                                      onDrag: _drag,
                                      onDragEnd: _dragEnd,
                                      onSideDrag: _sideDrag,
                                      onSideDragEnd: _sideDragEnd,
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: -navHeight * t,
                                height: navHeight,
                                child: _BottomNav(
                                  index: widget.navigationShell.currentIndex,
                                  onTap: (i) {
                                    ref.read(playerPanelProvider.notifier).collapse();
                                    widget.navigationShell.goBranch(
                                      i,
                                      initialLocation: i == widget.navigationShell.currentIndex,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  bool? _pipArmed;
  Size? _pipAspect;

  void _armPip(VideoPlayerController? c) {
    void arm(bool on, Size aspect) {
      if (on == _pipArmed && aspect == _pipAspect) return;
      _pipArmed = on;
      _pipAspect = aspect;
      Pip.instance.arm(on, aspect: aspect);
    }

    if (!ref.read(settingsProvider).pip || c == null) {
      arm(false, const Size(16, 9));
      return;
    }
    // The listener fires many times a second; only tell Android when playing or the shape changes.
    void update() {
      final v = c.value;
      arm(v.isPlaying, v.size.isEmpty ? const Size(16, 9) : v.size);
    }

    c.addListener(update);
    update();
  }
}

void _noop() {}

SystemUiOverlayStyle _themeOverlay(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

class _WatchPanel extends ConsumerWidget {
  const _WatchPanel({
    required this.t,
    required this.video,
    required this.fullHeight,
    required this.fade,
    required this.onDrag,
    required this.onDragEnd,
    required this.onSideDrag,
    required this.onSideDragEnd,
  });

  /// 0 = mini player, 1 = watch page.
  final double t;

  /// Where the video is drawn (morphs from the mini card to the top of the watch page).
  final Rect video;
  final double fullHeight;

  /// The mini player's opacity while it's swiped down to close.
  final double fade;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;
  final ValueChanged<double> onSideDrag;
  final ValueChanged<double> onSideDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    final videoH = width * 9 / 16;
    final detailsOpacity = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    final sheet = ref.watch(watchSheetProvider);
    final now = ref.watch(playbackProvider)!;
    final radius = lerpDouble(YtSizes.miniPlayerRadius, 0, (t * 3).clamp(0.0, 1.0))!;

    // Without a background at t = 0, touches outside the mini card reach the page underneath.
    return Stack(
      children: [
        if (t > 0) ...[
          Positioned.fill(
            key: const ValueKey('background'),
            child: Opacity(
              opacity: (t * 2).clamp(0.0, 1.0),
              child: ColoredBox(color: c.background),
            ),
          ),
          Positioned(
            key: const ValueKey('statusBar'),
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: Opacity(
              opacity: t,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ],
        if (detailsOpacity > 0)
          Positioned(
            key: const ValueKey('details'),
            top: top + videoH,
            left: 0,
            right: 0,
            height: fullHeight - top - videoH,
            child: Opacity(
              opacity: detailsOpacity,
              child: Stack(
                children: [
                  WatchDetails(onSheet: ref.read(watchSheetProvider.notifier).show),
                  if (sheet != WatchSheet.none)
                    Positioned.fill(
                      child: Material(
                        color: c.raised,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: switch (sheet) {
                          WatchSheet.description => DescriptionPanel(
                            onClose: ref.read(watchSheetProvider.notifier).close,
                          ),
                          WatchSheet.comments => CommentsPanel(
                            videoId: now.video.id,
                            onClose: ref.read(watchSheetProvider.notifier).close,
                          ),
                          WatchSheet.queue => QueuePanel(onClose: ref.read(watchSheetProvider.notifier).close),
                          WatchSheet.none => const SizedBox.shrink(),
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        // Keyed: the layers above come and go, and the video's drag detector must not be rebuilt mid-drag.
        Positioned.fromRect(
          key: const ValueKey('video'),
          rect: video,
          child: Opacity(
            opacity: fade,
            child: Material(
              color: Colors.black,
              elevation: t < 0.05 ? 6 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
              clipBehavior: Clip.antiAlias,
              // One detector for every size, so a drag survives the switch between mini and full.
              child: GestureDetector(
                onVerticalDragUpdate: (d) => onDrag(d.primaryDelta!),
                onVerticalDragEnd: (d) => onDragEnd(d.primaryVelocity ?? 0),
                onHorizontalDragUpdate: t == 0 ? (d) => onSideDrag(d.primaryDelta!) : null,
                onHorizontalDragEnd: t == 0 ? (d) => onSideDragEnd(d.primaryVelocity ?? 0) : null,
                child: t > 0.95
                    ? PlayerView(onMinimize: ref.read(playerPanelProvider.notifier).collapse)
                    : t == 0
                    ? _MiniPlayer(onExpand: ref.read(playerPanelProvider.notifier).expand)
                    : const VideoSurface(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// YouTube's floating mini player: the video in a rounded card. A tap shows the controls (expand, close,
/// previous / play-pause / next); a tap on the shown controls opens the watch page.
class _MiniPlayer extends ConsumerStatefulWidget {
  const _MiniPlayer({required this.onExpand});

  final VoidCallback onExpand;

  @override
  ConsumerState<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<_MiniPlayer> {
  bool _controls = false;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _show() {
    setState(() => _controls = true);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(playerControllerProvider);
    final remote = remoteControlsOf?.call(ref);
    final playback = ref.read(playbackProvider.notifier);

    Widget button(IconData icon, VoidCallback onPressed, {double size = 24, String? tooltip}) => IconButton(
      onPressed: () {
        onPressed();
        _show();
      },
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: Colors.white,
      icon: Icon(icon, size: size, fill: 1),
    );

    Widget playPause(bool playing, VoidCallback toggle) =>
        button(playing ? Symbols.pause : Symbols.play_arrow, toggle, size: 36, tooltip: playing ? 'Pause' : 'Play');

    final Widget center;
    if (remote != null) {
      center = playPause(remote.playing, remote.togglePlay);
    } else if (c != null) {
      center = ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (context, v, _) => playPause(v.isPlaying, () => v.isPlaying ? c.pause() : c.play()),
      );
    } else {
      center = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const VideoSurface(),
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _controls ? widget.onExpand : _show),
        if (c == null && remote == null && !_controls) Center(child: center),
        IgnorePointer(
          ignoring: !_controls,
          child: AnimatedOpacity(
            opacity: _controls ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onExpand,
              child: ColoredBox(
                color: Colors.black45,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: button(Symbols.open_in_full, widget.onExpand, size: 20, tooltip: 'Expand'),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: button(Symbols.close, () => playback.stop(), size: 22, tooltip: 'Close'),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          button(Symbols.skip_previous, () => playback.previous(), tooltip: 'Previous'),
                          const SizedBox(width: 4),
                          center,
                          const SizedBox(width: 4),
                          button(Symbols.skip_next, () => playback.next(), tooltip: 'Next'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: 0, height: 3, child: _MiniProgress()),
      ],
    );
  }
}

class _MiniProgress extends ConsumerWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(playerControllerProvider);
    if (c == null) return const SizedBox.shrink();
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, v, _) {
        final total = v.duration.inMilliseconds;
        return LinearProgressIndicator(
          value: total <= 0 ? 0 : v.position.inMilliseconds / total,
          color: YtColors.progress,
          backgroundColor: Colors.white24,
          minHeight: 3,
        );
      },
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    Widget icon(int i, bool selected) => switch (i) {
      0 => Icon(Symbols.home, fill: selected ? 1 : 0, size: 26, weight: 300),
      1 => ShortsIcon(size: 26, filled: selected, color: c.textPrimary),
      2 => Icon(Symbols.subscriptions, fill: selected ? 1 : 0, size: 26, weight: 300),
      _ => Icon(Symbols.account_circle, fill: selected ? 1 : 0, size: 26, weight: 300),
    };
    const labels = ['Home', 'Shorts', 'Subscriptions', 'You'];
    return Material(
      color: c.navBar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    radius: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon(i, i == index),
                        const SizedBox(height: 2),
                        Text(
                          labels[i],
                          style: TextStyle(fontSize: 10, color: c.textPrimary, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
