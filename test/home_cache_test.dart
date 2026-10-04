import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youpipe/innertube/models.dart';
import 'package:youpipe/providers.dart';

void main() {
  const video = VideoItem(
    id: 'dQw4w9WgXcQ',
    title: 'A video',
    channelName: 'A channel',
    channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
    viewsText: '1.2M views',
    publishedText: '3 days ago',
    durationText: '3:33',
    isShort: true,
  );

  test('a cached Home page reads back as it was written', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await writeVideoCache(prefs, 'k', [video]);
    final back = readVideoCache(prefs, 'k')!.single;
    expect(back.toJson(), video.toJson());
  });

  test('a cache older than its max age, or unreadable, is ignored', () async {
    final old = DateTime.now().subtract(const Duration(hours: 13)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'old': jsonEncode({
        'at': old,
        'items': [video.toJson()],
      }),
      'bad': 'not json',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(readVideoCache(prefs, 'old'), isNull);
    expect(readVideoCache(prefs, 'bad'), isNull);
    expect(readVideoCache(prefs, 'missing'), isNull);
  });
}
