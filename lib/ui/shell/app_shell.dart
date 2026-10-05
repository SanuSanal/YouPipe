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
import '../layout.dart';
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

  /// The side rail, so the remote's Left can reach it from inside a page (see [_leftToRail]).
  final _rail = GlobalKey<_SideNavState>();

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
    for (final hook in shellStartHooks) {
      hook(context, ref);
    }
  }

  @override
  void dispose() {
    _panel.dispose();
    _dismiss.dispose();
    _side.dispose();
    super.dispose();
  }

  /// Whether the current drag started on the expanded watch page, and how far it has pulled up past it (a swipe up
  /// there goes fullscreen, like YouTube).
  bool _dragFromFull = false;
  double _pullUp = 0;

  void _dragStart() {
    _dragFromFull = _panel.value == 1;
    _pullUp = 0;
  }

  /// Vertical drag on the video: up expands, down minimises; down on the mini player starts closing it.
  void _drag(double dy) {
    if (_dragFromFull && _panel.value == 1 && dy < 0) {
      _pullUp -= dy;
    } else if (_panel.value == 0 && (_dismiss.value > 0 || dy > 0)) {
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
    if (_dragFromFull && _panel.value == 1 && (_pullUp > 48 || velocity < -500)) {
      ref.read(fullscreenProvider.notifier).set(true);
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
    final form = formFactorOf(context);
    if (on) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // A TV is always landscape; phones and tablets turn for fullscreen.
      if (form != FormFactor.tv) await sensorLandscape();
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(appOrientations(form));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playerPanelProvider, (_, expanded) {
      _panel.animateTo(expanded ? 1 : 0, curve: Curves.easeOutCubic);
      // The remote's focus goes back to the rail when the watch page closes (its player had focus).
      if (!expanded) WidgetsBinding.instance.addPostFrameCallback((_) => _rail.currentState?.claimFocus());
    });
    ref.listen(fullscreenProvider, (_, on) => _setFullscreen(on));
    // Arm picture-in-picture while a video plays (leaving the app then shrinks it into a window).
    ref.listen(playerControllerProvider, (_, c) => _armPip(c));

    final playing = ref.watch(playbackProvider);
    final fullscreen = ref.watch(fullscreenProvider);
    final panelExpanded = ref.watch(playerPanelProvider);
    // The watch page covers the tabs and the rail: they leave focus traversal (the remote would move behind it).
    final coveredByPanel = playing != null && panelExpanded;
    final tab = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(currentTabProvider.notifier).set(tab);
    });

    final media = MediaQuery.of(context);
    // Wide screens (landscape tablets, TVs) get a side rail and the two-column watch page (docs/ui.md).
    final wide = isWide(media.size);
    final railW = wide ? YtSizes.navRailWidth : 0.0;
    final navHeight = wide ? 0.0 : YtSizes.navBarHeight + media.padding.bottom;
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
        // Claim Back whenever the shell has something to undo (fullscreen, the expanded player, another tab).
        // Android 16's predictive back asks up front: if this said "can pop", Back would close the app instead of
        // reaching the BackButtonListener above.
        canPop: widget.navigationShell.currentIndex == 0 && !fullscreen && !(playing != null && panelExpanded),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.navigationShell.goBranch(0);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          // An invisible stand-in for the nav bar (drawn in the Stack below), so toasts float above it like YouTube's.
          extendBody: true,
          bottomNavigationBar: fullscreen || wide ? null : IgnorePointer(child: SizedBox(height: navHeight)),
          body: fullscreen && playing != null
              ? const ColoredBox(
                  color: Colors.black,
                  child: _FullscreenSwipe(child: PlayerView(fullscreen: true, onMinimize: _noop)),
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
                          final miniW = math
                              .min(size.width * YtSizes.miniPlayerWidthFraction, YtSizes.miniPlayerMaxWidth)
                              .roundToDouble();
                          final miniH = miniW * 9 / 16;
                          final miniTop = size.height - navHeight - miniH - m;
                          // On wide screens the video takes the left column and the related list the right one.
                          final videoW = wide ? (size.width * YtSizes.watchColumnFraction).roundToDouble() : size.width;
                          final full = Rect.fromLTWH(0, media.padding.top, videoW, videoW * 9 / 16);
                          _miniHeight = miniH;
                          _travel = miniTop - full.top;
                          _sideTravel = size.width - railW - miniW - 2 * m;
                          final mini = Rect.fromLTWH(
                            railW + m + _sideTravel * _side.value,
                            miniTop + _dismiss.value,
                            miniW,
                            miniH,
                          );
                          return Stack(
                            children: [
                              Positioned.fill(
                                left: railW,
                                bottom: navHeight,
                                // Pages end with room for the floating mini player (lists read this as their bottom
                                // padding; sliver pages add a SliverBottomInset), so their last item can scroll clear.
                                child: MediaQuery(
                                  data: media.copyWith(
                                    padding: media.padding.copyWith(
                                      bottom: playing != null && !hideMini ? miniH + 2 * m : 0,
                                    ),
                                  ),
                                  // Always wrapped (it acts only while the rail shows), so rotating a tablet doesn't
                                  // rebuild the tabs.
                                  // Under the open watch page the pages can't take the remote's focus.
                                  child: ExcludeFocus(
                                    excluding: coveredByPanel,
                                    child: Focus(
                                      canRequestFocus: false,
                                      skipTraversal: true,
                                      onKeyEvent: _leftToRail,
                                      child: widget.navigationShell,
                                    ),
                                  ),
                                ),
                              ),
                              if (playing != null && !hideMini)
                                Positioned.fill(
                                  // Over the expanded player the status bar is black with light icons, like YouTube.
                                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                                    value: _panelOverlay(context, expanded: t > 0.5),
                                    child: _WatchPanel(
                                      t: t,
                                      video: Rect.lerp(mini, full, t)!,
                                      videoW: videoW,
                                      wide: wide,
                                      fullHeight: size.height,
                                      fade: (1 - _dismiss.value / miniH).clamp(0.0, 1.0),
                                      onDragStart: _dragStart,
                                      onDrag: _drag,
                                      onDragEnd: _dragEnd,
                                      onSideDrag: _sideDrag,
                                      onSideDragEnd: _sideDragEnd,
                                    ),
                                  ),
                                ),
                              if (wide)
                                Positioned(
                                  left: -railW * t,
                                  top: 0,
                                  bottom: 0,
                                  width: railW,
                                  child: ExcludeFocus(
                                    excluding: coveredByPanel,
                                    child: _SideNav(
                                      key: _rail,
                                      index: widget.navigationShell.currentIndex,
                                      onTap: _openTab,
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -navHeight * t,
                                  height: navHeight,
                                  child: _BottomNav(index: widget.navigationShell.currentIndex, onTap: _openTab),
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

  /// Each tab's pages sit in their own focus scope, which arrow keys don't leave. So Left that can't move any
  /// further inside the page goes to the side rail, like YouTube for TV.
  KeyEventResult _leftToRail(FocusNode node, KeyEvent e) {
    final rail = _rail.currentState;
    if (rail == null || e is KeyUpEvent || e.logicalKey != LogicalKeyboardKey.arrowLeft) return KeyEventResult.ignored;
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null || focused.focusInDirection(TraversalDirection.left)) return KeyEventResult.handled;
    rail.focusSelected();
    return KeyEventResult.handled;
  }

  void _openTab(int i) {
    ref.read(playerPanelProvider.notifier).collapse();
    widget.navigationShell.goBranch(i, initialLocation: i == widget.navigationShell.currentIndex);
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

/// In fullscreen a swipe down on the video leaves it, like YouTube.
class _FullscreenSwipe extends ConsumerStatefulWidget {
  const _FullscreenSwipe({required this.child});

  final Widget child;

  @override
  ConsumerState<_FullscreenSwipe> createState() => _FullscreenSwipeState();
}

class _FullscreenSwipeState extends ConsumerState<_FullscreenSwipe> {
  double _pulled = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onVerticalDragStart: (_) => _pulled = 0,
    onVerticalDragUpdate: (d) => _pulled += d.primaryDelta!,
    onVerticalDragEnd: (d) {
      if (_pulled > 48 || (d.primaryVelocity ?? 0) > 500) ref.read(fullscreenProvider.notifier).set(false);
    },
    child: widget.child,
  );
}

/// The theme's system bars, with light status bar icons over the expanded player. Flutter's `SystemUiOverlayStyle.light`
/// and `.dark` also paint the navigation bar black, which showed a black bar under the light watch page.
SystemUiOverlayStyle _panelOverlay(BuildContext context, {required bool expanded}) {
  final themed = Theme.of(context).appBarTheme.systemOverlayStyle!;
  return expanded
      ? themed.copyWith(statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark)
      : themed;
}

class _WatchPanel extends ConsumerWidget {
  const _WatchPanel({
    required this.t,
    required this.video,
    required this.videoW,
    required this.wide,
    required this.fullHeight,
    required this.fade,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required this.onSideDrag,
    required this.onSideDragEnd,
  });

  /// 0 = mini player, 1 = watch page.
  final double t;

  /// Where the video is drawn (morphs from the mini card to the top of the watch page).
  final Rect video;

  /// The width of the expanded video: the whole screen, or the left column on wide screens.
  final double videoW;

  /// Two columns: video and details on the left, related videos (or the open panel) on the right.
  final bool wide;
  final double fullHeight;

  /// The mini player's opacity while it's swiped down to close.
  final double fade;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;
  final ValueChanged<double> onSideDrag;
  final ValueChanged<double> onSideDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    final top = MediaQuery.paddingOf(context).top;
    final videoH = videoW * 9 / 16;
    final detailsOpacity = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    final sheet = ref.watch(watchSheetProvider);
    final now = ref.watch(playbackProvider)!;
    final radius = lerpDouble(YtSizes.miniPlayerRadius, 0, (t * 3).clamp(0.0, 1.0))!;
    final close = ref.read(watchSheetProvider.notifier).close;
    Widget sheetPanel({required bool rounded}) => Material(
      color: c.raised,
      borderRadius: rounded ? const BorderRadius.vertical(top: Radius.circular(12)) : null,
      child: switch (sheet) {
        WatchSheet.description => DescriptionPanel(onClose: close),
        WatchSheet.comments => CommentsPanel(videoId: now.video.id, onClose: close),
        WatchSheet.queue => QueuePanel(onClose: close),
        WatchSheet.none => const SizedBox.shrink(),
      },
    );

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
            width: videoW,
            height: fullHeight - top - videoH,
            child: Opacity(
              opacity: detailsOpacity,
              child: Stack(
                children: [
                  WatchDetails(onSheet: ref.read(watchSheetProvider.notifier).show, showRelated: !wide),
                  // Narrow: the panel slides over the details. Wide: it takes the right column instead.
                  if (!wide && sheet != WatchSheet.none) Positioned.fill(child: sheetPanel(rounded: true)),
                ],
              ),
            ),
          ),
        if (wide && detailsOpacity > 0)
          Positioned(
            key: const ValueKey('side'),
            top: top,
            left: videoW,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: detailsOpacity,
              child: sheet == WatchSheet.none ? const RelatedList() : sheetPanel(rounded: false),
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
                onVerticalDragStart: (_) => onDragStart(),
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

    return FocusHighlight(
      radius: YtSizes.miniPlayerRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const VideoSurface(),
          // Focusable for the TV remote, where Select opens the watch page straight away.
          InkWell(
            onTap: () => _controls || FocusManager.instance.highlightMode == FocusHighlightMode.traditional
                ? widget.onExpand()
                : _show(),
          ),
          if (c == null && remote == null && !_controls) Center(child: center),
          IgnorePointer(
            ignoring: !_controls,
            child: AnimatedOpacity(
              opacity: _controls ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: ExcludeFocus(
                excluding: !_controls,
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
          ),
          const Positioned(left: 0, right: 0, bottom: 0, height: 3, child: _MiniProgress()),
        ],
      ),
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

const _navLabels = ['Home', 'Shorts', 'Subscriptions', 'You'];

/// One destination of the bottom bar or the side rail: the icon (filled when selected) over its label.
class _NavItem extends StatelessWidget {
  const _NavItem({required this.i, required this.selected, required this.onTap, this.focusNode, this.rail = false});

  final int i;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  /// In the side rail: the item fills the rail and highlights as a rounded square.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
    final icon = switch (i) {
      0 => Icon(Symbols.home, fill: selected ? 1 : 0, size: 26, weight: 300),
      1 => ShortsIcon(size: 26, filled: selected, color: c.textPrimary),
      2 => Icon(Symbols.subscriptions, fill: selected ? 1 : 0, size: 26, weight: 300),
      _ => Icon(Symbols.account_circle, fill: selected ? 1 : 0, size: 26, weight: 300),
    };
    return FocusHighlight(
      radius: 12,
      child: InkResponse(
        onTap: onTap,
        focusNode: focusNode,
        radius: 36,
        highlightShape: rail ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: rail ? BorderRadius.circular(12) : null,
        containedInkWell: rail,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 2),
            Text(
              _navLabels[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: c.textPrimary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
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
              for (var i = 0; i < _navLabels.length; i++)
                Expanded(
                  child: _NavItem(i: i, selected: i == index, onTap: () => onTap(i)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The navigation rail on wide screens (landscape tablets, TVs), like YouTube on tablets. On a TV it makes sure
/// something has focus (the selected item) whenever nothing else does, so the remote's first press always lands.
class _SideNav extends StatefulWidget {
  const _SideNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  State<_SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<_SideNav> {
  final _nodes = List.generate(_navLabels.length, (i) => FocusNode(debugLabel: 'nav $i'));

  @override
  void initState() {
    super.initState();
    _claimFocus();
  }

  @override
  void didUpdateWidget(_SideNav old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _claimFocus();
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// Focuses the selected item (the remote's Left from a page, [_AppShellState._leftToRail]).
  void focusSelected() => _nodes[widget.index].requestFocus();

  /// Focuses the selected item unless a widget already has focus (TV only).
  void claimFocus() {
    final primary = FocusManager.instance.primaryFocus;
    if (DeviceInfo.current.tv && (primary == null || primary is FocusScopeNode)) focusSelected();
  }

  /// After this frame: focus the selected item if no widget (only a scope, or nothing) has focus.
  void _claimFocus() {
    if (!DeviceInfo.current.tv) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final primary = FocusManager.instance.primaryFocus;
      if (mounted && (primary == null || primary is FocusScopeNode)) _nodes[widget.index].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
    return Material(
      color: c.navBar,
      child: SafeArea(
        right: false,
        child: FocusTraversalGroup(
          child: Column(
            children: [
              const SizedBox(height: 8),
              for (var i = 0; i < _navLabels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: SizedBox(
                    height: 68,
                    width: double.infinity,
                    child: _NavItem(
                      i: i,
                      selected: i == widget.index,
                      onTap: () => widget.onTap(i),
                      focusNode: _nodes[i],
                      rail: true,
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
