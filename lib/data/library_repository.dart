import 'package:drift/drift.dart';

import '../innertube/models.dart';
import 'db/app_database.dart';

/// A history row: the video, when it was last watched, and where it stopped.
class HistoryEntry {
  const HistoryEntry(this.video, this.watchedAt, this.position, this.duration);

  final VideoItem video;
  final DateTime watchedAt;
  final Duration position;
  final Duration duration;

  /// 0..1 for the red "watched" bar under thumbnails.
  double get progress =>
      duration.inMilliseconds <= 0 ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
}

class LocalPlaylistSummary {
  const LocalPlaylistSummary(this.playlist, this.count, this.thumbnail);

  final Playlist playlist;
  final int count;
  final String? thumbnail;
}

/// The on-device library (docs/data.md): history, likes, Watch later, playlists, subscriptions, searches.
class LibraryRepository {
  LibraryRepository(this.db);

  final AppDatabase db;

  /// Mirrors likes, subscriptions and Watch later to the signed-in account (set by the account feature).
  /// Best-effort: the local library stays the source of truth.
  void Function(String action, String id, bool on)? remoteSync;

  Future<void> _upsertVideo(VideoItem v) => db.into(db.videos).insertOnConflictUpdate(videoToCompanion(v));

  // History ------------------------------------------------------------------------------------------------

  Future<void> recordWatch(VideoItem video, {Duration? position, Duration? duration}) async {
    await _upsertVideo(video);
    await db
        .into(db.watchHistory)
        .insert(
          WatchHistoryCompanion.insert(
            videoId: video.id,
            watchedAt: DateTime.now(),
            positionMs: Value(position?.inMilliseconds ?? 0),
            durationMs: Value(duration?.inMilliseconds ?? 0),
          ),
          onConflict: DoUpdate(
            (old) => WatchHistoryCompanion(
              watchedAt: Value(DateTime.now()),
              positionMs: position == null ? const Value.absent() : Value(position.inMilliseconds),
              durationMs: duration == null ? const Value.absent() : Value(duration.inMilliseconds),
            ),
          ),
        );
  }

  Future<void> savePosition(String videoId, Duration position, Duration duration) =>
      (db.update(db.watchHistory)..where((h) => h.videoId.equals(videoId))).write(
        WatchHistoryCompanion(positionMs: Value(position.inMilliseconds), durationMs: Value(duration.inMilliseconds)),
      );

  /// Where to resume [videoId]: null when it was barely started or nearly finished.
  Future<Duration?> resumePosition(String videoId) async {
    final row = await (db.select(db.watchHistory)..where((h) => h.videoId.equals(videoId))).getSingleOrNull();
    if (row == null || row.durationMs <= 0) return null;
    final p = row.positionMs;
    if (p < 15000 || p > row.durationMs * 0.95 || row.durationMs - p < 10000) return null;
    return Duration(milliseconds: p);
  }

  Stream<List<HistoryEntry>> watchHistory({int? limit}) {
    final q = db.select(db.watchHistory).join([
      innerJoin(db.videos, db.videos.videoId.equalsExp(db.watchHistory.videoId)),
    ])..orderBy([OrderingTerm.desc(db.watchHistory.watchedAt)]);
    if (limit != null) q.limit(limit);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          HistoryEntry(
            videoFromRow(r.readTable(db.videos)),
            r.readTable(db.watchHistory).watchedAt,
            Duration(milliseconds: r.readTable(db.watchHistory).positionMs),
            Duration(milliseconds: r.readTable(db.watchHistory).durationMs),
          ),
      ],
    );
  }

  /// Watch progress by video id (for the red bars under thumbnails everywhere).
  Stream<Map<String, double>> watchProgress() => db
      .select(db.watchHistory)
      .watch()
      .map(
        (rows) => {
          for (final r in rows)
            if (r.durationMs > 0) r.videoId: (r.positionMs / r.durationMs).clamp(0.0, 1.0),
        },
      );

  Future<List<String>> recentlyWatchedIds(int limit) async {
    final rows =
        await (db.select(db.watchHistory)
              ..orderBy([(h) => OrderingTerm.desc(h.watchedAt)])
              ..limit(limit))
            .get();
    return [for (final r in rows) r.videoId];
  }

  Future<void> removeFromHistory(String videoId) =>
      (db.delete(db.watchHistory)..where((h) => h.videoId.equals(videoId))).go();

  Future<void> clearHistory() => db.delete(db.watchHistory).go();

  // Likes --------------------------------------------------------------------------------------------------

  Future<void> setLiked(VideoItem video, bool liked) async {
    remoteSync?.call('like', video.id, liked);
    if (liked) {
      await _upsertVideo(video);
      await db
          .into(db.likedVideos)
          .insertOnConflictUpdate(LikedVideosCompanion.insert(videoId: video.id, likedAt: DateTime.now()));
    } else {
      await (db.delete(db.likedVideos)..where((l) => l.videoId.equals(video.id))).go();
    }
  }

  Stream<bool> watchIsLiked(String videoId) =>
      (db.select(db.likedVideos)..where((l) => l.videoId.equals(videoId))).watch().map((rows) => rows.isNotEmpty);

  Stream<List<VideoItem>> likedVideos() {
    final q = db.select(db.likedVideos).join([
      innerJoin(db.videos, db.videos.videoId.equalsExp(db.likedVideos.videoId)),
    ])..orderBy([OrderingTerm.desc(db.likedVideos.likedAt)]);
    return q.watch().map((rows) => [for (final r in rows) videoFromRow(r.readTable(db.videos))]);
  }

  // Playlists, Watch later ---------------------------------------------------------------------------------

  Future<int> watchLaterId() async {
    final existing = await (db.select(db.playlists)..where((p) => p.isWatchLater.equals(true))).getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'Watch later', createdAt: DateTime.now(), isWatchLater: const Value(true)),
        );
  }

  Future<int> createPlaylist(String name) =>
      db.into(db.playlists).insert(PlaylistsCompanion.insert(name: name, createdAt: DateTime.now()));

  Future<void> renamePlaylist(int id, String name) =>
      (db.update(db.playlists)..where((p) => p.id.equals(id))).write(PlaylistsCompanion(name: Value(name)));

  Future<void> deletePlaylist(int id) => (db.delete(db.playlists)..where((p) => p.id.equals(id))).go();

  Future<void> addToPlaylist(int playlistId, VideoItem video) async {
    await _upsertVideo(video);
    final exists = await (db.select(
      db.playlistItems,
    )..where((i) => i.playlistId.equals(playlistId) & i.videoId.equals(video.id))).getSingleOrNull();
    if (exists != null) return;
    final max = db.playlistItems.position.max();
    final last =
        await (db.selectOnly(db.playlistItems)
              ..addColumns([max])
              ..where(db.playlistItems.playlistId.equals(playlistId)))
            .map((r) => r.read(max))
            .getSingle();
    await db
        .into(db.playlistItems)
        .insert(
          PlaylistItemsCompanion.insert(
            playlistId: playlistId,
            videoId: video.id,
            position: (last ?? -1) + 1,
            addedAt: DateTime.now(),
          ),
        );
  }

  Future<void> removeFromPlaylist(int playlistId, String videoId) =>
      (db.delete(db.playlistItems)..where((i) => i.playlistId.equals(playlistId) & i.videoId.equals(videoId))).go();

  /// Moves the item at [from] to [to] (indexes in the current order).
  Future<void> movePlaylistItem(int playlistId, int from, int to) => db.transaction(() async {
    final items =
        await (db.select(db.playlistItems)
              ..where((i) => i.playlistId.equals(playlistId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    final moved = items.removeAt(from);
    items.insert(to, moved);
    for (final (i, item) in items.indexed) {
      await (db.update(
        db.playlistItems,
      )..where((r) => r.id.equals(item.id))).write(PlaylistItemsCompanion(position: Value(i)));
    }
  });

  Future<void> toggleWatchLater(VideoItem video) async {
    final id = await watchLaterId();
    final inList = await (db.select(
      db.playlistItems,
    )..where((i) => i.playlistId.equals(id) & i.videoId.equals(video.id))).getSingleOrNull();
    remoteSync?.call('watchLater', video.id, inList == null);
    inList == null ? await addToPlaylist(id, video) : await removeFromPlaylist(id, video.id);
  }

  Stream<Set<int>> playlistsContaining(String videoId) => (db.select(
    db.playlistItems,
  )..where((i) => i.videoId.equals(videoId))).watch().map((rows) => {for (final r in rows) r.playlistId});

  Stream<List<VideoItem>> playlistVideos(int playlistId) {
    final q =
        db.select(db.playlistItems).join([innerJoin(db.videos, db.videos.videoId.equalsExp(db.playlistItems.videoId))])
          ..where(db.playlistItems.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(db.playlistItems.position)]);
    return q.watch().map((rows) => [for (final r in rows) videoFromRow(r.readTable(db.videos))]);
  }

  Stream<Playlist?> watchPlaylist(int id) =>
      (db.select(db.playlists)..where((p) => p.id.equals(id))).watchSingleOrNull();

  /// All local playlists, Watch later first, with item counts and the first video's thumbnail.
  Stream<List<LocalPlaylistSummary>> localPlaylists() {
    final count = db.playlistItems.id.count();
    final q =
        db.select(db.playlists).join([
            leftOuterJoin(db.playlistItems, db.playlistItems.playlistId.equalsExp(db.playlists.id)),
          ])
          ..addColumns([count])
          ..groupBy([db.playlists.id])
          ..orderBy([OrderingTerm.desc(db.playlists.isWatchLater), OrderingTerm.desc(db.playlists.createdAt)]);
    return q.watch().asyncMap((rows) async {
      final out = <LocalPlaylistSummary>[];
      for (final r in rows) {
        final p = r.readTable(db.playlists);
        final first =
            await (db.select(db.playlistItems).join([
                    innerJoin(db.videos, db.videos.videoId.equalsExp(db.playlistItems.videoId)),
                  ])
                  ..where(db.playlistItems.playlistId.equals(p.id))
                  ..orderBy([OrderingTerm.asc(db.playlistItems.position)])
                  ..limit(1))
                .getSingleOrNull();
        out.add(LocalPlaylistSummary(p, r.read(count) ?? 0, first?.readTable(db.videos).thumbnail));
      }
      return out;
    });
  }

  // Saved YouTube playlists --------------------------------------------------------------------------------

  Future<void> setPlaylistSaved(PlaylistItem p, bool saved) async {
    if (saved) {
      await db
          .into(db.savedPlaylists)
          .insertOnConflictUpdate(
            SavedPlaylistsCompanion.insert(
              playlistId: p.id,
              title: p.title,
              owner: Value(p.channelName),
              thumbnail: Value(p.thumbnail),
              countText: Value(p.countText),
              savedAt: DateTime.now(),
            ),
          );
    } else {
      await (db.delete(db.savedPlaylists)..where((s) => s.playlistId.equals(p.id))).go();
    }
  }

  Stream<bool> watchIsPlaylistSaved(String id) =>
      (db.select(db.savedPlaylists)..where((s) => s.playlistId.equals(id))).watch().map((r) => r.isNotEmpty);

  Stream<List<PlaylistItem>> savedPlaylists() =>
      (db.select(db.savedPlaylists)..orderBy([(s) => OrderingTerm.desc(s.savedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            PlaylistItem(
              id: r.playlistId,
              title: r.title,
              thumbnail: r.thumbnail,
              channelName: r.owner,
              countText: r.countText,
            ),
        ],
      );

  // Subscriptions ------------------------------------------------------------------------------------------

  Future<void> setSubscribed(ChannelItem channel, bool subscribed) async {
    remoteSync?.call('subscribe', channel.id, subscribed);
    if (subscribed) {
      await db
          .into(db.subscriptions)
          .insertOnConflictUpdate(
            SubscriptionsCompanion.insert(
              channelId: channel.id,
              name: channel.name,
              avatar: Value(channel.avatar),
              subscribedAt: DateTime.now(),
            ),
          );
    } else {
      await (db.delete(db.subscriptions)..where((s) => s.channelId.equals(channel.id))).go();
      await (db.delete(db.feedVideos)..where((f) => f.channelId.equals(channel.id))).go();
    }
  }

  /// Adds many at once (imports); existing ones keep their date.
  Future<int> importSubscriptions(List<ChannelItem> channels) async {
    var added = 0;
    await db.batch((b) {
      for (final c in channels) {
        b.insert(
          db.subscriptions,
          SubscriptionsCompanion.insert(
            channelId: c.id,
            name: c.name,
            avatar: Value(c.avatar),
            subscribedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        added++;
      }
    });
    return added;
  }

  Stream<bool> watchIsSubscribed(String channelId) =>
      (db.select(db.subscriptions)..where((s) => s.channelId.equals(channelId))).watch().map((r) => r.isNotEmpty);

  Stream<List<ChannelItem>> subscriptions() =>
      (db.select(db.subscriptions)..orderBy([(s) => OrderingTerm.asc(s.name.lower())])).watch().map(
        (rows) => [for (final r in rows) ChannelItem(id: r.channelId, name: r.name, avatar: r.avatar)],
      );

  Future<List<ChannelItem>> subscriptionsOnce() async => [
    for (final r in await db.select(db.subscriptions).get())
      ChannelItem(id: r.channelId, name: r.name, avatar: r.avatar),
  ];

  /// Updates a subscription's avatar/name when a fresher one is seen (channel page, video info).
  Future<void> refreshSubscription(ChannelItem c) =>
      (db.update(db.subscriptions)..where((s) => s.channelId.equals(c.id))).write(
        SubscriptionsCompanion(name: Value(c.name), avatar: c.avatar == null ? const Value.absent() : Value(c.avatar)),
      );

  // Search history -----------------------------------------------------------------------------------------

  Future<void> addSearch(String query) => db
      .into(db.searchHistory)
      .insertOnConflictUpdate(SearchHistoryCompanion.insert(query: query.trim(), searchedAt: DateTime.now()));

  Future<void> removeSearch(String query) => (db.delete(db.searchHistory)..where((s) => s.query.equals(query))).go();

  Future<void> clearSearches() => db.delete(db.searchHistory).go();

  Stream<List<String>> searches({int limit = 20}) =>
      (db.select(db.searchHistory)
            ..orderBy([(s) => OrderingTerm.desc(s.searchedAt)])
            ..limit(limit))
          .watch()
          .map((rows) => [for (final r in rows) r.query]);
}
