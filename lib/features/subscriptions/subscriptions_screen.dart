import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/subscriptions_feed.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/top_bar.dart';
import '../../ui/widgets/video_tiles.dart';

enum _Filter { all, today, videos, shorts, continueWatching, unwatched }

const _labels = {
  _Filter.all: 'All',
  _Filter.today: 'Today',
  _Filter.videos: 'Videos',
  _Filter.shorts: 'Shorts',
  _Filter.continueWatching: 'Continue watching',
  _Filter.unwatched: 'Unwatched',
};

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    ref.read(subscriptionsFeedServiceProvider).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider).value ?? const <ChannelItem>[];
    final feed = ref.watch(subscriptionFeedProvider);
    final progress = ref.watch(watchProgressProvider).value ?? const <String, double>{};
    final all = feed.value ?? const <FeedVideo>[];
    final now = DateTime.now();
    final filtered = [
      for (final f in all)
        if (switch (_filter) {
          _Filter.all => true,
          _Filter.today => now.difference(f.publishedAt).inHours < 24,
          _Filter.videos => !f.video.isShort,
          _Filter.shorts => f.video.isShort,
          _Filter.continueWatching => (progress[f.video.id] ?? 0) > 0 && (progress[f.video.id] ?? 0) < 0.9,
          _Filter.unwatched => !progress.containsKey(f.video.id),
        })
          f.video,
    ];
    final videos = filtered.where((v) => !v.isShort || _filter == _Filter.shorts).toList();
    final shorts = _filter == _Filter.all ? filtered.where((v) => v.isShort).take(12).toList() : const <VideoItem>[];

    return Scaffold(
      body: StatusBarScrim(
        child: RefreshIndicator(
          color: context.yt.textPrimary,
          onRefresh: () => ref.read(subscriptionsFeedServiceProvider).refresh(force: true),
          child: CustomScrollView(
            slivers: [
              const YtTopBar(),
              if (subs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: Symbols.subscriptions,
                    title: "Don't miss new videos",
                    message:
                        'Subscribe to channels to see their latest videos here. Subscriptions are kept on this device.',
                    action: FilledButton(onPressed: () => openSearch(context, ref), child: const Text('Find channels')),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _ChannelStrip(channels: subs)),
                SliverToBoxAdapter(
                  child: ChipBar(
                    children: [
                      for (final f in _Filter.values)
                        YtChip(label: _labels[f]!, selected: f == _filter, onTap: () => setState(() => _filter = f)),
                    ],
                  ),
                ),
                if (feed.isLoading && all.isEmpty)
                  const SliverToBoxAdapter(child: FeedSkeleton())
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      icon: Symbols.video_library,
                      title: all.isEmpty ? 'Loading your subscriptions…' : 'Nothing here',
                      message: all.isEmpty ? 'Pull down to refresh.' : 'Try another filter.',
                    ),
                  )
                else if (_filter == _Filter.shorts)
                  SliverPadding(
                    padding: const EdgeInsets.all(8),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 9 / 16,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (_, i) =>
                          LayoutBuilder(builder: (_, box) => ShortCard(videos[i], width: box.maxWidth)),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: videos.length + (shorts.isEmpty ? 0 : 1),
                    itemBuilder: (_, i) {
                      if (shorts.isNotEmpty && i == 1) return ShortsShelf(items: shorts);
                      final index = shorts.isNotEmpty && i > 1 ? i - 1 : i;
                      return VideoCard(videos[index]);
                    },
                  ),
              ],
              const SliverBottomInset(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The row of channel avatars with "All" at the end.
class _ChannelStrip extends ConsumerWidget {
  const _ChannelStrip({required this.channels});

  final List<ChannelItem> channels;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: 96,
    child: Row(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: channels.length,
            itemBuilder: (_, i) => InkWell(
              onTap: () => openChannel(context, ref, channels[i].id),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Avatar(channels[i].avatar, size: 56, name: channels[i].name),
                    const SizedBox(height: 6),
                    Text(
                      channels[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: context.yt.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push('${branchPrefix(context)}/channels'),
          style: TextButton.styleFrom(foregroundColor: context.yt.link),
          child: const Text('All', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

/// All subscriptions, A–Z, with Subscribe toggles.
class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  static final extraActions = <Widget Function(BuildContext, WidgetRef)>[];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(subscriptionsProvider).value ?? const <ChannelItem>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('All subscriptions'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
        actions: [for (final a in extraActions) a(context, ref)],
      ),
      body: subs.isEmpty
          ? const EmptyView(icon: Symbols.subscriptions, title: 'No subscriptions yet')
          : ListView.builder(
              itemCount: subs.length,
              itemBuilder: (_, i) => ListTile(
                leading: Avatar(subs[i].avatar, size: 40, name: subs[i].name),
                title: Text(subs[i].name),
                onTap: () => openChannel(context, ref, subs[i].id),
                trailing: SubscribeButton(subs[i], compact: true),
              ),
            ),
    );
  }
}
