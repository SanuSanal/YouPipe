import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/db/app_database.dart';
import 'data/library_repository.dart';
import 'data/video_info.dart';
import 'features.dart';
import 'innertube/innertube.dart';
import 'player/video_player_service.dart';
import 'providers.dart';
import 'ui/messenger.dart';
import 'ui/router.dart';
import 'ui/theme/yt_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  // Portrait like YouTube; fullscreen switches to landscape.
  unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));

  final prefs = await SharedPreferences.getInstance();
  final innerTube = InnerTube(visitorData: prefs.getString('visitorData'));
  if (kDebugMode) {
    // adb shell run-as com.youpipe.app ls cache/innertube
    final dir = Directory('${(await getTemporaryDirectory()).path}/innertube')..createSync(recursive: true);
    innerTube.debugDump = (endpoint, data) =>
        File('${dir.path}/${endpoint.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.json')
            .writeAsString(jsonEncode(data));
  }
  final infos = VideoInfoService();
  final player = VideoPlayerService(infos);
  // The media session isn't needed until something plays, so it doesn't hold up the first frame (~110 ms).
  unawaited(() async {
    player.handler = await AudioService.init(
      builder: () => YouPipeAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.youpipe.app.playback',
        androidNotificationChannelName: 'Playback',
        androidNotificationIcon: 'drawable/ic_stat_youpipe',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }());

  // Keep the anonymous session stable across launches.
  innerTube.ensureVisitorData().then((v) {
    if (v != null) prefs.setString('visitorData', v);
  }, onError: (_) {});

  final db = AppDatabase();
  // YouTube always shows Watch later, even when empty.
  unawaited(LibraryRepository(db).watchLaterId());

  registerFeatures();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        innerTubeProvider.overrideWithValue(innerTube),
        videoInfoServiceProvider.overrideWithValue(infos),
        playerServiceProvider.overrideWithValue(player),
        databaseProvider.overrideWithValue(db),
      ],
      child: const YouPipeApp(),
    ),
  );
}

class YouPipeApp extends ConsumerStatefulWidget {
  const YouPipeApp({super.key});

  @override
  ConsumerState<YouPipeApp> createState() => _YouPipeAppState();
}

class _YouPipeAppState extends ConsumerState<YouPipeApp> {
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    // Creating the playback controller wires autoplay and notification next/previous at startup.
    ref.watch(playbackProvider.select((_) => null));
    for (final p in rootProviders) {
      ref.watch(p);
    }
    return MaterialApp.router(
      title: 'YouPipe',
      debugShowCheckedModeBanner: false,
      theme: buildYtTheme(Brightness.light),
      darkTheme: buildYtTheme(Brightness.dark),
      themeMode: settings.themeMode,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: _router,
    );
  }
}
