import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../layout.dart';
import '../theme/yt_theme.dart';

/// A network image sized to its box (decoded at the box's pixel size), with YouTube's grey placeholder.
class YtImage extends StatelessWidget {
  const YtImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = 0,
    this.circle = false,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final bool circle;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: context.yt.skeleton);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final u = url;
    Widget image = u == null
        ? placeholder
        : CachedNetworkImage(
            imageUrl: u,
            fit: fit,
            memCacheWidth: width == null ? null : (width! * dpr).round(),
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
    if (circle) {
      image = ClipOval(child: image);
    } else if (radius > 0) {
      image = ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
    }
    return SizedBox(width: width, height: height, child: image);
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.url, {super.key, this.size = YtSizes.feedAvatar, this.name});

  final String? url;
  final double size;

  /// Shows the initial when there's no picture.
  final String? name;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: context.yt.chip,
        child: Text(
          (name ?? '?').replaceFirst('@', '').characters.firstOrNull?.toUpperCase() ?? '?',
          style: TextStyle(fontSize: size * 0.42, color: context.yt.textPrimary, fontWeight: FontWeight.w500),
        ),
      );
    }
    return YtImage(url, width: size, height: size, circle: true);
  }
}

/// The YouPipe wordmark for the top bar: the mark plus "YouPipe".
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.height = 22});

  final double height;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset('assets/branding/logo.svg', height: height * 1.45),
      const SizedBox(width: 1),
      Text(
        'YouPipe',
        style: TextStyle(
          fontSize: height * 0.92,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
          color: context.yt.textPrimary,
          height: 1,
        ),
      ),
    ],
  );
}

/// YouPipe's Shorts glyph: a phone-shaped rounded rectangle with a play triangle. It's our own mark, not YouTube's.
class ShortsIcon extends StatelessWidget {
  const ShortsIcon({super.key, this.size = 24, this.color, this.filled = false});

  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ShortsPainter(color ?? IconTheme.of(context).color ?? context.yt.textPrimary, filled),
  );
}

class _ShortsPainter extends CustomPainter {
  _ShortsPainter(this.color, this.filled);

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(5.5 * s, 2.5 * s, 13 * s, 19 * s), Radius.circular(4 * s));
    final play = Path()
      ..moveTo(10 * s, 8.5 * s)
      ..lineTo(15.5 * s, 12 * s)
      ..lineTo(10 * s, 15.5 * s)
      ..close();
    if (filled) {
      canvas.drawPath(Path.combine(PathOperation.difference, Path()..addRRect(body), play), Paint()..color = color);
    } else {
      canvas.drawRRect(
        body,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * s,
      );
      canvas.drawPath(play, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ShortsPainter old) => old.color != color || old.filled != filled;
}

/// A YouTube chip (Home topics, search filters, sort options).
class YtChip extends StatelessWidget {
  const YtChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
    final fg = selected ? c.onChipSelected : c.textPrimary;
    return FocusHighlight(
      radius: YtSizes.chipRadius,
      child: Material(
        color: selected ? c.chipSelected : c.chip,
        borderRadius: BorderRadius.circular(YtSizes.chipRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(YtSizes.chipRadius),
          onTap: onTap,
          child: Container(
            height: YtSizes.chipHeight,
            padding: EdgeInsets.symmetric(horizontal: icon != null && label.isEmpty ? 8 : 12),
            // widthFactor 1: hug the label even under a bounded width (in a Wrap), instead of stretching.
            child: Align(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, size: 20, color: fg),
                  if (icon != null && label.isNotEmpty) const SizedBox(width: 6),
                  if (label.isNotEmpty) Text(label, style: YtText.chip.copyWith(color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of chips.
class ChipBar extends StatelessWidget {
  const ChipBar({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 12)});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: YtSizes.chipHeight + 16,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: padding.add(const EdgeInsets.symmetric(vertical: 8)),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => children[i],
    ),
  );
}

/// The rounded pill buttons under a video (Share, Download, Save…).
class PillButton extends StatelessWidget {
  const PillButton({super.key, this.icon, this.label, this.onTap, this.filledIcon = false, this.child});

  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final bool filledIcon;

  /// Replaces the icon + label (e.g. the like/dislike pair).
  final Widget? child;

  @override
  Widget build(BuildContext context) => FocusHighlight(
    radius: 18,
    child: Material(
      color: context.yt.chip,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: YtSizes.pillHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child:
                child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) Icon(icon, size: 20, fill: filledIcon ? 1 : 0),
                    if (icon != null && label != null) const SizedBox(width: 6),
                    if (label != null) Text(label!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
          ),
        ),
      ),
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 3, color: context.yt.textSecondary),
    ),
  );
}

/// Grey card shapes while a feed loads, like YouTube's skeletons.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.yt.skeleton;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
    );
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ColoredBox(color: c),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 18, backgroundColor: c),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [bar(double.infinity, 14), const SizedBox(height: 8), bar(160, 12)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A friendly error with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = '$error';
    final offline =
        text.contains('SocketException') || text.contains('connection') || text.contains('Failed host lookup');
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(offline ? Symbols.wifi_off : Symbols.error, size: compact ? 32 : 64, color: context.yt.textSecondary),
            const SizedBox(height: 16),
            Text(
              offline ? 'No connection' : 'Something went wrong',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              offline ? 'Check your internet connection and try again.' : 'Tap to retry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.yt.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: context.yt.divider),
                  foregroundColor: context.yt.link,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 96, color: context.yt.textSecondary, weight: 200),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(color: context.yt.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

/// Loads more when a scrollable gets near its end.
/// The end of a sliver page: room for the floating mini player when it's showing (the shell sets it as the
/// bottom padding), so the last item can scroll clear of it.
class SliverBottomInset extends StatelessWidget {
  const SliverBottomInset({super.key});

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom));
}

/// Pages of rows (playlists, history, settings) stay a readable width on tablets and TVs, centred; on phones this
/// changes nothing.
class MaxContentWidth extends StatelessWidget {
  const MaxContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxRowContentWidth),
      child: child,
    ),
  );
}

/// A radio-button row for settings and pickers. Not a `RadioListTile`: its `RadioGroup` takes the arrow keys (each
/// press selects the next radio and wraps around), so the TV remote could never leave the list (docs/ui.md).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({super.key, required this.title, this.subtitle, required this.selected, required this.onTap});

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.yt;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: ListTile(
        leading: Icon(
          selected ? Symbols.radio_button_checked : Symbols.radio_button_unchecked,
          color: selected ? c.link : c.textSecondary,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        onTap: onTap,
      ),
    );
  }
}

/// A focus ring for the TV remote and keyboards (docs/ui.md): a rounded border drawn over [child] while it, or a
/// widget inside it, has focus. Hidden while the screen is being touched, so phones never show it.
class FocusHighlight extends StatefulWidget {
  const FocusHighlight({super.key, required this.child, this.radius = 12});

  final Widget child;
  final double radius;

  @override
  State<FocusHighlight> createState() => _FocusHighlightState();
}

class _FocusHighlightState extends State<FocusHighlight> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    super.dispose();
  }

  void _modeChanged(FocusHighlightMode _) {
    if (_focused && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final show = _focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: CustomPaint(
        foregroundPainter: _RingPainter(show: show, color: context.yt.textPrimary, radius: widget.radius),
        child: widget.child,
      ),
    );
  }
}

/// The focus ring, drawn just outside the widget with a small gap, so it shows on any colour (a white chip too).
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.show, required this.color, required this.radius});

  final bool show;
  final Color color;
  final double radius;

  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final rect = (Offset.zero & size).inflate(_gap);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius + _gap)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.show != show || old.color != color || old.radius != radius;
}

class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({super.key, required this.onLoadMore, required this.child, this.threshold = 1200});

  final VoidCallback onLoadMore;
  final Widget child;
  final double threshold;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: (n) {
      if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < threshold) onLoadMore();
      return false;
    },
    child: child,
  );
}

void showSnack(BuildContext context, String message, {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      // Close after [duration] even with an action (Flutter keeps a toast with an action up until it's tapped).
      persist: false,
      action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ),
  );
}
