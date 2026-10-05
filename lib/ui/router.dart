import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/channel/channel_screen.dart';
import '../features/home/home_screen.dart';
import '../features/playlist/playlist_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shorts/shorts_screen.dart';
import '../features/subscriptions/subscriptions_screen.dart';
import '../features/you/you_screen.dart';
import 'shell/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root-level routes added by later features (login, downloads…).
final extraRootRoutes = <RouteBase>[];

/// Branch pages added by later features (Downloads…).
final extraDetailRoutes = <GoRoute Function()>[];

/// Pages pushed inside any bottom-nav branch (so the nav bar and mini player stay visible).
List<RouteBase> _detailRoutes() => [
  for (final r in extraDetailRoutes) r(),
  GoRoute(
    path: 'search',
    builder: (_, s) => SearchScreen(initial: s.uri.queryParameters['q']),
  ),
  GoRoute(
    path: 'results',
    builder: (_, s) => ResultsScreen(
      key: ValueKey(s.uri.toString()),
      query: s.uri.queryParameters['q'] ?? '',
      params: s.uri.queryParameters['p'],
    ),
  ),
  GoRoute(
    path: 'channel/:id',
    builder: (_, s) => ChannelScreen(channelId: s.pathParameters['id']!),
  ),
  GoRoute(
    path: 'playlist/:id',
    builder: (_, s) => PlaylistScreen(playlistId: s.pathParameters['id']!),
  ),
  GoRoute(
    path: 'local/:id',
    builder: (_, s) => LocalPlaylistScreen(id: int.parse(s.pathParameters['id']!)),
  ),
  GoRoute(path: 'history', builder: (_, _) => const HistoryScreen()),
  GoRoute(
    path: 'liked',
    builder: (_, _) => const LocalPlaylistScreen(id: LocalPlaylistScreen.liked),
  ),
  GoRoute(path: 'channels', builder: (_, _) => const ChannelsScreen()),
  GoRoute(
    path: 'short/:id',
    builder: (_, s) => ShortsScreen(startId: s.pathParameters['id'], isTab: false),
  ),
];

GoRouter buildRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen(), routes: _detailRoutes())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/shorts', builder: (_, _) => const ShortsScreen(), routes: _detailRoutes())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/subscriptions', builder: (_, _) => const SubscriptionsScreen(), routes: _detailRoutes()),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/you', builder: (_, _) => const YouScreen(), routes: _detailRoutes())],
        ),
      ],
    ),
    GoRoute(path: '/settings', parentNavigatorKey: rootNavigatorKey, builder: (_, _) => const SettingsScreen()),
    ...extraRootRoutes,
  ],
);
