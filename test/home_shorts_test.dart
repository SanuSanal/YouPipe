import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/data/home_feed.dart';
import 'package:youpipe/data/library_repository.dart';
import 'package:youpipe/data/subscriptions_feed.dart';
import 'package:youpipe/innertube/models.dart';

void main() {
  HistoryEntry watched(String id, String channel) =>
      HistoryEntry(VideoItem(id: id, title: 't', channelName: channel), DateTime(2026), Duration.zero, Duration.zero);
  FeedVideo upload(String id, String channel) =>
      FeedVideo(VideoItem(id: id, title: 't', channelName: channel), DateTime(2026), null);

  test('a topic chip searches its own query', () {
    const chip = HomeChip('Gaming', query: 'gaming');
    expect(homeShortsQueries(chip: chip, history: const [], subscriptionFeed: const []), ['gaming']);
  });

  test('"All" with nothing personal picks three different topics', () {
    final q = homeShortsQueries(chip: HomeChip.all, history: const [], subscriptionFeed: const []);
    expect(q, hasLength(3));
    expect(q.toSet(), hasLength(3));
    expect(discoverTopics, containsAll(q));
  });

  test('"All" mixes two watched or followed channels with one topic', () {
    final q = homeShortsQueries(
      chip: HomeChip.all,
      history: [watched('a', 'Chan A'), watched('b', 'Chan A'), watched('c', '  ')],
      subscriptionFeed: [upload('d', 'Chan B')],
    );
    expect(q.take(2).toSet(), {'Chan A', 'Chan B'});
    expect(discoverTopics, contains(q.last));
  });

  test('"All" varies from one load to the next', () {
    final history = [for (var i = 0; i < 10; i++) watched('v$i', 'Chan $i')];
    final sets = {
      for (var seed = 0; seed < 10; seed++)
        homeShortsQueries(
          chip: HomeChip.all,
          history: history,
          subscriptionFeed: const [],
          random: Random(seed),
        ).join('|'),
    };
    expect(sets.length, greaterThan(1));
  });
}
