import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Settings that can change without an app release (docs/remote_config.md), from `config/remote.json` on the main
/// branch. Fetched at most every 12 hours; the last copy is kept in prefs so it applies offline and at startup.
const remoteConfigUrl = 'https://raw.githubusercontent.com/SanuSanal/YouPipe/main/config/remote.json';

/// Applies the cached config at once, then refreshes it in the background. Watched from the app root.
final remoteConfigProvider = Provider<void>((ref) {
  final prefs = ref.read(prefsProvider);
  void apply(String json) {
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final version = m['webClientVersion'] as String?;
      // Only well-formed versions: a bad file must not break every request.
      if (version != null && RegExp(r'^2\.\d{8}\.\d{2}\.\d{2}$').hasMatch(version)) {
        ref.read(innerTubeProvider).clientVersion = version;
      }
    } catch (e) {
      debugPrint('YouPipe: remote config ignored: $e');
    }
  }

  final cached = prefs.getString('remoteConfig');
  if (cached != null) apply(cached);
  final last = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('remoteConfigAt') ?? 0);
  if (DateTime.now().difference(last) < const Duration(hours: 12)) return;
  Dio(BaseOptions(receiveTimeout: const Duration(seconds: 10)))
      .get<String>(remoteConfigUrl, options: Options(responseType: ResponseType.plain))
      .then((res) async {
        final body = res.data;
        if (body == null) return;
        apply(body);
        await prefs.setString('remoteConfig', body);
        await prefs.setInt('remoteConfigAt', DateTime.now().millisecondsSinceEpoch);
      })
      .catchError((Object e) => debugPrint('YouPipe: remote config fetch failed: $e'));
});
