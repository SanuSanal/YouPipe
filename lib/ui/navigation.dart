import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../innertube/models.dart';
import '../providers.dart';

const branches = ['home', 'shorts', 'subscriptions', 'you'];

/// Detail pages are pushed inside the current bottom-nav branch (like YouTube), so every branch has the same
/// child routes under its own prefix.
String branchPrefix(BuildContext context) {
  final segments = GoRouter.of(context).routerDelegate.currentConfiguration.uri.pathSegments;
  final first = segments.firstOrNull;
  return '/${branches.contains(first) ? first : 'home'}';
}

void _push(BuildContext context, WidgetRef ref, String path) {
  ref.read(playerPanelProvider.notifier).collapse();
  unawaited(context.push('${branchPrefix(context)}$path'));
}

/// Plays a video in the watch panel, or opens a Short in the Shorts player.
void playVideo(BuildContext context, WidgetRef ref, VideoItem video, {List<VideoItem>? queue, int index = 0}) {
  if (video.isShort) {
    openShort(context, ref, video.id);
    return;
  }
  ref.read(playerPanelProvider.notifier).expand();
  unawaited(ref.read(playbackProvider.notifier).play(video, queue: queue, index: index));
}

void openShort(BuildContext context, WidgetRef ref, String videoId) => _push(context, ref, '/short/$videoId');

void openChannel(BuildContext context, WidgetRef ref, String channelId) => _push(context, ref, '/channel/$channelId');

void openPlaylist(BuildContext context, WidgetRef ref, String playlistId) =>
    _push(context, ref, '/playlist/$playlistId');

void openLocalPlaylist(BuildContext context, WidgetRef ref, int id) => _push(context, ref, '/local/$id');

void openSearch(BuildContext context, WidgetRef ref, {String? query}) =>
    _push(context, ref, '/search${query == null ? '' : '?q=${Uri.encodeQueryComponent(query)}'}');

String resultsPath(BuildContext context, String query, {String? params}) =>
    '${branchPrefix(context)}/results?q=${Uri.encodeQueryComponent(query)}'
    '${params == null ? '' : '&p=${Uri.encodeQueryComponent(params)}'}';

void openHistory(BuildContext context, WidgetRef ref) => _push(context, ref, '/history');

void openLiked(BuildContext context, WidgetRef ref) => _push(context, ref, '/liked');

void openChannels(BuildContext context, WidgetRef ref) => _push(context, ref, '/channels');

void openSettings(BuildContext context, WidgetRef ref) {
  ref.read(playerPanelProvider.notifier).collapse();
  unawaited(context.push('/settings'));
}

/// What tapping any card does.
void openItem(BuildContext context, WidgetRef ref, YtItem item) {
  switch (item) {
    case VideoItem():
      playVideo(context, ref, item);
    case ChannelItem():
      openChannel(context, ref, item.id);
    case PlaylistItem():
      openPlaylist(context, ref, item.id);
  }
}
