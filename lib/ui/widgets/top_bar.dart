import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../layout.dart';
import '../navigation.dart';
import '../theme/yt_theme.dart';
import 'common.dart';

/// Extra top-bar actions registered by later features (the cast button).
final topBarExtraActions = <Widget Function(BuildContext)>[];

/// Keeps the status bar strip filled with the page background once [YtTopBar] has floated away, like YouTube
/// (otherwise the feed scrolls visibly under the clock and icons).
class StatusBarScrim extends StatelessWidget {
  const StatusBarScrim({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: MediaQuery.paddingOf(context).top,
        child: IgnorePointer(child: ColoredBox(color: context.yt.background)),
      ),
    ],
  );
}

/// YouTube's top bar: the wordmark on the left, then cast and search on the right. Floats away on scroll. On a TV
/// the search box comes first, on the left, and the wordmark moves to the right (docs/ui.md).
class YtTopBar extends ConsumerWidget {
  const YtTopBar({super.key, this.bottom, this.title});

  final PreferredSizeWidget? bottom;

  /// A page title instead of the wordmark (Subscriptions, You).
  final Widget? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tv = DeviceInfo.current.tv;
    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: YtSizes.topBarHeight,
      titleSpacing: tv ? 16 : 12,
      backgroundColor: context.yt.background,
      title: tv ? _TvSearchBox(onTap: () => openSearch(context, ref)) : title ?? const Wordmark(),
      actions: tv
          ? [title ?? const Wordmark(), const SizedBox(width: 24)]
          : [
              for (final a in topBarExtraActions) a(context),
              IconButton(
                onPressed: () => openSearch(context, ref),
                icon: const Icon(Symbols.search, size: 26, weight: 300),
              ),
              const SizedBox(width: 4),
            ],
      bottom: bottom,
    );
  }
}

/// The TV's search box: looks like a field, opens the search page (and its keyboard) on Select.
class _TvSearchBox extends StatelessWidget {
  const _TvSearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 360,
        height: 40,
        child: FocusHighlight(
          radius: 20,
          child: Material(
            color: c.chip,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Symbols.search, size: 22, color: c.textSecondary),
                    const SizedBox(width: 12),
                    Text('Search', style: TextStyle(color: c.textSecondary, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
