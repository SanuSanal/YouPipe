import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/features/watch/player_settings.dart';

void main() {
  test('cleanVtt strips the word timings and <c> spans of auto-generated tracks', () {
    const vtt = '''WEBVTT
Kind: captions

00:00:15.080 --> 00:00:16.880 align:start position:0%
a new division of Midjourney with the
goal<00:00:15.440><c> to</c><00:00:16.040><c.colorE5E5E5> reimagine</c>

''';
    final clean = cleanVtt(vtt);
    expect(clean, contains('00:00:15.080 --> 00:00:16.880 align:start position:0%'));
    expect(clean, contains('goal to reimagine'));
    expect(clean, isNot(contains('<')));
  });
}
