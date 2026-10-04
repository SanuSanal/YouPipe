import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../innertube/models.dart';

part 'app_database.g.dart';

/// Video metadata cache, so library views render offline.
class Videos extends Table {
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get channelName => text().nullable()();
  TextColumn get channelId => text().nullable()();
  TextColumn get channelAvatar => text().nullable()();
  TextColumn get thumbnail => text().nullable()();
  TextColumn get durationText => text().nullable()();
  TextColumn get viewsText => text().nullable()();
  TextColumn get publishedText => text().nullable()();
  BoolColumn get isShort => boolean().withDefault(const Constant(false))();
  BoolColumn get isLive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {videoId};
}

/// One row per video (like YouTube's history), with where playback stopped for "resume".
class WatchHistory extends Table {
  TextColumn get videoId => text().references(Videos, #videoId)();
  DateTimeColumn get watchedAt => dateTime()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {videoId};
}

class LikedVideos extends Table {
  TextColumn get videoId => text().references(Videos, #videoId)();
  DateTimeColumn get likedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {videoId};
}

/// Channels subscribed to on this device (no account needed). Their uploads come from RSS (docs/data.md).
class Subscriptions extends Table {
  TextColumn get channelId => text()();
  TextColumn get name => text()();
  TextColumn get avatar => text().nullable()();
  DateTimeColumn get subscribedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId};
}

/// Recent uploads of subscribed channels, from their RSS feeds.
@DataClassName('FeedVideoRow')
class FeedVideos extends Table {
  TextColumn get videoId => text()();
  TextColumn get channelId => text()();
  TextColumn get channelName => text()();
  TextColumn get title => text()();
  DateTimeColumn get publishedAt => dateTime()();
  TextColumn get thumbnail => text().nullable()();
  IntColumn get views => integer().nullable()();
  BoolColumn get isShort => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {videoId};
}

/// Playlists made in YouPipe. Watch later is one of them ([isWatchLater]).
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isWatchLater => boolean().withDefault(const Constant(false))();
}

@DataClassName('PlaylistEntryRow')
class PlaylistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get videoId => text().references(Videos, #videoId)();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();
}

/// YouTube playlists saved to the library.
class SavedPlaylists extends Table {
  TextColumn get playlistId => text()();
  TextColumn get title => text()();
  TextColumn get owner => text().nullable()();
  TextColumn get thumbnail => text().nullable()();
  TextColumn get countText => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId};
}

enum DownloadState { queued, downloading, done, failed }

/// Videos saved for offline viewing (docs/downloads.md). Metadata comes from `Videos`.
class Downloads extends Table {
  TextColumn get videoId => text().references(Videos, #videoId)();
  IntColumn get state => intEnum<DownloadState>()();

  /// The quality asked for; after downloading, the one actually saved.
  IntColumn get height => integer()();
  TextColumn get path => text().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {videoId};
}

class SearchHistory extends Table {
  TextColumn get query => text()();
  DateTimeColumn get searchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {query};
}

@DriftDatabase(
  tables: [
    Videos,
    WatchHistory,
    LikedVideos,
    Subscriptions,
    FeedVideos,
    Playlists,
    PlaylistItems,
    SavedPlaylists,
    SearchHistory,
    Downloads,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'youpipe'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(downloads);
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

// Conversions between rows and InnerTube models -------------------------------------------------------------

VideosCompanion videoToCompanion(VideoItem v) => VideosCompanion.insert(
  videoId: v.id,
  title: v.title,
  channelName: Value(v.channelName),
  channelId: Value(v.channelId),
  channelAvatar: Value(v.channelAvatar),
  thumbnail: Value(v.thumbnail),
  durationText: Value(v.durationText),
  viewsText: Value(v.viewsText),
  publishedText: Value(v.publishedText),
  isShort: Value(v.isShort),
  isLive: Value(v.isLive),
);

VideoItem videoFromRow(Video r) => VideoItem(
  id: r.videoId,
  title: r.title,
  channelName: r.channelName,
  channelId: r.channelId,
  channelAvatar: r.channelAvatar,
  thumbnail: r.thumbnail,
  durationText: r.durationText,
  viewsText: r.viewsText,
  publishedText: r.publishedText,
  isShort: r.isShort,
  isLive: r.isLive,
);
