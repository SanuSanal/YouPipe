import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/video_menu.dart';
import '../../ui/widgets/video_tiles.dart';

/// The playlist header used by YouTube playlists and local ones alike.
class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader({
    super.key,
    required this.title,
    this.thumbnail,
    this.owner,
    this.onOwner,
    this.meta = const [],
    required this.onPlayAll,
    required this.onShuffle,
    this.actions = const [],
    this.icon,
  });

  final String title;
  final String? thumbnail;
  final String? owner;
  final VoidCallback? onOwner;
  final List<String> meta;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;
  final List<Widget> actions;

  /// Shown when there's no thumbnail (an empty Watch later).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
    return Stack(
      children: [
        // The header is tinted by its thumbnail, fading into the page.
        if (thumbnail != null)
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: ImageFiltered(
                imageFilter: ColorFilter.mode(c.background.withValues(alpha: 0.35), BlendMode.srcOver),
                child: YtImage(thumbnail, fit: BoxFit.cover),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.75,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: thumbnail != null
                          ? YtImage(thumbnail)
                          : ColoredBox(color: c.chip, child: Icon(icon ?? Symbols.playlist_play, size: 56)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
              if (owner != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onOwner,
                  child: Text('by $owner', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(meta.join(' · '), style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onPlayAll,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.subscribe,
                        foregroundColor: c.onSubscribe,
                        minimumSize: const Size(0, 40),
                      ),
                      icon: const Icon(Symbols.play_arrow, fill: 1),
                      label: const Text('Play all', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onShuffle,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.chip,
                        foregroundColor: c.textPrimary,
                        minimumSize: const Size(0, 40),
                      ),
                      icon: const Icon(Symbols.shuffle),
                      label: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Material(
      color: context.yt.chip,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, fill: filled ? 1 : 0),
      ),
    ),
  );
}

void _playList(BuildContext context, WidgetRef ref, List<VideoItem> videos, {bool shuffle = false}) {
  final list = videos.where((v) => !v.isShort).toList();
  if (list.isEmpty) return;
  if (shuffle) list.shuffle();
  playVideo(context, ref, list.first, queue: list);
}

/// A YouTube playlist.
class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(playlistProvider(playlistId));
    final videos = ref.watch(playlistVideosProvider(playlistId));
    final saved = ref.watch(isPlaylistSavedProvider(playlistId)).value ?? false;
    final items = videos.value?.items.whereType<VideoItem>().toList() ?? const <VideoItem>[];
    final p = page.value;
    Future<void> play({bool shuffle = false}) async {
      final all = await ref.read(playlistVideosProvider(playlistId).notifier).all();
      if (context.mounted) _playList(context, ref, all, shuffle: shuffle);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
      ),
      body: page.hasError
          ? ErrorView(error: page.error!, onRetry: () => ref.invalidate(playlistProvider(playlistId)))
          : p == null
          ? const LoadingView()
          : LoadMoreListener(
              onLoadMore: () => ref.read(playlistVideosProvider(playlistId).notifier).loadMore(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: PlaylistHeader(
                      title: p.title,
                      thumbnail: p.thumbnail,
                      owner: p.owner,
                      onOwner: p.ownerId == null ? null : () => openChannel(context, ref, p.ownerId!),
                      meta: p.metadata,
                      onPlayAll: items.isEmpty ? null : play,
                      onShuffle: items.isEmpty ? null : () => play(shuffle: true),
                      actions: [
                        _RoundAction(
                          icon: Symbols.library_add,
                          filled: saved,
                          onTap: () async {
                            await ref.read(libraryProvider).setPlaylistSaved(p.asItem, !saved);
                            if (context.mounted) {
                              showSnack(context, saved ? 'Removed from library' : 'Saved to library');
                            }
                          },
                        ),
                        _RoundAction(
                          icon: Symbols.share,
                          onTap: () => SharePlus.instance.share(
                            ShareParams(text: 'https://www.youtube.com/playlist?list=$playlistId'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => VideoRow(
                      items[i],
                      onTap: () => playVideo(context, ref, items[i], queue: items, index: i),
                    ),
                  ),
                  if (videos.isLoading || (videos.value?.loadingMore ?? false))
                    const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.all(24), child: LoadingView()),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  const SliverBottomInset(),
                ],
              ),
            ),
    );
  }
}

/// Watch later, Liked videos, or a playlist made in YouPipe. [id] is the playlist id, or -1 for Liked videos.
class LocalPlaylistScreen extends ConsumerWidget {
  const LocalPlaylistScreen({super.key, required this.id});

  final int id;

  static const liked = -1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = id == liked;
    final playlist = isLiked ? null : ref.watch(localPlaylistProvider(id)).value;
    final videos =
        (isLiked ? ref.watch(likedVideosProvider) : ref.watch(localPlaylistVideosProvider(id))).value ??
        const <VideoItem>[];
    final title = isLiked ? 'Liked videos' : playlist?.name ?? '';
    final userMade = !isLiked && playlist != null && !playlist.isWatchLater;
    final lib = ref.read(libraryProvider);
    void remove(VideoItem v) {
      unawaited(isLiked ? lib.setLiked(v, false) : lib.removeFromPlaylist(id, v.id));
      showSnack(context, 'Removed from $title');
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
        actions: [
          if (userMade)
            PopupMenuButton<String>(
              icon: const Icon(Symbols.more_vert),
              onSelected: (a) async {
                if (a == 'rename') {
                  final name = await promptText(context, title: 'Rename playlist', initial: playlist.name);
                  if (name != null && name.trim().isNotEmpty) await lib.renamePlaylist(id, name.trim());
                } else if (a == 'delete') {
                  // It can't be undone, so YouTube asks first.
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: const Text('Delete playlist?'),
                      content: Text('"${playlist.name}" will be permanently deleted.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await lib.deletePlaylist(id);
                  if (context.mounted) context.pop();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete playlist')),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PlaylistHeader(
              title: title,
              thumbnail: videos.firstOrNull?.thumbnailOrDefault,
              icon: isLiked ? Symbols.thumb_up : Symbols.schedule,
              meta: [if (userMade) 'Private' else 'Playlist', '${videos.length} video${videos.length == 1 ? '' : 's'}'],
              onPlayAll: videos.isEmpty ? null : () => _playList(context, ref, videos),
              onShuffle: videos.isEmpty ? null : () => _playList(context, ref, videos, shuffle: true),
            ),
          ),
          if (videos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: isLiked ? Symbols.thumb_up : Symbols.video_library,
                title: 'No videos in this playlist yet',
                message: isLiked ? 'Videos you like will show up here' : 'Save videos from their ⋮ menu',
              ),
            )
          else if (userMade || playlist?.isWatchLater == true)
            SliverReorderableList(
              itemCount: videos.length,
              onReorderItem: (from, to) => lib.movePlaylistItem(id, from, to),
              itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                key: ValueKey(videos[i].id),
                index: i,
                child: VideoRow(
                  videos[i],
                  onTap: () => playVideo(context, ref, videos[i], queue: videos, index: i),
                  onRemove: () => remove(videos[i]),
                  removeLabel: 'Remove from $title',
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: videos.length,
              itemBuilder: (context, i) => VideoRow(
                videos[i],
                onTap: () => playVideo(context, ref, videos[i], queue: videos, index: i),
                onRemove: () => remove(videos[i]),
                removeLabel: 'Remove from $title',
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverBottomInset(),
        ],
      ),
    );
  }
}
