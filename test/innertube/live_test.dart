@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/innertube/innertube.dart';

/// Smoke test against the real InnerTube API. Run when YouTube changes something:
///   flutter test --tags live --run-skipped
void main() {
  final yt = InnerTube();

  setUpAll(() => yt.ensureVisitorData());

  test('signed-out home answers (empty, with a nudge, in the EU)', () async {
    final home = await yt.home();
    expect(home.items.isNotEmpty || home.nudge != null, isTrue);
  });

  test('search + filter + continuation + suggestions', () async {
    final all = await yt.search('lofi hip hop');
    expect(all.entries.allItems.whereType<VideoItem>(), isNotEmpty);
    expect(all.filters, isNotEmpty);
    final more = await yt.searchContinuation(all.continuation!);
    expect(more.entries, isNotEmpty);
    final channels = await yt.search('rick astley', params: SearchFilter.channels.params);
    expect(channels.entries.allItems.whereType<ChannelItem>(), isNotEmpty);
    expect(await yt.suggestions('lofi'), isNotEmpty);
  });

  test('related + continuation', () async {
    final related = await yt.related('dQw4w9WgXcQ');
    expect(related.items.whereType<VideoItem>().length, greaterThan(5));
    final more = await yt.nextContinuation(related.continuation!);
    expect(more.items, isNotEmpty);
  });

  test('channel + Videos tab + continuation', () async {
    final home = await yt.channel('UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(home.name, isNotEmpty);
    final videosTab = home.tabs.firstWhere((t) => t.title == 'Videos');
    final videos = await yt.channel(home.id, params: videosTab.params);
    expect(videos.content.entries.allItems.whereType<VideoItem>(), isNotEmpty);
    expect(videos.content.continuation, isNotNull);
    final more = await yt.browseContinuation(videos.content.continuation!);
    expect(more.entries, isNotEmpty);
    final popular = await yt.browseContinuation(videos.sortChips.firstWhere((c) => c.label == 'Popular').token!);
    expect(popular.entries.allItems.whereType<VideoItem>(), isNotEmpty);
  });

  test('playlist + continuation', () async {
    final page = await yt.playlist('PLFgquLnL59alCl_2TQvOiD5Vgm1hCaGSI');
    expect(page.videos.items, isNotEmpty);
    final more = await yt.browseContinuation(page.videos.continuation!);
    expect(more.entries.allItems, isNotEmpty);
  });

  test('shorts feed pages', () async {
    final first = await yt.shorts();
    expect(first.videoIds.length, greaterThan(3));
    final next = await yt.shorts(first.continuation);
    expect(next.videoIds, isNotEmpty);
  });
}
