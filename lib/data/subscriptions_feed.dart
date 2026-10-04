import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../innertube/models.dart';
import '../util/format.dart';
import 'db/app_database.dart';

/// A subscription upload, from the channel's RSS feed.
class FeedVideo {
  const FeedVideo(this.video, this.publishedAt, this.views);

  final VideoItem video;
  final DateTime publishedAt;
  final int? views;
}

/// The Subscriptions feed without an account (docs/data.md): every subscribed channel's
/// `feeds/videos.xml?channel_id=` (its 15 latest uploads), cached in `FeedVideos`.
class SubscriptionsFeed {
  SubscriptionsFeed(this.db, {Dio? dio}) : _dio = dio ?? Dio(BaseOptions(receiveTimeout: const Duration(seconds: 20)));

  final AppDatabase db;
  final Dio _dio;

  /// Refreshes run at most this often unless forced.
  static const minInterval = Duration(minutes: 30);
  DateTime? _lastRefresh;
  Future<void>? _running;

  final refreshing = ValueNotifier(false);

  Future<void> refresh({bool force = false}) {
    if (!force && _lastRefresh != null && DateTime.now().difference(_lastRefresh!) < minInterval) {
      return Future.value();
    }
    return _running ??= _refresh().whenComplete(() {
      _running = null;
    });
  }

  Future<void> _refresh() async {
    refreshing.value = true;
    try {
      final subs = await db.select(db.subscriptions).get();
      // Six channels at a time: quick, without hammering YouTube.
      var next = 0;
      Future<void> worker() async {
        while (next < subs.length) {
          final s = subs[next++];
          try {
            await _fetch(s.channelId, s.name);
          } catch (e) {
            debugPrint('YouPipe: RSS ${s.channelId} failed: $e');
          }
        }
      }

      await Future.wait([for (var i = 0; i < 6; i++) worker()]);
      // Keep only the last 60 days.
      await (db.delete(
        db.feedVideos,
      )..where((f) => f.publishedAt.isSmallerThanValue(DateTime.now().subtract(const Duration(days: 60))))).go();
      _lastRefresh = DateTime.now();
    } finally {
      refreshing.value = false;
    }
  }

  Future<void> _fetch(String channelId, String channelName) async {
    final res = await _dio.get<String>(
      'https://www.youtube.com/feeds/videos.xml',
      queryParameters: {'channel_id': channelId},
      options: Options(responseType: ResponseType.plain),
    );
    final entries = parseRss(res.data ?? '', channelId: channelId, channelName: channelName);
    await db.batch((b) {
      for (final e in entries) {
        b.insert(db.feedVideos, e, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// The feed, newest first, with the channel avatars from `Subscriptions`.
  Stream<List<FeedVideo>> watch({int limit = 300}) {
    final q =
        db.select(db.feedVideos).join([
            innerJoin(db.subscriptions, db.subscriptions.channelId.equalsExp(db.feedVideos.channelId)),
          ])
          ..orderBy([OrderingTerm.desc(db.feedVideos.publishedAt)])
          ..limit(limit);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          () {
            final f = r.readTable(db.feedVideos);
            final s = r.readTable(db.subscriptions);
            return FeedVideo(
              VideoItem(
                id: f.videoId,
                title: f.title,
                channelName: s.name,
                channelId: f.channelId,
                channelAvatar: s.avatar,
                thumbnail: f.thumbnail,
                viewsText: f.views == null ? null : viewsLabel(f.views!),
                publishedText: timeAgo(f.publishedAt),
                isShort: f.isShort,
              ),
              f.publishedAt,
              f.views,
            );
          }(),
      ],
    );
  }
}

/// Parses a channel's Atom feed into `FeedVideos` rows.
List<FeedVideosCompanion> parseRss(String xml, {required String channelId, required String channelName}) {
  final doc = XmlDocument.parse(xml);
  return [
    for (final e in doc.findAllElements('entry'))
      if (e.getElement('yt:videoId')?.innerText case final id?)
        FeedVideosCompanion.insert(
          videoId: id,
          channelId: channelId,
          channelName: e.getElement('author')?.getElement('name')?.innerText ?? channelName,
          title: e.getElement('title')?.innerText ?? '',
          publishedAt: DateTime.tryParse(e.getElement('published')?.innerText ?? '') ?? DateTime.now(),
          thumbnail: Value(
            e.getElement('media:group')?.getElement('media:thumbnail')?.getAttribute('url') ??
                'https://i.ytimg.com/vi/$id/hqdefault.jpg',
          ),
          views: Value(
            int.tryParse(
              e
                      .getElement('media:group')
                      ?.getElement('media:community')
                      ?.getElement('media:statistics')
                      ?.getAttribute('views') ??
                  '',
            ),
          ),
          isShort: Value(e.getElement('link')?.getAttribute('href')?.contains('/shorts/') ?? false),
        ),
  ];
}
