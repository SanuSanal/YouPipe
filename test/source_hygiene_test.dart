import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/innertube/parsers.dart';

void main() {
  // A shell heredoc once turned the `\b` of a regex into a backspace character, silently breaking the parser.
  test('sources contain no control characters', () {
    final bad = RegExp('[\x00-\x08\x0B\x0C\x0E-\x1F]');
    final offenders = [
      for (final dir in ['lib', 'test', 'android/app/src/main'])
        for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('.dart') || f.path.endsWith('.kt'))
            if (bad.hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(offenders, isEmpty);
  });

  test("YouTube's short ages read in the long form", () {
    expect(longAge('3mo ago'), '3 months ago');
    expect(longAge('1y ago'), '1 year ago');
    expect(longAge('5d ago'), '5 days ago');
    expect(longAge('Streamed 2w ago'), 'Streamed 2 weeks ago');
    expect(longAge('3 months ago'), '3 months ago');
  });
}
