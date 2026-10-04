import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/features/update/updater.dart';

void main() {
  final release = ReleaseInfo.fromJson(
    jsonDecode(File('test/fixtures/github_release.json').readAsStringSync()) as Map<String, dynamic>,
  );

  group('versions', () {
    test('parses with or without a v and ignores suffixes', () {
      expect(parseVersion('v1.2.3'), [1, 2, 3]);
      expect(parseVersion('0.0.3'), [0, 0, 3]);
      expect(parseVersion('1.10.0+42'), [1, 10, 0]);
      expect(parseVersion('nightly'), isNull);
    });

    test('compares numerically, not as text', () {
      expect(isNewerVersion('v0.0.4', '0.0.3'), isTrue);
      expect(isNewerVersion('v0.10.0', '0.9.9'), isTrue);
      expect(isNewerVersion('v1.0.0', '0.99.99'), isTrue);
      expect(isNewerVersion('v0.0.3', '0.0.3'), isFalse);
      expect(isNewerVersion('v0.0.3', '1.0.0'), isFalse);
      expect(isNewerVersion('garbage', '0.0.1'), isFalse);
    });
  });

  group('release', () {
    test('parses the GitHub release', () {
      expect(release.tag, 'v0.0.3');
      expect(release.version, '0.0.3');
      expect(release.pageUrl, 'https://github.com/SanuSanal/YouPipe/releases/tag/v0.0.3');
      expect(release.assets.map((a) => a.name), contains('SHA256SUMS.txt'));
    });

    test('picks the APK for the most preferred ABI the release has', () {
      expect(pickApk(release.assets, ['arm64-v8a', 'armeabi-v7a', 'armeabi'])?.name, endsWith('-arm64-v8a.apk'));
      expect(pickApk(release.assets, ['armeabi-v7a', 'armeabi'])?.name, endsWith('-armeabi-v7a.apk'));
      expect(pickApk(release.assets, ['x86_64', 'x86', 'arm64-v8a'])?.name, endsWith('-x86_64.apk'));
      expect(pickApk(release.assets, ['riscv64', 'arm64-v8a'])?.name, endsWith('-arm64-v8a.apk'));
      expect(pickApk(release.assets, ['mips']), isNull);
    });
  });

  test('reads the SHA-256 from GitHub asset digests', () {
    final apk = release.assets.firstWhere((a) => a.name.endsWith('-arm64-v8a.apk'));
    expect(apk.sha256, '553b6f4fe1c49c47260bc234073e2f7ae0b361e8d33e53a5d59353430e466733');
    expect(
      parseSha256Digest('sha256:A6D8C3717EECA7AD2D4D5F6ED8200DCF90D2011F64A8EBBE4B260A614FCA8C09'),
      'a6d8c3717eeca7ad2d4d5f6ed8200dcf90d2011f64a8ebbe4b260a614fca8c09',
    );
    expect(parseSha256Digest(null), isNull);
    expect(parseSha256Digest('sha512:abc'), isNull);
  });

  group('release notes', () {
    test('drops the APK hint and changelog link', () {
      expect(cleanReleaseNotes(release.notes), isEmpty);
    });

    test('turns the workflow notes into plain bullets', () {
      const body =
          "## What's new\n\n"
          '- Add an in-app update checker for GitHub releases\n'
          '- Fix **lyrics** sync\n\n'
          '**Which APK?** Most phones need `arm64-v8a`.';
      expect(cleanReleaseNotes(body), '• Add an in-app update checker for GitHub releases\n• Fix lyrics sync');
    });

    test('still reads the older GitHub-generated notes', () {
      const body =
          '**Which APK?** Most phones need `arm64-v8a`.\n\n'
          "## What's Changed\n"
          '* Add an update checker by @SanuSanal in https://github.com/SanuSanal/YouPipe/pull/5\n\n'
          '**Full Changelog**: https://github.com/SanuSanal/YouPipe/compare/v0.0.3...v0.0.4';
      expect(cleanReleaseNotes(body), '• Add an update checker');
    });
  });
}
