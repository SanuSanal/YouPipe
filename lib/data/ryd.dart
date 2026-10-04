import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Like and dislike counts from Return YouTube Dislike (`returnyoutubedislikeapi.com`), since YouTube hides
/// dislikes (docs/apis.md).
class Votes {
  const Votes(this.likes, this.dislikes);

  final int likes;
  final int dislikes;
}

final _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'YouPipe/1.0 (Android; https://github.com/SanuSanal/YouPipe)'},
  ),
);

final votesProvider = FutureProvider.autoDispose.family<Votes?, String>((ref, videoId) async {
  try {
    final res = await _dio.get<Map<String, dynamic>>(
      'https://returnyoutubedislikeapi.com/votes',
      queryParameters: {'videoId': videoId},
    );
    final d = res.data;
    if (d == null) return null;
    return Votes((d['likes'] as num?)?.toInt() ?? 0, (d['dislikes'] as num?)?.toInt() ?? 0);
  } catch (_) {
    return null;
  }
});
