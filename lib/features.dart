/// Feature registration: later phases (downloads, sign-in, SponsorBlock, cast, updates) plug their routes, menu
/// entries, settings sections and startup providers in here, so the core screens don't import them directly.
library;

import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'package:flutter/material.dart' show Colors;
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'features/account/account.dart';
import 'features/cast/cast_feature.dart';
import 'features/downloads/downloads.dart';
import 'features/remote_config.dart';
import 'features/settings/settings_screen.dart';
import 'features/sponsorblock/sponsorblock.dart';
import 'features/subscriptions/import_export.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/update/update.dart';
import 'features/watch/player_view.dart';
import 'features/watch/seek_bar.dart';
import 'features/you/you_screen.dart';
import 'providers.dart';
import 'ui/router.dart';
import 'ui/shell/app_shell.dart';
import 'ui/widgets/top_bar.dart';
import 'ui/widgets/video_menu.dart';

/// Providers watched from the app root so they're created (and hook themselves in) at startup.
final rootProviders = <ProviderListenable<Object?>>[];

void registerFeatures() {
  // Client fixes without a release.
  rootProviders.add(remoteConfigProvider);

  // SponsorBlock: skipping, the seek bar colours, and its settings.
  rootProviders.add(sbSkipperProvider);
  seekBarSegments = sbSeekBarSegments;
  settingsExtraSections.add(sponsorBlockSettings);

  // Downloads: the ⋮ entry and watch-page pill, the Downloads page, and syncing with the Android jobs.
  rootProviders.add(downloadManagerProvider);
  downloadStarter = startDownload;
  downloadPillBuilder = downloadPill;
  extraDetailRoutes.add(() => GoRoute(path: 'downloads', builder: (_, _) => const DownloadsScreen()));
  youExtraEntries.add((icon: Symbols.download, label: 'Downloads', onTap: openDownloads));

  // Optional Google sign-in: the You header, the login page, account lists, and syncing likes/subscriptions.
  rootProviders.add(authProvider);
  youHeaderBuilder = accountHeader;
  extraRootRoutes.add(
    GoRoute(path: '/login', parentNavigatorKey: rootNavigatorKey, builder: (_, _) => const LoginScreen()),
  );
  extraDetailRoutes.add(
    () => GoRoute(
      path: 'account/:id',
      builder: (_, s) =>
          AccountFeedScreen(browseId: s.pathParameters['id']!, title: s.uri.queryParameters['title'] ?? ''),
    ),
  );

  // Casting to Chromecast and DLNA TVs.
  rootProviders.add(castBridgeProvider);
  remoteControlsOf = castRemoteOf;
  castingViewBuilder = castingView;
  playerCastButton = () => const CastButton(color: Colors.white);
  topBarExtraActions.add((_) => const CastButton());

  // In-app updates from GitHub Releases.
  shellStartHooks.add(checkForUpdateOnLaunch);
  settingsExtraSections.add(updateSettings);

  // Import / export subscriptions (Google Takeout, NewPipe).
  ChannelsScreen.extraActions.add(subscriptionsMenu);
}
