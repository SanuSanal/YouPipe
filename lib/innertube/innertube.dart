import 'dart:convert';

import 'package:dio/dio.dart';

import 'auth.dart';
import 'clients.dart';
import 'json_nav.dart';
import 'models.dart';
import 'parsers.dart';

export 'models.dart';

class InnerTubeException implements Exception {
  InnerTubeException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'InnerTubeException($statusCode): $message';
}

/// Search filters, as the `params` blobs youtube.com sends for its filter chips.
enum SearchFilter {
  videos('Videos', 'EgIQAQ%3D%3D'),
  shorts('Shorts', 'EgIQCQ%3D%3D'),
  channels('Channels', 'EgIQAg%3D%3D'),
  playlists('Playlists', 'EgIQAw%3D%3D'),
  live('Live', 'EgJAAQ%3D%3D');

  const SearchFilter(this.label, this.params);
  final String label;
  final String params;
}

/// YouTube (www.youtube.com) InnerTube client for browse/search/next/reel. Pure Dart, no Flutter imports.
class InnerTube {
  InnerTube({Dio? dio, this.hl = 'en', this.gl = 'US', this.visitorData})
    : _dio =
          dio ??
          Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20)));

  final Dio _dio;
  String hl;
  String gl;

  /// Anonymous session id. Without it YouTube serves degraded/generic responses.
  String? visitorData;

  /// A newer WEB client version from the remote config (docs/remote_config.md); null uses the built-in one.
  String? clientVersion;

  /// Google session cookie (from the sign-in WebView). When set, requests are authenticated (docs/account.md).
  String? cookie;

  bool get signedIn => isSignedInCookie(cookie);

  Map<String, String> _headers() {
    final headers = _client.headers(visitorData: visitorData, version: clientVersion);
    final c = cookie;
    if (c != null && isSignedInCookie(c)) {
      headers['Cookie'] = c;
      headers['Authorization'] = sapisidHashHeader(c)!;
      headers['X-Goog-AuthUser'] = '0';
      headers['X-Origin'] = 'https://www.youtube.com';
    }
    return headers;
  }

  /// Debug builds save raw responses through this, for re-recording fixtures from the device (docs/testing.md).
  void Function(String endpoint, Json data)? debugDump;

  static const _client = YouTubeClient.web;
  static const _base = 'https://www.youtube.com/youtubei/v1/';

  Future<Json> _post(String endpoint, Json body) async {
    try {
      final res = await _dio.post<Json>(
        '$_base$endpoint',
        queryParameters: {'prettyPrint': 'false'},
        data: {
          'context': _client.context(hl: hl, gl: gl, visitorData: visitorData, version: clientVersion),
          ...body,
        },
        options: Options(headers: _headers(), contentType: Headers.jsonContentType, responseType: ResponseType.json),
      );
      final data = res.data ?? const {};
      debugDump?.call(endpoint, data);
      visitorData ??= nav<String>(data, ['responseContext', 'visitorData']);
      return data;
    } on DioException catch (e) {
      throw InnerTubeException(e.message ?? e.type.name, statusCode: e.response?.statusCode);
    }
  }

  /// Fetches a fresh anonymous visitorData if we don't have one yet.
  Future<String?> ensureVisitorData() async {
    if (visitorData != null) return visitorData;
    final data = await _post('visitor_id', const {});
    return visitorData = nav<String>(data, ['responseContext', 'visitorData']);
  }

  /// Home. Signed out, YouTube returns no videos until there's watch history (see [HomeFeed.nudge]).
  Future<HomeFeed> home() async => parseHome(await _post('browse', {'browseId': 'FEwhat_to_watch'}));

  /// Search. [params] is a filter option's params (from [SearchPage.filters]) or a [SearchFilter].
  Future<SearchPage> search(String query, {String? params}) async =>
      parseSearch(await _post('search', {'query': query, 'params': ?params}));

  Future<SearchPage> searchContinuation(String token) async =>
      parseSearch(await _post('search', {'continuation': token}));

  /// Autocomplete, from Google's suggest service (the same one youtube.com uses).
  Future<List<String>> suggestions(String input) async {
    try {
      final res = await _dio.get<List<int>>(
        'https://suggestqueries.google.com/complete/search',
        queryParameters: {'client': 'firefox', 'ds': 'yt', 'hl': hl, 'gl': gl, 'q': input},
        options: Options(responseType: ResponseType.bytes),
      );
      final data = jsonDecode(utf8.decode(res.data ?? const [], allowMalformed: true));
      return (data is List && data.length > 1 && data[1] is List) ? (data[1] as List).whereType<String>().toList() : [];
    } on DioException catch (e) {
      throw InnerTubeException(e.message ?? e.type.name, statusCode: e.response?.statusCode);
    }
  }

  /// The watch page's related videos.
  Future<Paged<YtItem>> related(String videoId) async => parseNextRelated(await _post('next', {'videoId': videoId}));

  Future<Paged<YtItem>> nextContinuation(String token) async => parseList(await _post('next', {'continuation': token}));

  /// The first page of a video's comments (Top comments).
  Future<CommentsPage> comments(String videoId) async {
    final token = findCommentsToken(await _post('next', {'videoId': videoId}));
    if (token == null) return const CommentsPage([], null);
    return commentsContinuation(token);
  }

  /// More comments, a reply thread, or the list re-sorted by a sort chip's token.
  Future<CommentsPage> commentsContinuation(String token) async =>
      parseComments(await _post('next', {'continuation': token}));

  /// A channel page; [params] picks a tab (from [ChannelPage.tabs]), Home when null.
  Future<ChannelPage> channel(String channelId, {String? params}) async =>
      parseChannel(await _post('browse', {'browseId': channelId, 'params': ?params}), channelId);

  /// More of a browse list (channel tab, playlist), or a channel tab re-sorted by a [SortChip.token].
  Future<FeedPage> browseContinuation(String token) async =>
      parseFeedPage(await _post('browse', {'continuation': token}));

  Future<PlaylistPage> playlist(String playlistId) async =>
      parsePlaylist(await _post('browse', {'browseId': 'VL$playlistId'}), playlistId);

  // Signed in -----------------------------------------------------------------------------------------------------

  Future<AccountInfo?> accountInfo() async => parseAccountMenu(await _post('account/account_menu', const {}));

  /// An account feed as entries: `FEhistory`, `FElibrary`, `FEchannels` (subscriptions list), `FEsubscriptions`…
  Future<FeedPage> accountFeed(String browseId) async => parseFeedPage(await _post('browse', {'browseId': browseId}));

  /// The account's subscribed channels (`FEchannels`: a shelf of `channelRenderer`s). When it has none, the page
  /// holds only its sort menu, so the web sidebar (`guide`) is checked as well before reporting none.
  Future<FeedPage> subscribedChannels() async {
    final page = parseFeedPage(await _post('browse', {'browseId': 'FEchannels'}));
    if (page.entries.allItems.whereType<ChannelItem>().isNotEmpty) return page;
    return FeedPage([for (final c in parseGuideSubscriptions(await _post('guide', const {}))) ItemEntry(c)], null);
  }

  Future<void> like(String videoId, {bool liked = true}) => _post(liked ? 'like/like' : 'like/removelike', {
    'target': {'videoId': videoId},
  });

  Future<void> subscribe(String channelId, {bool subscribe = true}) =>
      _post(subscribe ? 'subscription/subscribe' : 'subscription/unsubscribe', {
        'channelIds': [channelId],
      });

  /// Adds to or removes from an account playlist (`WL` is Watch later).
  Future<void> editPlaylist(String playlistId, String videoId, {bool add = true}) => _post('browse/edit_playlist', {
    'playlistId': playlistId,
    'actions': [
      add
          ? {'action': 'ACTION_ADD_VIDEO', 'addedVideoId': videoId}
          : {'action': 'ACTION_REMOVE_VIDEO_BY_VIDEO_ID', 'removedVideoId': videoId},
    ],
  });

  /// The Shorts feed. Without a token it starts a fresh sequence.
  Future<ShortsPage> shorts([String? continuation]) async {
    final page = parseShortsSequence(
      await _post('reel/reel_watch_sequence', {'sequenceParams': continuation ?? 'CA8%3D'}),
    );
    // A fresh sequence holds a single Short; the real feed starts at its continuation.
    final next = page.continuation;
    if (continuation != null || page.videoIds.length > 3 || next == null) return page;
    final more = await shorts(next);
    return ShortsPage([
      ...page.videoIds,
      ...more.videoIds.where((id) => !page.videoIds.contains(id)),
    ], more.continuation);
  }
}
