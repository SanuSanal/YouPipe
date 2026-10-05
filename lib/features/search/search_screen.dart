import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/top_bar.dart';
import '../../ui/widgets/video_tiles.dart';

/// The search field page: history (clock icons) and suggestions as you type.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initial});

  final String? initial;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    if (ref.read(settingsProvider).saveSearchHistory) ref.read(libraryProvider).addSearch(query);
    // The keyboard closes with the search, as on YouTube; otherwise it stays up over the results and the watch page.
    FocusManager.instance.primaryFocus?.unfocus();
    context.pushReplacement(resultsPath(context, query));
  }

  @override
  Widget build(BuildContext context) {
    final input = _text.text;
    final history = ref.watch(searchHistoryProvider).value ?? const <String>[];
    final suggestions = ref.watch(searchSuggestionsProvider(input)).value ?? const <String>[];
    final matching = [
      for (final h in history)
        if (input.isEmpty || h.toLowerCase().startsWith(input.toLowerCase())) h,
    ].take(input.isEmpty ? 20 : 3).toList();
    final rows = [
      for (final h in matching) (h, true),
      for (final s in suggestions)
        if (!matching.contains(s)) (s, false),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: YtSizes.topBarHeight + 8,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
        titleSpacing: 0,
        title: SearchField(controller: _text, onChanged: (_) => setState(() {}), onSubmitted: _submit),
        actions: const [SizedBox(width: 12)],
      ),
      body: MaxContentWidth(
        child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final (text, isHistory) = rows[i];
            return ListTile(
              leading: Icon(isHistory ? Symbols.history : Symbols.search, weight: 300),
              title: Text(text, style: const TextStyle(fontSize: 15)),
              trailing: IconButton(
                onPressed: () => setState(() {
                  _text.text = '$text ';
                  _text.selection = TextSelection.collapsed(offset: _text.text.length);
                }),
                icon: const Icon(Symbols.north_west, weight: 300),
              ),
              onTap: () => _submit(text),
              onLongPress: isHistory
                  ? () async {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text(text),
                          content: const Text('Remove from search history?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Remove')),
                          ],
                        ),
                      );
                      if (remove == true) await ref.read(libraryProvider).removeSearch(text);
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// YouTube's rounded grey search field.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = true,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (readOnly) return _pill(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(color: context.yt.chip, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(hintText: 'Search YouPipe', isCollapsed: true, border: InputBorder.none),
      ),
    );
  }

  /// The read-only field (on the results page) is a button, so the TV remote's Select opens the search page too (a
  /// read-only TextField's onTap is touch-only).
  Widget _pill(BuildContext context) {
    final text = controller?.text ?? '';
    return SizedBox(
      height: 40,
      child: FocusHighlight(
        radius: 20,
        child: Material(
          color: context.yt.chip,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text.isEmpty ? 'Search YouPipe' : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: text.isEmpty ? context.yt.textSecondary : null),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search results with YouTube's filter sheet.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.query, this.params});

  final String query;
  final String? params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (query: query, params: params);
    final results = ref.watch(searchResultsProvider(key));
    final entries = results.value?.items ?? const <FeedEntry>[];
    return Scaffold(
      body: StatusBarScrim(
        child: LoadMoreListener(
          onLoadMore: () => ref.read(searchResultsProvider(key).notifier).loadMore(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                toolbarHeight: YtSizes.topBarHeight + 8,
                leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
                titleSpacing: 0,
                title: SearchField(
                  controller: TextEditingController(text: query),
                  readOnly: true,
                  onTap: () =>
                      context.pushReplacement('${branchPrefix(context)}/search?q=${Uri.encodeQueryComponent(query)}'),
                ),
                actions: [
                  IconButton(
                    onPressed: () => _showFilters(context, ref, key),
                    icon: Icon(Symbols.tune, weight: 300, fill: params == null ? 0 : 1),
                  ),
                ],
              ),
              if (results.isLoading && entries.isEmpty)
                const SliverToBoxAdapter(child: FeedSkeleton())
              else if (results.hasError && entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(error: results.error!, onRetry: () => ref.invalidate(searchResultsProvider(key))),
                )
              else if (entries.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: Symbols.search_off,
                    title: 'No results found',
                    message: 'Try different keywords',
                  ),
                )
              else
                SliverMainAxisGroup(
                  slivers: [
                    FeedSliver(entries),
                    SliverToBoxAdapter(
                      child: results.value?.loadingMore ?? false
                          ? const Padding(padding: EdgeInsets.all(24), child: LoadingView())
                          : const SizedBox(height: 24),
                    ),
                  ],
                ),
              const SliverBottomInset(),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref, SearchQuery key) {
    final groups = ref.read(searchResultsProvider(key).notifier).filters;
    if (groups.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (sheet, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const Text('Search filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(g.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in g.options)
                    YtChip(
                      label: o.label,
                      selected: o.selected,
                      // YouTube supplies the params for toggling an option off as well as on.
                      onTap: o.params == null
                          ? null
                          : () {
                              Navigator.of(sheet).pop();
                              context.pushReplacement(resultsPath(context, query, params: o.params));
                            },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
