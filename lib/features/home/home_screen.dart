import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/home_feed.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/top_bar.dart';
import '../../ui/widgets/video_tiles.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final chip = ref.watch(homeChipProvider);
    final shorts = ref.watch(homeShortsProvider).value ?? const <VideoItem>[];
    final hasHistory = (ref.watch(historyProvider).value ?? const []).isNotEmpty;
    final hasSubs = (ref.watch(subscriptionsProvider).value ?? const []).isNotEmpty;
    final chips = [
      for (final c in HomeChip.defaults)
        if (c.kind != HomeChipKind.subscriptions || hasSubs) c,
    ];
    final items = home.value?.items ?? const <VideoItem>[];
    // YouTube puts a Shorts shelf after the first couple of videos.
    const shelfAt = 2;

    return Scaffold(
      body: StatusBarScrim(
        child: RefreshIndicator(
          color: context.yt.textPrimary,
          onRefresh: () async {
            ref.invalidate(homeShortsProvider);
            ref.invalidate(homeProvider);
            await ref.read(homeProvider.future);
          },
          child: LoadMoreListener(
            onLoadMore: () => ref.read(homeProvider.notifier).loadMore(),
            child: Listener(
              onPointerDown: (_) => HomeController.touched = true,
              child: CustomScrollView(
                slivers: [
                  YtTopBar(
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(YtSizes.chipHeight + 16),
                      child: ChipBar(
                        children: [
                          for (final c in chips)
                            YtChip(
                              label: c.label,
                              selected: c == chip,
                              onTap: () => ref.read(homeChipProvider.notifier).select(c),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (chip == HomeChip.all && !hasHistory && !hasSubs && home.hasValue)
                    const SliverToBoxAdapter(child: _StartCard()),
                  if (home.isLoading && items.isEmpty)
                    const SliverToBoxAdapter(child: FeedSkeleton())
                  else if (home.hasError && items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorView(error: home.error!, onRetry: () => ref.invalidate(homeProvider)),
                    )
                  else if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        icon: Symbols.search,
                        title: 'Try searching to get started',
                        message: 'Start watching videos to help us build a feed of videos you\'ll love.',
                        action: FilledButton(onPressed: () => openSearch(context, ref), child: const Text('Search')),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: items.length + (shorts.isEmpty ? 0 : 1) + 1,
                      itemBuilder: (context, i) {
                        final withShelf = shorts.isNotEmpty;
                        if (withShelf && i == shelfAt) return ShortsShelf(items: shorts);
                        final index = withShelf && i > shelfAt ? i - 1 : i;
                        if (index >= items.length) {
                          return home.value?.loadingMore ?? false
                              ? const Padding(padding: EdgeInsets.all(24), child: LoadingView())
                              : const SizedBox(height: 24);
                        }
                        return VideoCard(items[index]);
                      },
                    ),
                  const SliverBottomInset(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown on a fresh install: Home is built on this device from what you watch and subscribe to.
class _StartCard extends ConsumerWidget {
  const _StartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    margin: const EdgeInsets.fromLTRB(12, 4, 12, 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: context.yt.divider),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your feed, on your phone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          'YouPipe builds Home from what you watch and the channels you subscribe to, all stored on this device. '
          'Until then, here are popular videos.',
          style: TextStyle(color: context.yt.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );
}
