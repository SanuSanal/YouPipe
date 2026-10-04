import 'dart:async';

import 'package:flutter/foundation.dart';

import '../innertube/innertube.dart';
import 'library_repository.dart';
import 'subscriptions_feed.dart';

/// A Home chip. YouTube's own chips are personalised server-side, which signed-out YouTube no longer does, so
/// YouPipe's are topic searches (docs/phase0.md).
@immutable
class HomeChip {
  const HomeChip(this.label, {this.query, this.params, this.kind = HomeChipKind.search});

  final String label;
  final String? query;
  final String? params;
  final HomeChipKind kind;

  static const all = HomeChip('All', kind: HomeChipKind.all);

  static final defaults = [
    all,
    const HomeChip('Music', query: 'music'),
    const HomeChip('Gaming', query: 'gaming'),
    HomeChip('Live', query: 'live', params: SearchFilter.live.params),
    const HomeChip('News', query: 'news today'),
    const HomeChip('Podcasts', query: 'podcast'),
    const HomeChip('Sports', query: 'sports highlights'),
    const HomeChip('Comedy', query: 'comedy'),
    const HomeChip('Cooking', query: 'cooking recipes'),
    const HomeChip('Science', query: 'science'),
    const HomeChip('Recently uploaded', kind: HomeChipKind.subscriptions),
  ];

  @override
  bool operator ==(Object other) => other is HomeChip && other.label == label;

  @override
  int get hashCode => label.hashCode;
}

enum HomeChipKind { all, search, subscriptions }

/// Where Home items come from. Each source pages on its own; [HomeMixer] interleaves them.
abstract class _Source {
  _Source(this.weight);

  /// Items taken from this source per round.
  final int weight;
  bool done = false;
  final _buffer = <VideoItem>[];
  Future<void>? _loading;

  Future<List<VideoItem>> fetch();

  Future<void> ensure() async {
    if (_buffer.isNotEmpty || done) return;
    final load = _loading ??= () async {
      try {
        final items = await fetch();
        if (items.isEmpty) done = true;
        _buffer.addAll(items);
      } catch (e) {
        debugPrint('YouPipe: home source failed: $e');
        done = true;
      }
    }();
    await load;
    _loading = null;
  }
}

List<VideoItem> _videosOnly(Iterable<YtItem> items) => [
  for (final i in items)
    if (i is VideoItem && !i.isShort) i,
];

class _RelatedSource extends _Source {
  _RelatedSource(this.yt, this.seed) : super(2);

  final InnerTube yt;
  final String seed;
  bool _started = false;
  String? _token;

  @override
  Future<List<VideoItem>> fetch() async {
    final Paged<YtItem> page;
    if (!_started) {
      _started = true;
      page = await yt.related(seed);
    } else if (_token != null) {
      page = await yt.nextContinuation(_token!);
    } else {
      return const [];
    }
    _token = page.continuation;
    return _videosOnly(page.items);
  }
}

class _SearchSource extends _Source {
  _SearchSource(this.yt, this.query, {this.params, int weight = 1}) : super(weight);

  final InnerTube yt;
  final String query;
  final String? params;
  bool _started = false;
  String? _token;

  @override
  Future<List<VideoItem>> fetch() async {
    final SearchPage page;
    if (!_started) {
      _started = true;
      page = await yt.search(query, params: params);
    } else if (_token != null) {
      page = await yt.searchContinuation(_token!);
    } else {
      return const [];
    }
    _token = page.continuation;
    return _videosOnly(page.entries.allItems);
  }
}

/// The signed-in account's own Home (YouTube's recommendations), with continuations.
class _AccountHomeSource extends _Source {
  _AccountHomeSource(this.yt) : super(3);

  final InnerTube yt;
  bool _started = false;
  String? _token;

  @override
  Future<List<VideoItem>> fetch() async {
    final Paged<YtItem> page;
    if (!_started) {
      _started = true;
      page = await yt.home();
    } else if (_token != null) {
      final more = await yt.browseContinuation(_token!);
      page = Paged(more.entries.allItems.toList(), more.continuation);
    } else {
      return const [];
    }
    _token = page.continuation;
    return _videosOnly(page.items);
  }
}

class _ListSource extends _Source {
  _ListSource(this.items) : super(2);

  final List<VideoItem> items;
  bool _given = false;

  @override
  Future<List<VideoItem>> fetch() async {
    if (_given) return const [];
    _given = true;
    return items;
  }
}

/// Builds the signed-out Home: related videos of recent history, unwatched subscription uploads, and topic searches
/// when there's nothing personal yet (docs/data.md).
class HomeMixer {
  HomeMixer._(this._sources, this._exclude);

  final List<_Source> _sources;
  final Set<String> _exclude;
  final _seen = <String>{};

  static const _discover = ['music', 'news today', 'gaming', 'comedy', 'science', 'sports highlights'];

  static Future<HomeMixer> create({
    required HomeChip chip,
    required InnerTube yt,
    required LibraryRepository library,
    required List<FeedVideo> subscriptionFeed,
  }) async {
    final history = await library.watchHistory(limit: 200).first;
    // Finished videos don't come back; half-watched ones may.
    final finished = {
      for (final h in history)
        if (h.progress > 0.9) h.video.id,
    };
    final recentUploads = [
      for (final f in subscriptionFeed)
        if (!f.video.isShort && DateTime.now().difference(f.publishedAt).inDays <= 14 && !finished.contains(f.video.id))
          f.video,
    ];
    final sources = <_Source>[];
    switch (chip.kind) {
      case HomeChipKind.search:
        sources.add(_SearchSource(yt, chip.query!, params: chip.params, weight: 3));
      case HomeChipKind.subscriptions:
        sources.add(_ListSource(recentUploads));
      case HomeChipKind.all:
        if (yt.signedIn) sources.add(_AccountHomeSource(yt));
        final seeds = [
          for (final h in history)
            if (!h.video.isShort) h.video.id,
        ].take(6);
        sources.addAll([for (final s in seeds) _RelatedSource(yt, s)]);
        if (recentUploads.isNotEmpty) sources.insert(sources.isEmpty ? 0 : 1, _ListSource(recentUploads));
        // Something to discover even with history; the whole feed when there's nothing personal yet.
        final personal = sources.isNotEmpty;
        final topics = [..._discover]..shuffle();
        for (final q in topics.take(personal ? 1 : 4)) {
          sources.add(_SearchSource(yt, q, weight: personal ? 1 : 2));
        }
    }
    final mixer = HomeMixer._(sources, finished);
    // Start every source at once so the first page arrives as fast as the slowest single request.
    await Future.wait(sources.map((s) => s.ensure()));
    return mixer;
  }

  bool get hasMore => _sources.any((s) => !s.done || s._buffer.isNotEmpty);

  /// The next [count] items, round-robin by weight across sources, without repeats.
  Future<List<VideoItem>> next(int count) async {
    final out = <VideoItem>[];
    var stalled = 0;
    while (out.length < count && hasMore && stalled < 3) {
      final before = out.length;
      for (final s in _sources) {
        await s.ensure();
        var taken = 0;
        while (taken < s.weight && s._buffer.isNotEmpty) {
          final v = s._buffer.removeAt(0);
          if (_exclude.contains(v.id) || !_seen.add(v.id)) continue;
          out.add(v);
          taken++;
        }
        if (out.length >= count) break;
      }
      stalled = out.length == before ? stalled + 1 : 0;
    }
    return out;
  }
}
