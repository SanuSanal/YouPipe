import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youpipe/data/video_info.dart';
import 'package:youpipe/features/settings/settings_screen.dart';
import 'package:youpipe/features/update/update.dart';
import 'package:youpipe/features/update/update_sheet.dart';
import 'package:youpipe/features/update/updater.dart';
import 'package:youpipe/innertube/innertube.dart';
import 'package:youpipe/player/video_player_service.dart';
import 'package:youpipe/providers.dart';
import 'package:youpipe/ui/theme/yt_theme.dart';
import 'package:youpipe/ui/widgets/common.dart';

const _update = AvailableUpdate(
  release: ReleaseInfo(tag: 'v9.9.9', notes: '- Fixes', pageUrl: releasesPageUrl, assets: []),
  apk: ReleaseAsset(name: 'YouPipe-v9.9.9-arm64-v8a.apk', url: 'https://example.invalid/a.apk', size: 27000000),
);

/// Roboto from the Flutter SDK (the test font is much wider), so rows that overflow here overflow on a phone too.
Future<void> _loadRoboto() async {
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path && !Directory('${dir.path}/material_fonts').existsSync()) {
    dir = dir.parent;
  }
  final fonts = Directory('${dir.path}/material_fonts');
  if (!fonts.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final f in ['roboto-regular', 'roboto-medium', 'roboto-bold']) {
    final file = File('${fonts.path}/$f.ttf');
    if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

class _FailedUpdate extends UpdateController {
  @override
  UpdateState build() => UpdateFailed(UpdateException('NETWORK', 'offline'), update: _update);
}

/// Text contrast (WCAG AA) and tap targets on screens that render without the network, in both themes. A light-mode
/// "Update" button once drew black text on black (2026-10-05).
void main() {
  late SharedPreferences prefs;

  setUpAll(_loadRoboto);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Brightness brightness,
    Widget home, {
    List overrides = const [],
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(990, 4000); // 360 dp wide: the narrowest common phone
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          innerTubeProvider.overrideWithValue(InnerTube()),
          videoInfoServiceProvider.overrideWithValue(VideoInfoService()),
          playerServiceProvider.overrideWithValue(VideoPlayerService(VideoInfoService())),
          ...overrides,
        ],
        child: MaterialApp(
          theme: buildYtTheme(brightness),
          home: home,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  }

  Widget sheetOpener() => Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(onPressed: () => showUpdateSheet(context, _update), child: const Text('open')),
      ),
    ),
  );

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      testWidgets('update sheet', (tester) async {
        await pumpApp(tester, brightness, sheetOpener());
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Update'), findsOneWidget);
        await expectAccessible(tester);
      });

      // Android's largest font size is 2x; the buttons wrap instead of overflowing (CI, without Roboto, overflowed).
      testWidgets('update sheet with the largest font size', (tester) async {
        await pumpApp(tester, brightness, sheetOpener(), textScale: 2);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Update'), findsOneWidget);
        await expectAccessible(tester);
      });

      testWidgets('update sheet after a failed download', (tester) async {
        await pumpApp(tester, brightness, sheetOpener(), overrides: [updateProvider.overrideWith(_FailedUpdate.new)]);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsOneWidget);
        await expectAccessible(tester);
      });

      testWidgets('settings', (tester) async {
        await pumpApp(tester, brightness, const SettingsScreen());
        expect(find.text('Manage all history'), findsOneWidget);
        await expectAccessible(tester);
      });

      testWidgets('error view', (tester) async {
        await pumpApp(
          tester,
          brightness,
          Scaffold(
            body: ErrorView(error: Exception('x'), onRetry: () {}),
          ),
        );
        await expectAccessible(tester);
      });
    });
  }
}
