import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/html_text.dart';
import '../../ui/widgets/video_tiles.dart';

/// Tabs YouPipe can show (Posts, Store and channel search aren't supported).
const _supportedTabs = {'Home', 'Videos', 'Shorts', 'Live', 'Releases', 'Playlists', 'Podcasts'};

class ChannelScreen extends ConsumerWidget {
  const ChannelScreen({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(channelProvider((channelId: channelId, params: null)));
    return page.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(channelProvider((channelId: channelId, params: null)))),
      ),
      data: (p) {
        // Keep the channel's name and picture fresh in Subscriptions.
        ref.read(libraryProvider).refreshSubscription(p.asItem);
        final tabs = p.tabs.where((t) => _supportedTabs.contains(t.title)).toList();
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  pinned: true,
                  title: Text(p.name),
                  leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
                  actions: [
                    IconButton(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: 'https://www.youtube.com/${p.handle ?? 'channel/${p.id}'}'),
                      ),
                      icon: const Icon(Symbols.share, weight: 300),
                    ),
                  ],
                ),
                SliverToBoxAdapter(child: _Header(page: p)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t.title)]),
                    context.yt.background,
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  for (final t in tabs) _TabContent(channelId: channelId, tab: t, initial: t.selected ? p : null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.page});

  final ChannelPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.yt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (page.banner != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AspectRatio(aspectRatio: 6.2, child: YtImage(page.banner, radius: 12)),
            ),
          Row(
            children: [
              Avatar(page.avatar, size: 72, name: page.name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (page.handle != null)
                      Text(page.handle!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      page.metadata.join(' · '),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (page.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  expand: false,
                  builder: (_, scroll) => ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      HtmlText(page.description!, style: const TextStyle(fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      page.description!.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                  ),
                  Icon(Symbols.chevron_right, color: c.textSecondary),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: SubscribeButton(page.asItem)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, this.color);

  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: color, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar || old.color != color;
}

class _TabContent extends ConsumerStatefulWidget {
  const _TabContent({required this.channelId, required this.tab, this.initial});

  final String channelId;
  final ChannelTab tab;
  final ChannelPage? initial;

  @override
  ConsumerState<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends ConsumerState<_TabContent> with AutomaticKeepAliveClientMixin {
  String? _sortToken;
  String _sortLabel = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final params = widget.tab.selected ? null : widget.tab.params;
    final tabPage = ref.watch(channelProvider((channelId: widget.channelId, params: params)));
    final key = (channelId: widget.channelId, params: params, sortToken: _sortToken);
    final list = ref.watch(channelListProvider(key));
    final entries = list.value?.items ?? const <FeedEntry>[];
    final chips = tabPage.value?.sortChips ?? const <SortChip>[];
    final isShorts = widget.tab.title == 'Shorts';
    final items = entries.allItems.toList();

    Widget body;
    if (list.isLoading && entries.isEmpty) {
      body = const SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.all(32), child: LoadingView()),
      );
    } else if (list.hasError && entries.isEmpty) {
      body = SliverToBoxAdapter(
        child: ErrorView(error: list.error!, compact: true, onRetry: () => ref.invalidate(channelListProvider(key))),
      );
    } else if (entries.isEmpty) {
      body = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'This channel has no ${widget.tab.title.toLowerCase()}',
              style: TextStyle(color: context.yt.textSecondary),
            ),
          ),
        ),
      );
    } else if (isShorts) {
      body = SliverPadding(
        padding: const EdgeInsets.all(4),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 9 / 16,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => switch (items[i]) {
            final VideoItem v => LayoutBuilder(builder: (context, box) => ShortCard(v, width: box.maxWidth)),
            _ => const SizedBox.shrink(),
          },
        ),
      );
    } else {
      body = SliverList.builder(itemCount: entries.length, itemBuilder: (context, i) => FeedEntryView(entries[i]));
    }

    return LoadMoreListener(
      onLoadMore: () => ref.read(channelListProvider(key).notifier).loadMore(),
      child: CustomScrollView(
        key: PageStorageKey(widget.tab.title),
        slivers: [
          if (chips.isNotEmpty)
            SliverToBoxAdapter(
              child: ChipBar(
                children: [
                  for (final c in chips)
                    YtChip(
                      label: c.label,
                      selected: _sortLabel.isEmpty ? c.selected : c.label == _sortLabel,
                      onTap: () => setState(() {
                        _sortLabel = c.label;
                        _sortToken = c.selected ? null : c.token;
                      }),
                    ),
                ],
              ),
            ),
          body,
          if (list.value?.loadingMore ?? false)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(24), child: LoadingView()),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverBottomInset(),
        ],
      ),
    );
  }
}
