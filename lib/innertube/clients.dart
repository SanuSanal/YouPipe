/// InnerTube client identities.
///
/// Versions drift: when YouTube starts rejecting requests, refresh [YouTubeClient.web] from
/// `INNERTUBE_CLIENT_VERSION` in youtube.com's page source.
class YouTubeClient {
  const YouTubeClient({
    required this.clientName,
    required this.clientVersion,
    required this.clientId,
    required this.userAgent,
    required this.origin,
  });

  final String clientName;
  final String clientVersion;

  /// Numeric id sent as `X-YouTube-Client-Name`.
  final int clientId;
  final String userAgent;
  final String origin;

  Map<String, dynamic> context({required String hl, required String gl, String? visitorData, String? version}) => {
    'client': {
      'clientName': clientName,
      'clientVersion': version ?? clientVersion,
      'hl': hl,
      'gl': gl,
      'visitorData': ?visitorData,
    },
  };

  Map<String, String> headers({String? visitorData, String? version}) => {
    'User-Agent': userAgent,
    'X-YouTube-Client-Name': '$clientId',
    'X-YouTube-Client-Version': version ?? clientVersion,
    'Origin': origin,
    'Referer': '$origin/',
    'X-Goog-Visitor-Id': ?visitorData,
  };

  /// YouTube web. Used for every browse/search/next/reel call.
  static const web = YouTubeClient(
    clientName: 'WEB',
    clientVersion: '2.20261002.01.00',
    clientId: 1,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
    origin: 'https://www.youtube.com',
  );
}
