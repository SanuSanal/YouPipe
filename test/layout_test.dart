import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/innertube/models.dart';
import 'package:youpipe/ui/layout.dart';
import 'package:youpipe/ui/widgets/video_tiles.dart';

void main() {
  tearDown(() => DeviceInfo.current = const DeviceInfo());

  test('feed columns: one on phones, then 2, 3 and 4 like YouTube on tablets', () {
    expect(feedColumns(392), 1);
    expect(feedColumns(599), 1);
    expect(feedColumns(600), 2);
    expect(feedColumns(899), 2);
    expect(feedColumns(900), 3);
    expect(feedColumns(1208), 4);
  });

  test('TVs fit a card per 220 dp (4 across at 1080p, next to the rail)', () {
    DeviceInfo.current = const DeviceInfo(tv: true);
    expect(feedColumns(888), 4);
    expect(feedColumns(400), 2);
    expect(feedColumns(3000), 6);
  });

  test('wide (rail, two-column watch page) only in landscape from 900 dp', () {
    expect(isWide(const Size(1280, 900)), isTrue);
    expect(isWide(const Size(900, 1280)), isFalse);
    expect(isWide(const Size(800, 400)), isFalse);
  });

  test('phones stay portrait; tablets and TVs are free to rotate', () {
    expect(appOrientations(FormFactor.phone), [DeviceOrientation.portraitUp]);
    expect(appOrientations(FormFactor.tablet), isEmpty);
    expect(appOrientations(FormFactor.tv), isEmpty);
  });

  test('feed runs: consecutive videos form a grid run; Shorts, shelves and rows stand alone', () {
    VideoItem v(String id, {bool short = false}) => VideoItem(id: id, title: id, isShort: short);
    const channel = ChannelItem(id: 'UCx', name: 'A channel');
    final shelf = ShelfEntry('Latest', [v('s1')]);
    final runs = feedRuns([
      ItemEntry(const ChannelItem(id: 'UCx', name: 'A channel')),
      ItemEntry(v('a')),
      ItemEntry(v('b')),
      ItemEntry(v('short', short: true)),
      ItemEntry(v('c')),
      shelf,
    ]);
    expect(runs, hasLength(5));
    expect((runs[0] as ItemEntry).item, channel);
    expect((runs[1] as List<VideoItem>).map((v) => v.id), ['a', 'b']);
    expect(((runs[2] as ItemEntry).item as VideoItem).isShort, isTrue);
    expect((runs[3] as List<VideoItem>).map((v) => v.id), ['c']);
    expect(runs[4], same(shelf));
    expect(feedRuns(const []), isEmpty);
  });
}
