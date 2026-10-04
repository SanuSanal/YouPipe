import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays a googlevideo progressive stream through PlaybackProxy.kt on 127.0.0.1, which fetches it in 1 MB
/// ranges. ExoPlayer's own open-ended request is throttled to about twice real time (docs/streaming.md).
abstract final class PlaybackProxy {
  static const _channel = MethodChannel('youpipe/playback_proxy');

  /// The loopback URL that serves [url], or null when the relay can't start (then play [url] directly).
  static Future<Uri?> uriFor(String url, {String mimeType = 'video/mp4'}) async {
    try {
      final proxied = await _channel.invokeMethod<String>('url', {'url': url, 'mimeType': mimeType});
      return proxied == null ? null : Uri.parse(proxied);
    } on PlatformException catch (e) {
      debugPrint('YouPipe: playback proxy unavailable: ${e.message}');
      return null;
    }
  }
}
