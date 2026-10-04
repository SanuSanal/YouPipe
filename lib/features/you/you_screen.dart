import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/library_repository.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/top_bar.dart';
import '../../ui/widgets/video_menu.dart';
import '../../ui/widgets/video_tiles.dart';
import '../playlist/playlist_screen.dart';

/// Entries added by later features (Downloads, account) as (icon, label, onTap).
typedef YouEntry = ({IconData icon, String label, void Function(BuildContext, WidgetRef) onTap});
final youExtraEntries = <YouEntry>[];

/// A widget shown at the top of You (the account header once sign-in exists).
Widget Function(BuildContext, WidgetRef)? youHeaderBuilder;

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value ?? const <HistoryEntry>[];
    final playlists = ref.watch(localPlaylistsProvider).value ?? const <LocalPlaylistSummary>[];
    final liked = ref.watch(likedVideosProvider).value ?? const <VideoItem>[];
    final saved = ref.watch(savedPlaylistsProvider).value ?? const <PlaylistItem>[];
    final c = context.yt;

    Widget sectionTitle(String title, VoidCallback? onViewAll) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 8, 12),
      child: Row(
        children: [
          Text(title, style: YtText.sectionTitle),
          const Spacer(),
          if (onViewAll != null)
            OutlinedButton(
              onPressed: onViewAll,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: c.divider),
                foregroundColor: c.textPrimary,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('View all'),
            ),
        ],
      ),
    );

    return Scaffold(
      body: StatusBarScrim(
        child: CustomScrollView(
          slivers: [
            YtTopBar(title: const SizedBox.shrink()),
            SliverToBoxAdapter(
              child:
                  youHeaderBuilder?.call(context, ref) ??
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: c.chip,
                          child: Icon(Symbols.person, size: 40, color: c.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('You', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                              Text(
                                'Your library lives on this device',
                                style: TextStyle(color: c.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            SliverToBoxAdapter(
              child: sectionTitle('History', history.isEmpty ? null : () => openHistory(context, ref)),
            ),
            SliverToBoxAdapter(
              child: history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Videos you watch will show up here", style: TextStyle(color: c.textSecondary)),
                    )
                  : SizedBox(
                      height: 160 * 9 / 16 + 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: history.length.clamp(0, 20),
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(width: 160, child: SmallCard(history[i].video, width: 160)),
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 8, 12),
                child: Row(
                  children: [
                    const Text('Playlists', style: YtText.sectionTitle),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        final name = await promptText(context, title: 'New playlist', hint: 'Choose a title');
                        if (name != null && name.trim().isNotEmpty) {
                          await ref.read(libraryProvider).createPlaylist(name.trim());
                        }
                      },
                      icon: const Icon(Symbols.add),
                      tooltip: 'New playlist',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160 * 9 / 16 + 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _PlaylistCard(
                      title: 'Liked videos',
                      subtitle: '${liked.length} videos',
                      thumbnail: liked.firstOrNull?.thumbnailOrDefault,
                      icon: Symbols.thumb_up,
                      onTap: () => context.push('${branchPrefix(context)}/local/${LocalPlaylistScreen.liked}'),
                    ),
                    for (final p in playlists)
                      _PlaylistCard(
                        title: p.playlist.name,
                        subtitle: p.playlist.isWatchLater ? '${p.count} videos' : 'Private · ${p.count} videos',
                        thumbnail: p.thumbnail,
                        icon: p.playlist.isWatchLater ? Symbols.schedule : null,
                        onTap: () => openLocalPlaylist(context, ref, p.playlist.id),
                      ),
                    for (final s in saved)
                      _PlaylistCard(
                        title: s.title,
                        subtitle: s.channelName ?? 'Playlist',
                        thumbnail: s.thumbnail,
                        onTap: () => openPlaylist(context, ref, s.id),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: Divider()),
            SliverList.list(
              children: [
                for (final e in youExtraEntries)
                  ListTile(
                    leading: Icon(e.icon, weight: 300),
                    title: Text(e.label),
                    onTap: () => e.onTap(context, ref),
                  ),
                ListTile(
                  leading: const Icon(Symbols.subscriptions, weight: 300),
                  title: const Text('Your subscriptions'),
                  onTap: () => openChannels(context, ref),
                ),
                ListTile(
                  leading: const Icon(Symbols.history, weight: 300),
                  title: const Text('History'),
                  onTap: () => openHistory(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Symbols.settings, weight: 300),
                  title: const Text('Settings'),
                  onTap: () => openSettings(context, ref),
                ),
                const SizedBox(height: 24),
              ],
            ),
            const SliverBottomInset(),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.title, required this.subtitle, this.thumbnail, this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final String? thumbnail;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            PlaylistThumb(thumbnail: thumbnail, icon: icon),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: YtText.rowTitle),
            Text(subtitle, style: YtText.meta.copyWith(color: context.yt.textSecondary)),
          ],
        ),
      ),
    ),
  );
}

/// Watch history, newest first, grouped like YouTube (Today, Yesterday, This week, then by month).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value ?? const <HistoryEntry>[];
    final lib = ref.read(libraryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    String group(DateTime t) {
      final day = DateTime(t.year, t.month, t.day);
      final d = today.difference(day).inDays;
      if (d <= 0) return 'Today';
      if (d == 1) return 'Yesterday';
      if (d < 7) return 'This week';
      return t.year == now.year ? months[t.month - 1] : '${months[t.month - 1]} ${t.year}';
    }

    final rows = <Object>[];
    String? last;
    for (final h in history) {
      final g = group(h.watchedAt);
      if (g != last) rows.add(g);
      last = g;
      rows.add(h);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Clear all watch history',
              icon: const Icon(Symbols.delete),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Clear watch history?'),
                    content: const Text('Your watch history will be cleared from this device.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Clear watch history')),
                    ],
                  ),
                );
                if (ok == true) await lib.clearHistory();
              },
            ),
        ],
      ),
      body: MaxContentWidth(
        child: history.isEmpty
            ? const EmptyView(
                icon: Symbols.history,
                title: 'Keep track of what you watch',
                message: 'Watch history isn\'t viewable when empty.',
              )
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  final String g => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Text(g, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  final HistoryEntry h => VideoRow(
                    h.video,
                    onRemove: () {
                      unawaited(lib.removeFromHistory(h.video.id));
                      showSnack(context, 'Removed from watch history');
                    },
                    removeLabel: 'Remove from watch history',
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
      ),
    );
  }
}
