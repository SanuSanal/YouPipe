import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

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

/// YouTube's top bar: the wordmark on the left, then cast and search on the right. Floats away on scroll.
class YtTopBar extends ConsumerWidget {
  const YtTopBar({super.key, this.bottom, this.title});

  final PreferredSizeWidget? bottom;

  /// A page title instead of the wordmark (Subscriptions, You).
  final Widget? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SliverAppBar(
    floating: true,
    snap: true,
    toolbarHeight: YtSizes.topBarHeight,
    titleSpacing: 12,
    backgroundColor: context.yt.background,
    title: title ?? const Wordmark(),
    actions: [
      for (final a in topBarExtraActions) a(context),
      IconButton(onPressed: () => openSearch(context, ref), icon: const Icon(Symbols.search, size: 26, weight: 300)),
      const SizedBox(width: 4),
    ],
    bottom: bottom,
  );
}
