/// Helpers for walking InnerTube's deeply nested renderer JSON without a wall of null checks.
library;

typedef Json = Map<String, dynamic>;

/// Follows [path] through nested maps/lists. String segments index maps, int segments index lists.
/// Returns null as soon as any segment is missing or of the wrong type.
T? nav<T>(Object? root, List<Object> path) {
  Object? cur = root;
  for (final seg in path) {
    if (seg is String && cur is Map) {
      cur = cur[seg];
    } else if (seg is int && cur is List && seg >= 0 && seg < cur.length) {
      cur = cur[seg];
    } else {
      return null;
    }
  }
  return cur is T ? cur : null;
}

List<Json> navList(Object? root, List<Object> path) => nav<List>(root, path)?.whereType<Json>().toList() ?? const [];

/// Joins the `text` of every run in `{runs: [...]}` or returns `simpleText`.
String? textOf(Object? textObject) {
  if (textObject is! Map) return null;
  final simple = textObject['simpleText'];
  if (simple is String) return simple;
  final runs = textObject['runs'];
  if (runs is! List) return null;
  return runs.map((r) => r is Map ? (r['text'] ?? '') : '').join();
}

List<Json> runsOf(Object? textObject) => navList(textObject, ['runs']);

/// Parses "3:49" / "1:02:03" into a Duration.
Duration? parseDuration(String? text) {
  if (text == null) return null;
  final parts = text.trim().split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  var seconds = 0;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null) return null;
    seconds = seconds * 60 + n;
  }
  return Duration(seconds: seconds);
}
