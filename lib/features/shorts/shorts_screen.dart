import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../data/ryd.dart';
import '../../data/video_info.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/layout.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/video_menu.dart';
import '../../ui/widgets/video_tiles.dart';
import '../../util/format.dart';
import '../watch/watch_details.dart';
import '../../player/playback_proxy.dart';

/// Shorts: a vertical pager over the Shorts feed (`reel/reel_watch_sequence`), optionally starting at [startId].
class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key, this.startId, this.isTab = true});

  final String? startId;

  /// The Shorts tab (no back button) or a Short opened from a card.
  final bool isTab;

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen> {
  final _ids = <String>[];
  String? _continuation;
  bool _loading = false;
  int _index = 0;
  Object? _error;

  /// Turns pages for the TV remote's Up/Down (touch swipes the PageView directly).
  final _pages = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.startId != null) _ids.add(widget.startId!);
    _more();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _step(int by) {
    const d = Duration(milliseconds: 250);
    by > 0
        ? _pages.nextPage(duration: d, curve: Curves.easeOut)
        : _pages.previousPage(duration: d, curve: Curves.easeOut);
  }

  Future<void> _more() async {
    if (_loading) return;
    _loading = true;
    try {
      final page = await ref.read(innerTubeProvider).shorts(_continuation);
      if (!mounted) return;
      setState(() {
        _ids.addAll(page.videoIds.where((id) => !_ids.contains(id)));
        _continuation = page.continuation;
        _error = null;
      });
    } catch (e) {
      if (mounted && _ids.isEmpty) setState(() => _error = e);
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only the visible Shorts page plays; the tab is kept alive in the background by the shell.
    final route = ModalRoute.of(context);
    final visible = route?.isCurrent ?? true;
    // A hidden tab has its tickers off, and this rebuilds when that changes. Riverpod pauses an offstage widget's
    // listeners, so currentTabProvider alone never reached it: Back from Shorts kept the Short playing on Home.
    final onScreen = TickerMode.valuesOf(context).enabled;
    final tabActive = !widget.isTab || ref.watch(currentTabProvider) == 1;
    final active = visible && onScreen && tabActive && !ref.watch(playerPanelProvider);
    if (active) {
      // Shorts take over the sound: pause the main video.
      ref.read(playerServiceProvider).controller.value?.pause();
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _more)
            : _ids.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Stack(
                children: [
                  PageView.builder(
                    controller: _pages,
                    scrollDirection: Axis.vertical,
                    itemCount: _ids.length,
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      if (i > _ids.length - 4) _more();
                    },
                    itemBuilder: (context, i) {
                      final page = _ShortPage(
                        key: ValueKey(_ids[i]),
                        videoId: _ids[i],
                        playing: active && i == _index,
                        preload: (i - _index).abs() <= 1,
                        onStep: _step,
                      );
                      // Landscape (tablets, TVs): a centred 9:16 column, like YouTube, instead of a cropped band.
                      final size = MediaQuery.sizeOf(context);
                      return size.width > size.height
                          ? Center(
                              child: AspectRatio(aspectRatio: 9 / 16, child: page),
                            )
                          : page;
                    },
                  ),
                  SafeArea(
                    child: Row(
                      children: [
                        if (!widget.isTab)
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Symbols.arrow_back, color: Colors.white),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => openSearch(context, ref),
                          icon: const Icon(Symbols.search, color: Colors.white, weight: 300),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ShortPage extends ConsumerStatefulWidget {
  const _ShortPage({
    super.key,
    required this.videoId,
    required this.playing,
    required this.preload,
    required this.onStep,
  });

  final String videoId;
  final bool playing;
  final bool preload;

  /// The remote's Up/Down on the video: the previous or next Short.
  final ValueChanged<int> onStep;

  @override
  ConsumerState<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends ConsumerState<_ShortPage> {
  VideoPlayerController? _c;
  VideoInfo? _info;
  Object? _error;
  bool _opening = false;
  bool _recorded = false;

  /// The video, focused on a TV (and after paging with the remote), so Select and Up/Down reach it.
  final _videoFocus = FocusNode(debugLabel: 'short');

  @override
  void initState() {
    super.initState();
    if (widget.preload) _open();
  }

  @override
  void didUpdateWidget(_ShortPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preload && _c == null) _open();
    _apply();
    // Paging with the remote: focus follows to the Short that just came on screen.
    if (widget.playing && !oldWidget.playing && FocusManager.instance.highlightMode == FocusHighlightMode.traditional) {
      _videoFocus.requestFocus();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent || !node.hasPrimaryFocus) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      widget.onStep(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      return KeyEventResult.handled;
    }
    final c = _c;
    if (c != null &&
        (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.mediaPlayPause)) {
      setState(() => c.value.isPlaying ? c.pause() : c.play());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _apply() {
    final c = _c;
    if (c == null) return;
    if (widget.playing) {
      c.play();
      _record();
    } else {
      c.pause();
    }
  }

  void _record() {
    final i = _info;
    if (_recorded || i == null || !ref.read(settingsProvider).saveHistory) return;
    _recorded = true;
    unawaited(ref.read(libraryProvider).recordWatch(_asItem(i)));
  }

  VideoItem _asItem(VideoInfo i) => VideoItem(
    id: i.videoId,
    title: i.title,
    channelName: i.channelName,
    channelId: i.channelId,
    channelAvatar: i.channelAvatar,
    viewsText: i.viewCount >= 0 ? viewsLabel(i.viewCount) : null,
    isShort: true,
  );

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    try {
      final info = await ref.read(videoInfoServiceProvider).get(widget.videoId);
      final dash = info.manifestPath != null;
      // Without a manifest, the progressive stream goes through the loopback relay (full speed, docs/streaming.md).
      final muxed = dash ? null : await PlaybackProxy.uriFor(info.muxedUrl!);
      final c = VideoPlayerController.networkUrl(
        dash ? Uri.file(info.manifestPath!) : (muxed ?? Uri.parse(info.muxedUrl!)),
        formatHint: dash ? VideoFormat.dash : null,
        httpHeaders: {'User-Agent': dash ? info.dashUserAgent : info.muxedUserAgent},
      );
      await c.initialize();
      await c.setLooping(true);
      if (!mounted) {
        unawaited(c.dispose());
        return;
      }
      setState(() {
        _c = c;
        _info = info;
      });
      _apply();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    _videoFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final info = _info;
    return Focus(
      focusNode: _videoFocus,
      autofocus: widget.playing && DeviceInfo.current.tv,
      onKeyEvent: _onKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null)
            GestureDetector(
              onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
              child: FittedBox(
                fit: c.value.aspectRatio < 0.7 ? BoxFit.cover : BoxFit.contain,
                child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
              ),
            )
          else
            Stack(
              fit: StackFit.expand,
              children: [
                YtImage('https://i.ytimg.com/vi/${widget.videoId}/oar2.jpg', fit: BoxFit.cover),
                Center(
                  child: _error != null
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            _error is VideoUnavailable
                                ? (_error as VideoUnavailable).friendly
                                : 'Couldn\'t load this Short',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ],
            ),
          if (c != null && !c.value.isPlaying && widget.playing)
            const IgnorePointer(
              child: Center(child: Icon(Symbols.play_arrow, size: 72, fill: 1, color: Colors.white70)),
            ),
          // Bottom shade so the text stays readable.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, 0.3),
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
          ),
          if (info != null) ...[
            Positioned(
              right: 4,
              bottom: 72,
              child: _Rail(info: info, item: _asItem(info)),
            ),
            Positioned(left: 12, right: 72, bottom: 20, child: _Meta(info: info)),
          ],
          if (c != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(playedColor: Colors.white, backgroundColor: Colors.white24),
              ),
            ),
        ],
      ),
    );
  }
}

class _Rail extends ConsumerWidget {
  const _Rail({required this.info, required this.item});

  final VideoInfo info;
  final VideoItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(isLikedProvider(info.videoId)).value ?? false;
    final votes = ref.watch(votesProvider(info.videoId)).value;
    final likes = info.likeCount >= 0 ? info.likeCount : votes?.likes;
    Widget action(IconData icon, String label, VoidCallback onTap, {bool filled = true}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FocusHighlight(
        radius: 24,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, fill: filled ? 1 : 0, size: 26),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
    return Column(
      children: [
        action(Symbols.thumb_up, likes == null ? 'Like' : compactCount(likes + (liked ? 1 : 0)), () {
          ref.read(libraryProvider).setLiked(item, !liked);
        }, filled: liked),
        action(Symbols.thumb_down, votes == null ? 'Dislike' : compactCount(votes.dislikes), () {}, filled: false),
        action(Symbols.comment, 'Comments', () => _showComments(context, info.videoId)),
        action(Symbols.share, 'Share', () => shareVideo(item)),
        action(Symbols.more_horiz, '', () => showVideoMenu(context, ref, item)),
      ],
    );
  }

  void _showComments(BuildContext context, String videoId) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: CommentsPanel(videoId: videoId, onClose: () => Navigator.of(sheet).pop()),
    ),
  );
}

class _Meta extends ConsumerWidget {
  const _Meta({required this.info});

  final VideoInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = info.channelId;
    final subscribed = id == null ? false : ref.watch(isSubscribedProvider(id)).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: id == null ? null : () => openChannel(context, ref, id),
              child: Row(
                children: [
                  Avatar(info.channelAvatar, size: 32, name: info.channelName),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      '@${info.channelName.replaceAll(' ', '')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (id != null)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (subscribed && !await confirmUnsubscribe(context, info.channelName)) return;
                  await ref
                      .read(libraryProvider)
                      .setSubscribed(
                        ChannelItem(id: id, name: info.channelName, avatar: info.channelAvatar),
                        !subscribed,
                      );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: subscribed ? Colors.white24 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    subscribed ? 'Subscribed' : 'Subscribe',
                    style: TextStyle(
                      color: subscribed ? Colors.white : YtColors.dark.onSubscribe,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          info.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
