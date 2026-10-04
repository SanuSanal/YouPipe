/// Number, duration and date formatting the way YouTube shows them.
library;

/// "1.2M", "34K", "999". YouTube rounds down: 1,290,000 is "1.2M".
String compactCount(int n) {
  String fmt(double v, String unit) {
    if (v >= 10) return '${v.floor()}$unit';
    final one = (v * 10).floor() / 10;
    return '${one == one.roundToDouble() ? one.toInt() : one}$unit';
  }

  if (n >= 1000000000) return fmt(n / 1000000000, 'B');
  if (n >= 1000000) return fmt(n / 1000000, 'M');
  if (n >= 1000) return fmt(n / 1000, 'K');
  return '$n';
}

/// "1.2M views", "1 view", "No views".
String viewsLabel(int n) => n < 0
    ? ''
    : n == 0
    ? 'No views'
    : n == 1
    ? '1 view'
    : '${compactCount(n)} views';

/// "3 hours ago", like YouTube.
String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  String unit(int n, String u) => '$n $u${n == 1 ? '' : 's'} ago';
  if (d.inDays >= 365) return unit(d.inDays ~/ 365, 'year');
  if (d.inDays >= 30) return unit(d.inDays ~/ 30, 'month');
  if (d.inDays >= 7) return unit(d.inDays ~/ 7, 'week');
  if (d.inDays >= 1) return unit(d.inDays, 'day');
  if (d.inHours >= 1) return unit(d.inHours, 'hour');
  if (d.inMinutes >= 1) return unit(d.inMinutes, 'minute');
  return 'Just now';
}

/// NewPipe's upload date ("2026-10-03T05:30:31-07:00") as "3 hours ago"; other text is returned as-is.
String? relativeDate(String? text) {
  if (text == null || text.isEmpty) return null;
  final t = DateTime.tryParse(text);
  return t == null ? text : timeAgo(t.toLocal());
}

/// "3:07", "1:02:03".
String formatDuration(Duration d) {
  final neg = d.isNegative;
  d = d.abs();
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${neg ? '-' : ''}${h > 0 ? '$h:$m:$s' : '$m:$s'}';
}
