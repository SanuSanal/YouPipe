import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Parses a `name=value; name2=value2` cookie header.
Map<String, String> parseCookies(String cookie) => {
  for (final part in cookie.split(';'))
    if (part.trim().split('=') case [final name, ...final value] when name.isNotEmpty) name.trim(): value.join('='),
};

/// True when the cookie belongs to a signed-in Google session.
bool isSignedInCookie(String? cookie) {
  if (cookie == null) return false;
  final c = parseCookies(cookie);
  return c.containsKey('SAPISID') || c.containsKey('__Secure-3PAPISID');
}

/// The `Authorization` header youtube.com sends for signed-in requests:
/// `SAPISIDHASH <unix seconds>_<sha1("<seconds> <SAPISID> <origin>")>`.
String? sapisidHashHeader(String cookie, {String origin = 'https://www.youtube.com', DateTime? now}) {
  final c = parseCookies(cookie);
  final sapisid = c['SAPISID'] ?? c['__Secure-3PAPISID'];
  if (sapisid == null) return null;
  final ts = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  final hash = sha1.convert(utf8.encode('$ts $sapisid $origin')).toString();
  return 'SAPISIDHASH ${ts}_$hash';
}
