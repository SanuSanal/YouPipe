import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/ryd.dart';
import '../../data/video_info.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/html_text.dart';
import '../../ui/widgets/video_menu.dart';
import '../../ui/widgets/video_tiles.dart';
import '../../util/format.dart';

enum WatchSheet { none, description, comments, queue }

/// Everything under the player on the watch page.
class WatchDetails extends ConsumerWidget {
  const WatchDetails({super.key, required this.onSheet, this.showRelated = true});

  final ValueChanged<WatchSheet> onSheet;

  /// False on wide screens, where [RelatedList] has its own column next to the player.
  final bool showRelated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(playbackProvider);
    if (now == null) return const SizedBox.shrink();
    final video = now.video;
    final info = ref.watch(currentInfoProvider);
    final infoForThis = info?.videoId == video.id ? info : null;
    final related = ref.watch(relatedProvider(video.id));
    final c = context.yt;
    final relatedItems = related.value?.items ?? const <YtItem>[];
    return LoadMoreListener(
      onLoadMore: () => ref.read(relatedProvider(video.id).notifier).loadMore(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FocusHighlight(
              radius: 8,
              child: InkWell(
                onTap: () => onSheet(WatchSheet.description),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        infoForThis?.title ?? video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: YtText.watchTitle.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: YtText.meta.copyWith(color: c.textSecondary),
                          children: [
                            TextSpan(
                              text: [
                                if (infoForThis != null && infoForThis.viewCount >= 0)
                                  infoForThis.isLive
                                      ? '${compactCount(infoForThis.viewCount)} watching'
                                      : viewsLabel(infoForThis.viewCount)
                                else
                                  ?video.viewsText,
                                ?relativeDate(infoForThis?.uploadDate) ?? video.publishedText,
                              ].join('  '),
                            ),
                            TextSpan(
                              text: '  ...more',
                              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ChannelRow(video: video, info: infoForThis),
          ),
          SliverToBoxAdapter(
            child: _Actions(video: video, info: infoForThis),
          ),
          SliverToBoxAdapter(
            child: _CommentsTeaser(videoId: video.id, onTap: () => onSheet(WatchSheet.comments)),
          ),
          if (now.queue.length > 1)
            SliverToBoxAdapter(
              child: _QueueCard(now: now, onTap: () => onSheet(WatchSheet.queue)),
            ),
          if (showRelated) ..._relatedSlivers(related.isLoading, relatedItems, compact: false),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// The related videos as their own column, next to the player on wide screens (YouTube tablet's layout).
class RelatedList extends ConsumerWidget {
  const RelatedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(playbackProvider);
    if (now == null) return const SizedBox.shrink();
    final related = ref.watch(relatedProvider(now.video.id));
    return LoadMoreListener(
      onLoadMore: () => ref.read(relatedProvider(now.video.id).notifier).loadMore(),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ..._relatedSlivers(related.isLoading, related.value?.items ?? const [], compact: true),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// Related videos as cards (under the details) or as compact rows (in the side column).
List<Widget> _relatedSlivers(bool loading, List<YtItem> items, {required bool compact}) => [
  if (loading && items.isEmpty)
    const SliverToBoxAdapter(
      child: Padding(padding: EdgeInsets.only(top: 12), child: FeedSkeleton(count: 2)),
    ),
  SliverList.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => switch (items[i]) {
      final VideoItem v => compact ? VideoRow(v) : VideoCard(v),
      final ChannelItem ch => ChannelRow(ch),
      final PlaylistItem p => PlaylistRow(p),
    },
  ),
];

class _ChannelRow extends ConsumerWidget {
  const _ChannelRow({required this.video, required this.info});

  final VideoItem video;
  final VideoInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = info?.channelId ?? video.channelId;
    final name = info?.channelName ?? video.channelName ?? '';
    final avatar = info?.channelAvatar ?? video.channelAvatar;
    final subs = info?.subscriberCount ?? -1;
    return FocusHighlight(
      radius: 8,
      child: InkWell(
        onTap: id == null ? null : () => openChannel(context, ref, id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Avatar(avatar, size: 36, name: name),
              const SizedBox(width: 12),
              Flexible(
                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: YtText.channelName),
              ),
              if (subs >= 0) ...[
                const SizedBox(width: 8),
                Text(compactCount(subs), style: YtText.meta.copyWith(color: context.yt.textSecondary)),
              ],
              const Spacer(),
              if (id != null) SubscribeButton(ChannelItem(id: id, name: name, avatar: avatar)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.video, required this.info});

  final VideoItem video;
  final VideoInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(isLikedProvider(video.id)).value ?? false;
    final votes = ref.watch(votesProvider(video.id)).value;
    final likes = (info?.likeCount ?? -1) >= 0 ? info!.likeCount : votes?.likes;
    final c = context.yt;
    return SizedBox(
      height: YtSizes.pillHeight + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          PillButton(
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    await ref.read(libraryProvider).setLiked(video, !liked);
                    if (context.mounted) {
                      showSnack(context, liked ? 'Removed from Liked videos' : 'Added to Liked videos');
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Symbols.thumb_up, size: 20, fill: liked ? 1 : 0),
                      if (likes != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          compactCount(likes + (liked ? 1 : 0)),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 12), color: c.divider),
                const Icon(Symbols.thumb_down, size: 20),
                if (votes != null) ...[
                  const SizedBox(width: 6),
                  Text(compactCount(votes.dislikes), style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(icon: Symbols.share, label: 'Share', onTap: () => shareVideo(video)),
          const SizedBox(width: 8),
          if (downloadStarter != null && !video.isLive) ...[
            downloadPillBuilder?.call(context, ref, video) ??
                PillButton(
                  icon: Symbols.download,
                  label: 'Download',
                  onTap: () => downloadStarter!(context, ref, video),
                ),
            const SizedBox(width: 8),
          ],
          PillButton(icon: Symbols.playlist_add, label: 'Save', onTap: () => showSaveToPlaylist(context, ref, video)),
          const SizedBox(width: 8),
          PillButton(
            icon: Symbols.schedule,
            label: 'Watch later',
            onTap: () async {
              await ref.read(libraryProvider).toggleWatchLater(video);
              if (context.mounted) showSnack(context, 'Watch later updated');
            },
          ),
        ],
      ),
    );
  }
}

class _CommentsTeaser extends ConsumerWidget {
  const _CommentsTeaser({required this.videoId, required this.onTap});

  final String videoId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (videoId: videoId, sortToken: null);
    final comments = ref.watch(commentsProvider(key));
    final count = ref.read(commentsProvider(key).notifier).count;
    final first = comments.value?.items.firstOrNull;
    final c = context.yt;
    if (comments.hasError) return const SizedBox(height: 12);
    if (comments.hasValue && first == null && count == null) {
      // Comments are turned off for this video.
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Text('Comments are turned off.', style: TextStyle(color: c.textSecondary, fontSize: 13)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Material(
        color: c.chip,
        borderRadius: BorderRadius.circular(12),
        child: FocusHighlight(
          radius: 12,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Comments',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (count != null)
                          TextSpan(
                            text: '  ${shortCount(count)}',
                            style: TextStyle(color: c.textSecondary),
                          ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (first == null)
                    Text('Loading comments…', style: TextStyle(color: c.textSecondary, fontSize: 13))
                  else
                    Row(
                      children: [
                        Avatar(first.authorAvatar, size: 24, name: first.author.replaceFirst('@', '')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            first.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
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
    );
  }
}

/// "2,458,072" → "2.4M".
String shortCount(String grouped) {
  final n = int.tryParse(grouped.replaceAll(RegExp(r'[^0-9]'), ''));
  return n == null ? grouped : compactCount(n);
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.now, required this.onTap});

  final NowPlaying now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final next = now.hasNextInQueue ? now.queue[now.index + 1] : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Material(
        color: context.yt.chip,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Symbols.queue_music),
          title: Text('Queue · ${now.index + 1} / ${now.queue.length}'),
          subtitle: next == null ? null : Text('Next: ${next.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Symbols.expand_more),
        ),
      ),
    );
  }
}

// Panels shown under the player ---------------------------------------------------------------------------------

/// The header of the Description / Comments / Queue panels.
class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.title, this.trailing, required this.onClose});

  final Widget title;
  final Widget? trailing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.yt.textSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
        child: Row(
          children: [
            DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              child: title,
            ),
            const Spacer(),
            ?trailing,
            IconButton(onPressed: onClose, icon: const Icon(Symbols.close)),
          ],
        ),
      ),
      const Divider(),
    ],
  );
}

class DescriptionPanel extends ConsumerWidget {
  const DescriptionPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(playbackProvider);
    final info = ref.watch(currentInfoProvider);
    final votes = now == null ? null : ref.watch(votesProvider(now.video.id)).value;
    final c = context.yt;
    void seek(Duration d) => ref.read(playerControllerProvider)?.seekTo(d);
    final date = info?.uploadDate == null ? null : DateTime.tryParse(info!.uploadDate!);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final likes = (info?.likeCount ?? -1) >= 0 ? info!.likeCount : votes?.likes;
    return Column(
      children: [
        PanelHeader(title: const Text('Description'), onClose: onClose),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(info?.title ?? now?.video.title ?? '', style: YtText.watchTitle.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(likes == null ? '–' : compactCount(likes), 'Likes'),
                  _Stat(
                    info == null || info.viewCount < 0 ? '–' : _grouped(info.viewCount),
                    info?.isLive == true ? 'Watching' : 'Views',
                  ),
                  if (date != null)
                    _Stat('${months[date.month - 1]} ${date.day}', '${date.year}')
                  else
                    _Stat(relativeDate(info?.uploadDate) ?? '–', ''),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(12)),
                child: info == null
                    ? const LoadingView()
                    : HtmlText(
                        info.description,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                        onTimestamp: (d) {
                          seek(d);
                          onClose();
                        },
                        onHashtag: (tag) => openSearch(context, ref, query: tag),
                      ),
              ),
              if (info != null && info.chapters.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Chapters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: info.chapters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final ch = info.chapters[i];
                      return FocusHighlight(
                        radius: 8,
                        child: InkWell(
                          onTap: () {
                            seek(ch.start);
                            onClose();
                          },
                          child: SizedBox(
                            width: 160,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                YtImage(ch.thumbnail, width: 160, height: 90, radius: 8),
                                const SizedBox(height: 6),
                                Text(ch.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: YtText.rowTitle),
                                Text(
                                  formatDuration(ch.start),
                                  style: TextStyle(color: c.link, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _grouped(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(fontSize: 12, color: context.yt.textSecondary)),
    ],
  );
}

class CommentsPanel extends ConsumerStatefulWidget {
  const CommentsPanel({super.key, required this.videoId, required this.onClose});

  final String videoId;
  final VoidCallback onClose;

  @override
  ConsumerState<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends ConsumerState<CommentsPanel> {
  String? _sortToken;
  String? _sortLabel;
  List<SortChip> _sorts = const [];

  @override
  Widget build(BuildContext context) {
    final key = (videoId: widget.videoId, sortToken: _sortToken);
    final comments = ref.watch(commentsProvider(key));
    final notifier = ref.read(commentsProvider(key).notifier);
    if (notifier.sorts.isNotEmpty) _sorts = notifier.sorts;
    final count = notifier.count;
    final items = comments.value?.items ?? const <CommentData>[];
    return Column(
      children: [
        PanelHeader(
          title: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Comments'),
                if (count != null)
                  TextSpan(
                    text: '  ${shortCount(count)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: context.yt.textSecondary),
                  ),
              ],
            ),
          ),
          onClose: widget.onClose,
        ),
        if (_sorts.length > 1)
          ChipBar(
            children: [
              for (final s in _sorts)
                YtChip(
                  label: s.label,
                  selected: _sortLabel == null ? s.selected : s.label == _sortLabel,
                  onTap: () => setState(() {
                    _sortLabel = s.label;
                    _sortToken = s.token;
                  }),
                ),
            ],
          ),
        Expanded(
          child: comments.hasError && items.isEmpty
              ? ErrorView(error: comments.error!, compact: true, onRetry: () => ref.invalidate(commentsProvider(key)))
              : LoadMoreListener(
                  onLoadMore: () => ref.read(commentsProvider(key).notifier).loadMore(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: items.length + 1,
                    itemBuilder: (context, i) => i == items.length
                        ? (comments.isLoading || (comments.value?.loadingMore ?? false)
                              ? const Padding(padding: EdgeInsets.all(24), child: LoadingView())
                              : const SizedBox.shrink())
                        : CommentTile(items[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class CommentTile extends ConsumerStatefulWidget {
  const CommentTile(this.comment, {super.key, this.isReply = false});

  final CommentData comment;
  final bool isReply;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  bool _expanded = false;
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final cm = widget.comment;
    final c = context.yt;
    final meta = YtText.meta.copyWith(color: c.textSecondary);
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.isReply ? 0 : 16, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: cm.authorChannelId == null ? null : () => openChannel(context, ref, cm.authorChannelId!),
            child: Avatar(cm.authorAvatar, size: widget.isReply ? 24 : 32, name: cm.author.replaceFirst('@', '')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cm.pinnedText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(Symbols.keep, size: 14, color: c.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(cm.pinnedText!, style: meta, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Flexible(
                      child: cm.isCreator
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(10)),
                              child: Text(cm.author, style: meta.copyWith(color: c.textPrimary)),
                            )
                          : Text(cm.author, style: meta, overflow: TextOverflow.ellipsis),
                    ),
                    if (cm.verified) ...[
                      const SizedBox(width: 2),
                      Icon(Symbols.check_circle, size: 12, fill: 1, color: c.textSecondary),
                    ],
                    Text(' · ${cm.published ?? ''}', style: meta),
                  ],
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: HtmlText(
                    cm.text,
                    maxLines: _expanded ? null : 4,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                    onTimestamp: (d) => ref.read(playerControllerProvider)?.seekTo(d),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Symbols.thumb_up, size: 16, color: c.textPrimary),
                    if (cm.likes != null && cm.likes!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(cm.likes!, style: meta),
                    ],
                    const SizedBox(width: 20),
                    Icon(Symbols.thumb_down, size: 16, color: c.textPrimary),
                    if (cm.hearted) ...[
                      const SizedBox(width: 20),
                      const Icon(Symbols.favorite, size: 16, fill: 1, color: YtColors.red),
                    ],
                  ],
                ),
                if (cm.repliesToken != null && cm.replyCount > 0 && !widget.isReply)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      foregroundColor: c.link,
                    ),
                    onPressed: () => setState(() => _showReplies = !_showReplies),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_showReplies ? Symbols.expand_less : Symbols.expand_more, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${cm.replyCount} ${cm.replyCount == 1 ? 'reply' : 'replies'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (_showReplies && cm.repliesToken != null) _Replies(token: cm.repliesToken!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Replies extends ConsumerWidget {
  const _Replies({required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replies = ref.watch(repliesProvider(token));
    final items = replies.value?.items ?? const <CommentData>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in items) CommentTile(r, isReply: true),
        if (replies.isLoading) const Padding(padding: EdgeInsets.all(12), child: LoadingView()),
        if (replies.value?.hasMore ?? false)
          TextButton(
            onPressed: () => ref.read(repliesProvider(token).notifier).loadMore(),
            style: TextButton.styleFrom(foregroundColor: context.yt.link),
            child: const Text('Show more replies'),
          ),
      ],
    );
  }
}

class QueuePanel extends ConsumerWidget {
  const QueuePanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(playbackProvider);
    if (now == null) return const SizedBox.shrink();
    return Column(
      children: [
        PanelHeader(title: Text('Queue · ${now.index + 1}/${now.queue.length}'), onClose: onClose),
        Expanded(
          child: ListView.builder(
            // Explicit, or the list adds the status bar's height on top (it reads the screen's insets).
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: now.queue.length,
            itemBuilder: (context, i) => Container(
              color: i == now.index ? context.yt.chip : null,
              child: VideoRow(
                now.queue[i],
                thumbWidth: 120,
                onTap: () {
                  unawaited(ref.read(playbackProvider.notifier).play(now.queue[i], queue: now.queue, index: i));
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
