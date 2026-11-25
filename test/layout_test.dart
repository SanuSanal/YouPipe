import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Orientation;
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/innertube/models.dart';
import 'package:youpipe/ui/layout.dart';
import 'package:youpipe/ui/widgets/video_tiles.dart';

void main() {
  tearDown(() => DeviceInfo.current = const DeviceInfo());

  const portrait = Orientation.portrait;
  const landscape = Orientation.landscape;

  test('feed columns: one on phones, 2 on portrait tablets, 3 on landscape ones, like YouTube', () {
    expect(feedColumns(392, portrait), 1);
    expect(feedColumns(599, portrait), 1);
    expect(feedColumns(600, portrait), 2);
    expect(feedColumns(900, portrait), 2);
    expect(feedColumns(1200, portrait), 2);
    expect(feedColumns(800, landscape), 2);
    expect(feedColumns(900, landscape), 3);
    expect(feedColumns(1280, landscape), 3);
    expect(feedColumns(1848, landscape), 3);
  });

  test('TVs always show 4 cards across, whatever width in dp they report', () {
    DeviceInfo.current = const DeviceInfo(tv: true);
    expect(feedColumns(888, landscape), 4);
    expect(feedColumns(1368, landscape), 4);
    expect(feedColumns(3000, landscape), 4);
  });

  test('wide (two-column watch page) only in landscape from 900 dp', () {
    expect(isWide(const Size(1280, 900)), isTrue);
    expect(isWide(const Size(900, 1280)), isFalse);
    expect(isWide(const Size(800, 400)), isFalse);
  });

  test('the side rail is for TVs only; tablets keep the bottom bar', () {
    expect(showsSideRail(const Size(1280, 900)), isFalse);
    DeviceInfo.current = const DeviceInfo(tv: true);
    expect(showsSideRail(const Size(1280, 720)), isTrue);
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
