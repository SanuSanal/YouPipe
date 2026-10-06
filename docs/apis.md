# APIs used by the app

Every network API and native channel YouPipe talks to. Nothing here is secret, and the app has no API keys. **Never add real cookies, tokens or signed-in responses to this page.**

| Service | Host | Used for | Code |
|---|---|---|---|
| YouTube InnerTube (WEB) | `www.youtube.com/youtubei/v1` | Search, related, comments, channels, playlists, Shorts, account | `lib/innertube/` |
| YouTube streams (NewPipeExtractor) | `youtube.com`, `googlevideo.com` | Playable URLs, captions, storyboards, chapters, downloads, cast | `StreamExtractorChannel.kt`, `DownloadWorker.kt`, `CastProxy.kt` |
| Google suggest | `suggestqueries.google.com` | Search suggestions | `InnerTube.suggestions` |
| Channel RSS | `www.youtube.com/feeds/videos.xml` | Local subscriptions feed | `lib/data/subscriptions_feed.dart` |
| Return YouTube Dislike | `returnyoutubedislikeapi.com` | Like and dislike counts | `lib/data/ryd.dart` |
| SponsorBlock | `sponsor.ajay.app/api` | Segments to skip | `lib/features/sponsorblock/` |
| Google sign-in | `accounts.google.com` | Optional sign-in, in a WebView | `lib/features/account/` |
| GitHub | `api.github.com`, `github.com`, `raw.githubusercontent.com` | Updates, remote config | `lib/features/update/`, `lib/features/remote_config.dart` |
| Image CDNs | `i.ytimg.com`, `yt3.ggpht.com` | Thumbnails and avatars (not IP-bound) | — |
| Google Cast SDK, DLNA | Local network | Casting | `CastChannel.kt`, `lib/player/dlna.dart` |

## YouTube InnerTube (WEB client)

### Request format

- **Every call:** `POST https://www.youtube.com/youtubei/v1/<endpoint>?prettyPrint=false` with a JSON body `{"context": {"client": {clientName: WEB, clientVersion, hl, gl, visitorData}}, …}`.
- **Client:** `YouTubeClient.web` (`lib/innertube/clients.dart`), `X-YouTube-Client-Name: 1`. The version (`2.20261002.01.00` on 2026-10-03) can be overridden by the remote config.
- **Headers:** `User-Agent` (desktop Chrome), `X-YouTube-Client-Name`, `X-YouTube-Client-Version`, `Origin`/`Referer: https://www.youtube.com`, `X-Goog-Visitor-Id`.
- **Signed in** (`lib/innertube/auth.dart`), these are added:
  - `Cookie`;
  - `Authorization: SAPISIDHASH <ts>_<sha1("<ts> <SAPISID> https://www.youtube.com")>`;
  - `X-Goog-AuthUser: 0`;
  - `X-Origin`.

### Endpoints

| Dart method (`InnerTube`) | Endpoint | Body | Notes |
|---|---|---|---|
| `ensureVisitorData()` | `visitor_id` | none | |
| `home()` | `browse` | `browseId: FEwhat_to_watch` | Signed out with no history: empty plus a `feedNudgeRenderer` |
| `search(q, params:)` / `searchContinuation` | `search` | `query`, `params` / `continuation` | Filter groups come back in the response (`searchFilterGroupRenderer`) |
| `suggestions(input)` | GET `suggestqueries.google.com/complete/search?client=firefox&ds=yt` | | Plain JSON `[input, [suggestions…]]` |
| `related(videoId)` / `nextContinuation` | `next` | `videoId` / `continuation` | `secondaryResults` |
| `comments(videoId)` / `commentsContinuation` | `next` | `videoId`, then the `comment-item-section` token; replies and sort use their own tokens | Entities in `frameworkUpdates` |
| `channel(id, params:)` | `browse` | `browseId: UC…`, tab `params` | Sort chips' tokens re-sort via `browseContinuation` |
| `playlist(id)` | `browse` | `browseId: VL<id>` | Continuation via `continuationItemViewModel` |
| `browseContinuation` | `browse` | `continuation` | Items under `onResponseReceivedActions` |
| `shorts([token])` | `reel/reel_watch_sequence` | `sequenceParams` (`CA8%3D` fresh) | 1 entry, then 12 per page |
| `accountInfo()` | `account/account_menu` | none | Signed in |
| `accountFeed(id)` | `browse` | `FEhistory`, `FEplaylist_aggregation` | Signed in |
| `subscribedChannels()` | `browse` `FEchannels`, then `guide` when it's empty | The account's subscriptions: a shelf of `channelRenderer`s; with none, the page holds only its sort menu, and the sidebar (`guideSubscriptionsSectionRenderer`) confirms | Signed in |
| `like(id, liked:)` | `like/like`, `like/removelike` | `target: {videoId}` | Signed in |
| `subscribe(id, subscribe:)` | `subscription/subscribe`, `/unsubscribe` | `channelIds` | Signed in |
| `editPlaylist(id, videoId, add:)` | `browse/edit_playlist` | `playlistId` (`WL` = Watch later), `actions` | Signed in |

**Gone or empty signed out:** `FEtrending`, `FEexplore` (HTTP 400).

### Search filter params (`SearchFilter`)

Videos `EgIQAQ%3D%3D` · Shorts `EgIQCQ%3D%3D` · Channels `EgIQAg%3D%3D` · Playlists `EgIQAw%3D%3D` · Live `EgJAAQ%3D%3D`. The filter sheet uses the params from each response instead.

## Other HTTP APIs

- **Channel RSS:** `GET https://www.youtube.com/feeds/videos.xml?channel_id=UC…` returns the 15 latest uploads (Atom). Each entry has `yt:videoId`, `title`, `published`, `media:thumbnail`, `media:statistics@views`, and a `link` that contains `/shorts/` for Shorts.
- **Return YouTube Dislike:** `GET https://returnyoutubedislikeapi.com/votes?videoId=<id>` returns `{likes, dislikes, viewCount, …}`.
- **SponsorBlock:** `GET https://sponsor.ajay.app/api/skipSegments/<sha256(id)[0:4]>?categories=[…]&actionType=skip`. Only the hash prefix leaves the phone. A 404 means no segments.
- **GitHub Releases:** `GET https://api.github.com/repos/SanuSanal/YouPipe/releases/latest`. The APK is checked against the asset's `digest` (`sha256:<hex>`).
- **Remote config:** `GET https://raw.githubusercontent.com/SanuSanal/YouPipe/main/config/remote.json`, at most every 12 h.

## Platform channels (Dart ↔ Kotlin)

| Channel | Methods | Kotlin |
|---|---|---|
| `youpipe/playback_proxy` | `url({url, mimeType, contentLength?})` → a `http://127.0.0.1:<port>/s/<token>` URL that serves the googlevideo stream in 1 MB ranges (streaming.md) | `PlaybackProxy.kt` |
| `youpipe/stream_extractor` | `getVideoInfo({videoId, hl, gl, maxHeight})` → video info map (streaming.md). Errors: `AGE_RESTRICTED`, `GEO_RESTRICTED`, `UNAVAILABLE`, `RECAPTCHA`, `BOT_CHECK` ("Sign in to confirm that you're not a bot" over both IPv4 and IPv6; the native side already retried over the other address family, streaming.md), `NO_STREAMS`, `EXTRACTION_FAILED` | `StreamExtractorChannel.kt` |
| `youpipe/downloader` | `enqueue({videoId, title, dir, height, hl, gl})`, `cancel({videoId})`, `status()` → `[{videoId, state, downloaded, total, path, size, height, error}]`, `prune()` | `DownloadChannel.kt`, `DownloadWorker.kt` |
| `youpipe/cookies` | `get({url})` → cookie string; `clear()` | `CookieChannel.kt` |
| `youpipe/cast` (+ `youpipe/cast/events`) | `selectRoute`, `load`, `play`, `pause`, `seek`, `setVolume`, `disconnect`, `relayStart`, `relayUrl`, `relayStop` | `CastChannel.kt`, `CastProxy.kt` |
| `youpipe/updater` | `appInfo()`, `install({path})`, `openUrl({url})` | `UpdateChannel.kt` |
| `youpipe/pip` | `arm({enabled, width, height})`, `enter()`; from Kotlin: `changed(bool)`, `closed()` (the PiP window was closed, not expanded) | `MainActivity.kt` |
| `youpipe/system` | `requestNotifications()`; `device()` → `{tv, pip}` (television UI mode or leanback; the PiP feature), read once at startup (docs/ui.md); `playing({playing})`: keep the screen on and hold a Wi-Fi lock while a video plays (needs `ACCESS_WIFI_STATE`; docs/playback.md); `landscape()`: sensor landscape for fullscreen, either side even with rotation lock on (docs/ui.md) | `SystemChannel.kt` |
