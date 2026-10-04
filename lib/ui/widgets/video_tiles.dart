import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../navigation.dart';
import '../theme/yt_theme.dart';
import 'common.dart';
import 'video_menu.dart';
import '../layout.dart';

String videoMeta(VideoItem v, {bool withChannel = true}) =>
    [if (withChannel) ?v.channelName, ?v.viewsText, ?v.publishedText].where((s) => s.isNotEmpty).join(' · ');

/// The duration / LIVE badge in a thumbnail's corner, and the red watched bar along its bottom.
class ThumbnailOverlay extends ConsumerWidget {
  const ThumbnailOverlay({super.key, required this.video, this.badgeInset = 8});

  final VideoItem video;
  final double badgeInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(watchProgressProvider.select((m) => m.value?[video.id] ?? 0));
    return Stack(
      children: [
        if (video.isLive || video.durationText != null)
          Positioned(
            right: badgeInset,
            bottom: badgeInset + (progress > 0 ? 4 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: video.isLive ? YtColors.liveRed : YtColors.badge,
                borderRadius: BorderRadius.circular(4),
              ),
              child: video.isLive
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.sensors, size: 14, color: Colors.white),
                        SizedBox(width: 2),
                        Text('LIVE', style: YtText.badge),
                      ],
                    )
                  : Text(video.durationText!, style: YtText.badge),
            ),
          ),
        if (progress > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              color: YtColors.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}

/// The Home/search/related card: full-width 16:9 thumbnail, then avatar, title, meta and ⋮.
class VideoCard extends ConsumerWidget {
  const VideoCard(this.video, {super.key, this.onTap, this.inset = false, this.grid = false});

  final VideoItem video;
  final VoidCallback? onTap;

  /// Rounded thumbnail with side margins (the watch page's related list) instead of edge to edge.
  final bool inset;

  /// A cell of [VideoGridSliver] (tablets, TVs): rounded thumbnail, no outer margins (the grid spaces cells).
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    Widget thumb = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decoded at the size it's shown (a grid cell on tablets, the screen width on phones).
          LayoutBuilder(builder: (context, box) => YtImage(video.thumbnailOrDefault, width: box.maxWidth)),
          ThumbnailOverlay(video: video),
        ],
      ),
    );
    if (inset || grid) thumb = ClipRRect(borderRadius: BorderRadius.circular(12), child: thumb);
    if (inset) thumb = Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: thumb);
    return FocusHighlight(
      child: InkWell(
        onTap: onTap ?? () => playVideo(context, ref, video),
        onLongPress: () => showVideoMenu(context, ref, video),
        borderRadius: grid ? BorderRadius.circular(12) : null,
        child: Padding(
          padding: EdgeInsets.only(bottom: grid ? 0 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              Padding(
                padding: EdgeInsets.fromLTRB(grid ? 0 : 12, grid ? 10 : 12, 0, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No avatar when the channel is unknown (a channel's own featured video), like YouTube.
                    if (video.channelAvatar != null || video.channelName != null) ...[
                      GestureDetector(
                        onTap: video.channelId == null ? null : () => openChannel(context, ref, video.channelId!),
                        child: Avatar(video.channelAvatar, name: video.channelName),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: YtText.feedTitle.copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            videoMeta(video),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: YtText.meta.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    MenuButton(onTap: () => showVideoMenu(context, ref, video)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    icon: Icon(Symbols.more_vert, size: 20, color: context.yt.textPrimary),
  );
}

/// The compact row: 160dp rounded thumbnail on the left (playlists, history, library lists).
class VideoRow extends ConsumerWidget {
  const VideoRow(
    this.video, {
    super.key,
    this.onTap,
    this.leading,
    this.trailing,
    this.onRemove,
    this.removeLabel,
    this.thumbWidth = YtSizes.rowThumbWidth,
  });

  final VideoItem video;
  final VoidCallback? onTap;

  /// E.g. the index number in a playlist, or a drag handle.
  final Widget? leading;
  final Widget? trailing;

  /// Adds a "Remove from …" entry to the ⋮ menu.
  final VoidCallback? onRemove;
  final String? removeLabel;
  final double thumbWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    void menu() => showVideoMenu(context, ref, video, onRemove: onRemove, removeLabel: removeLabel);
    return FocusHighlight(
      radius: 8,
      child: InkWell(
        onTap: onTap ?? () => playVideo(context, ref, video),
        onLongPress: menu,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ?leading,
              ClipRRect(
                borderRadius: BorderRadius.circular(YtSizes.thumbRadius),
                child: SizedBox(
                  width: thumbWidth,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        YtImage(video.thumbnailOrDefault, width: thumbWidth),
                        ThumbnailOverlay(video: video, badgeInset: 4),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: YtText.rowTitle.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [?video.channelName, ?video.viewsText].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YtText.meta.copyWith(color: c.textSecondary),
                    ),
                    if (video.publishedText != null)
                      Text(video.publishedText!, style: YtText.meta.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              trailing ?? MenuButton(onTap: menu),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 9:16 Shorts card with the title over the bottom of the thumbnail.
class ShortCard extends ConsumerWidget {
  const ShortCard(this.video, {super.key, this.width = 160, this.onTap});

  final VideoItem video;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusHighlight(
    radius: YtSizes.thumbRadius,
    child: InkWell(
      borderRadius: BorderRadius.circular(YtSizes.thumbRadius),
      onTap: onTap ?? () => openShort(context, ref, video.id),
      onLongPress: () => showVideoMenu(context, ref, video),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(YtSizes.thumbRadius),
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Stack(
              fit: StackFit.expand,
              children: [
                YtImage(video.thumbnailOrDefault, width: width),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0, 0.2),
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          shadows: [Shadow(blurRadius: 4)],
                        ),
                      ),
                      if (video.viewsText != null)
                        Text(
                          video.viewsText!,
                          style: const TextStyle(color: Colors.white, fontSize: 12, shadows: [Shadow(blurRadius: 4)]),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () => showVideoMenu(context, ref, video),
                    icon: const Icon(
                      Symbols.more_vert,
                      size: 18,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The Shorts shelf: our Shorts glyph in red, "Shorts", and a horizontal row of 9:16 cards.
class ShortsShelf extends StatelessWidget {
  const ShortsShelf({super.key, required this.items, this.title = 'Shorts'});

  final List<VideoItem> items;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              const ShortsIcon(size: 26, color: YtColors.red, filled: true),
              const SizedBox(width: 8),
              Text(title, style: YtText.sectionTitle),
            ],
          ),
        ),
        SizedBox(
          height: 160 * 16 / 9,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ShortCard(items[i]),
          ),
        ),
      ],
    ),
  );
}

/// A channel search result / list entry: avatar, name, handle and subscribers, Subscribe.
class ChannelRow extends ConsumerWidget {
  const ChannelRow(this.channel, {super.key, this.avatarSize = 64, this.showSubscribe = true});

  final ChannelItem channel;
  final double avatarSize;
  final bool showSubscribe;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusHighlight(
    radius: 8,
    child: InkWell(
      onTap: () => openChannel(context, ref, channel.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: YtSizes.rowThumbWidth,
              child: Center(
                child: Avatar(channel.avatar, size: avatarSize, name: channel.name),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (channel.subscribersText?.isNotEmpty == true)
                    Text(
                      channel.subscribersText!,
                      style: YtText.meta.copyWith(color: context.yt.textSecondary),
                      maxLines: 2,
                    ),
                  if (showSubscribe) ...[const SizedBox(height: 8), SubscribeButton(channel, compact: true)],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Unsubscribing asks first, like YouTube (it also reaches the account when signed in).
Future<bool> confirmUnsubscribe(BuildContext context, String channelName) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text('Unsubscribe from $channelName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Unsubscribe')),
        ],
      ),
    ) ==
    true;

/// Subscribe / Subscribed. Subscriptions live on this device (docs/data.md).
class SubscribeButton extends ConsumerWidget {
  const SubscribeButton(this.channel, {super.key, this.compact = false});

  final ChannelItem channel;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    final subscribed = ref.watch(isSubscribedProvider(channel.id)).value ?? false;
    Future<void> toggle() async {
      if (subscribed && !await confirmUnsubscribe(context, channel.name)) return;
      await ref.read(libraryProvider).setSubscribed(channel, !subscribed);
      if (!subscribed) {
        unawaited(ref.read(subscriptionsFeedServiceProvider).refresh(force: true));
      }
      if (context.mounted) showSnack(context, subscribed ? 'Subscription removed' : 'Subscription added');
    }

    return FocusHighlight(
      radius: 18,
      child: Material(
        color: subscribed ? c.chip : c.subscribe,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: toggle,
          child: Container(
            height: compact ? 32 : YtSizes.pillHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subscribed) ...[
                  Icon(Symbols.notifications, size: 20, color: c.textPrimary),
                  const SizedBox(width: 6),
                ],
                Text(
                  subscribed ? 'Subscribed' : 'Subscribe',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subscribed ? c.textPrimary : c.onSubscribe,
                  ),
                ),
                if (subscribed) ...[
                  const SizedBox(width: 4),
                  Icon(Symbols.expand_more, size: 18, color: c.textPrimary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A playlist row: a thumbnail with the "N videos" strip on its right edge.
class PlaylistRow extends ConsumerWidget {
  const PlaylistRow(this.playlist, {super.key, this.onTap});

  final PlaylistItem playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusHighlight(
    radius: 8,
    child: InkWell(
      onTap: onTap ?? () => openPlaylist(context, ref, playlist.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlaylistThumb(thumbnail: playlist.thumbnail, count: playlist.countText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: YtText.rowTitle),
                  const SizedBox(height: 4),
                  Text(
                    [?playlist.channelName, 'Playlist'].join(' · '),
                    style: YtText.meta.copyWith(color: context.yt.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A playlist thumbnail: the image with a stacked-card edge and a count badge, like YouTube's.
class PlaylistThumb extends StatelessWidget {
  const PlaylistThumb({super.key, this.thumbnail, this.count, this.width = YtSizes.rowThumbWidth, this.icon});

  final String? thumbnail;
  final String? count;
  final double width;

  /// Shown instead of an image (Watch later, Liked videos).
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -4,
            left: 8,
            right: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.yt.textSecondary.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(YtSizes.thumbRadius),
              child: thumbnail != null
                  ? YtImage(thumbnail, width: width)
                  : ColoredBox(
                      color: context.yt.chip,
                      child: Icon(icon ?? Symbols.playlist_play, size: width / 5, color: context.yt.textSecondary),
                    ),
            ),
          ),
          if (count != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: YtColors.badge, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.playlist_play, size: 14, color: Colors.white),
                    const SizedBox(width: 2),
                    // "12 videos" → "12"; an empty playlist's "No videos" → "0".
                    Text(
                      count!.startsWith('No ') ? '0' : count!.replaceAll(' videos', '').replaceAll(' video', ''),
                      style: YtText.badge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Videos as YouTube lays them out for the width (docs/ui.md): one full-width card per row on phones, a grid of
/// [feedColumns] cards on tablets and TVs.
class VideoGridSliver extends StatelessWidget {
  const VideoGridSliver(this.videos, {super.key});

  final List<VideoItem> videos;

  /// The text under a grid card's thumbnail: avatar row with a two-line title and the meta line.
  static const _textHeight = 100.0;
  static const _spacing = 16.0;
  static const _sidePadding = 16.0;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = feedColumns(constraints.crossAxisExtent);
      if (columns == 1) {
        return SliverList.builder(itemCount: videos.length, itemBuilder: (context, i) => VideoCard(videos[i]));
      }
      final cell = (constraints.crossAxisExtent - 2 * _sidePadding - (columns - 1) * _spacing) / columns;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(_sidePadding, 8, _sidePadding, 16),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 24,
            crossAxisSpacing: _spacing,
            mainAxisExtent: cell * 9 / 16 + _textHeight,
          ),
          itemCount: videos.length,
          itemBuilder: (context, i) => VideoCard(videos[i], grid: true),
        ),
      );
    },
  );
}

/// Videos with a Shorts shelf among them (Home, Subscriptions): after [phoneShelfAt] cards on a phone, after the
/// first row of the grid on tablets and TVs.
class VideosWithShortsSliver extends StatelessWidget {
  const VideosWithShortsSliver({super.key, required this.videos, required this.shorts, required this.phoneShelfAt});

  final List<VideoItem> videos;
  final List<VideoItem> shorts;
  final int phoneShelfAt;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = feedColumns(constraints.crossAxisExtent);
      final split = math.min(videos.length, columns == 1 ? phoneShelfAt : columns);
      return SliverMainAxisGroup(
        slivers: [
          VideoGridSliver(videos.sublist(0, split)),
          if (shorts.isNotEmpty) SliverToBoxAdapter(child: ShortsShelf(items: shorts)),
          VideoGridSliver(videos.sublist(split)),
        ],
      );
    },
  );
}

/// Feed entries (search results, channel tabs) with each run of videos laid out by [VideoGridSliver], and Shorts,
/// shelves, channels and playlists full width between them. On a phone this is the plain list it always was.
class FeedSliver extends StatelessWidget {
  const FeedSliver(this.entries, {super.key});

  final List<FeedEntry> entries;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      for (final run in feedRuns(entries))
        if (run case final List<VideoItem> videos)
          VideoGridSliver(videos)
        else if (run case final FeedEntry e)
          SliverToBoxAdapter(
            // Channel and playlist rows keep a readable width on tablets and TVs; shelves use the full width.
            child: e is ItemEntry && e.item is! VideoItem
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxRowContentWidth),
                      child: FeedEntryView(e),
                    ),
                  )
                : FeedEntryView(e),
          ),
    ],
  );
}

/// [FeedSliver]'s grouping, in order: each run of consecutive videos (not Shorts) as one `List<VideoItem>`, and every
/// other entry (Shorts, shelves, channels, playlists) on its own.
List<Object> feedRuns(List<FeedEntry> entries) {
  final out = <Object>[];
  var run = <VideoItem>[];
  for (final e in entries) {
    if (e case ItemEntry(item: final VideoItem v) when !v.isShort) {
      run.add(v);
    } else {
      if (run.isNotEmpty) out.add(run);
      run = [];
      out.add(e);
    }
  }
  if (run.isNotEmpty) out.add(run);
  return out;
}

/// Renders a feed entry the way YouTube does: videos as cards, channels and playlists as rows, Shorts shelves,
/// and titled shelves as horizontal rows of smaller cards.
class FeedEntryView extends ConsumerWidget {
  const FeedEntryView(this.entry, {super.key});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (entry) {
    ItemEntry(item: final VideoItem v) when v.isShort => ShortsShelf(items: [v]),
    ItemEntry(item: final VideoItem v) => VideoCard(v),
    ItemEntry(item: final ChannelItem c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ChannelRow(c)),
    ItemEntry(item: final PlaylistItem p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: PlaylistRow(p)),
    ShelfEntry(shorts: true, :final title, :final items) => ShortsShelf(
      title: title.isEmpty ? 'Shorts' : title,
      items: items.whereType<VideoItem>().toList(),
    ),
    ShelfEntry(:final title, :final items) => HorizontalShelf(title: title, items: items),
  };
}

/// A titled horizontal row of small cards (a channel's shelves, "People also watched").
class HorizontalShelf extends ConsumerWidget {
  const HorizontalShelf({super.key, required this.title, required this.items});

  final String title;
  final List<YtItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const w = 240.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(title, style: YtText.sectionTitle.copyWith(fontSize: 18)),
            ),
          SizedBox(
            height: w * 9 / 16 + 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: w,
                child: SmallCard(items[i], width: w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small card for horizontal shelves and carousels.
class SmallCard extends ConsumerWidget {
  const SmallCard(this.item, {super.key, this.width = 240, this.progress});

  final YtItem item;
  final double width;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    final (thumb, title, meta) = switch (item) {
      VideoItem v => (v.thumbnailOrDefault, v.title, videoMeta(v)),
      PlaylistItem p => (p.thumbnail, p.title, [?p.channelName, 'Playlist'].join(' · ')),
      ChannelItem ch => (ch.avatar, ch.name, ch.subscribersText ?? ''),
    };
    return FocusHighlight(
      radius: YtSizes.thumbRadius,
      child: InkWell(
        onTap: () => openItem(context, ref, item),
        onLongPress: item is VideoItem ? () => showVideoMenu(context, ref, item as VideoItem) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item is PlaylistItem)
              PlaylistThumb(thumbnail: thumb, width: width, count: (item as PlaylistItem).countText)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(YtSizes.thumbRadius),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      YtImage(thumb, width: width),
                      if (item case final VideoItem v) ThumbnailOverlay(video: v, badgeInset: 4),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: YtText.rowTitle),
            const SizedBox(height: 2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: YtText.meta.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
