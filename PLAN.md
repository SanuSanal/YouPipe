# YouPipe: a YouTube clone built on YouPipe Music's API stack

## Verdict: feasible, and most of the hard parts are already solved

YouPipe Music already has the two pieces that decide whether a third-party YouTube client works:

1. **A pure-Dart InnerTube client** (`lib/innertube/`): request context, visitorData, continuations, SAPISIDHASH sign-in, and tolerant JSON navigation.
2. **Playable stream URLs from NewPipeExtractor**: it gets past the ~1 MB PO-token cap, and it already builds **HD DASH manifests (up to 1080p) that play in ExoPlayer through `video_player`** (Video mode, tested 2026-09-30).

A YouTube app reuses both. The work that changes is:

- **The client and renderers:** `WEB` on `www.youtube.com` instead of `WEB_REMIX`, so every parser is new.
- **A video-first player:** it becomes the main surface instead of an optional output.
- **YouTube's UI:** video feed, watch page, Shorts, comments, channels.

Roughly **40% of the code carries over** as-is or lightly adapted: native channels, downloads, sign-in, updater, cast relay, release pipeline, SponsorBlock and error log. All the infrastructure risk is already retired.

## Decisions to confirm

| # | Decision | Recommendation | Why |
|---|---|---|---|
| D1 | Repo strategy | **New repo `SanuSanal/YouPipe` at `D:\claude\YouPipe`.** Copy the shared files in. YouPipe stays an independent project: the shared-core plugin (Phase 5) is deferred | The two apps' clients, parsers and players differ. Extracting a plugin now would destabilise the shipped music app for no gain |
| D2 | Player engine | **`video_player` (ExoPlayer) + `audio_service`**, reusing `VideoOutput`'s DASH-manifest approach. Escape hatch: a small native Media3 plugin, if the Phase 0 spike shows quality switching or PiP is too limited | Already proven on the device. A native Media3 player is cleaner but means writing a texture/platform-view plugin |
| D3 | Comments source | **Changed in Phase 2: parsed in Dart** from the `next` endpoint's comment entities. The original recommendation was NewPipeExtractor `CommentsInfo`, but v0.26.5 misses avatars after a YouTube change, and Dart also gets YouTube's Top/Newest sort (docs/innertube.md) | Avatars and sort; the entity format is documented and fixture-tested |
| D4 | Library without sign-in | **Local-first, like the music app.** Local subscriptions (feed from channel RSS), watch history, Watch later and playlists. A Google account is optional and adds the real Home/Subscriptions feeds. **Phase 0 finding:** signed-out Home is *empty* (YouTube only shows "Your YouTube history is off", and Trending is gone). So signed-out Home is built locally from related videos of recent history, local subscription uploads and topic chips (docs/phase0.md) | No-account use is the main reason people use NewPipe-style apps |
| D5 | Identity | App name **"YouPipe"**, applicationId **`com.youpipe.app`**, dark + light themes (YouTube supports both) | `com.youpipe.music` is taken by the sibling app; both can be installed side by side |
| D6 | License | **GPL-3.0** (applies to both apps) | NewPipeExtractor is GPL-3.0, and the APK links it. YouPipe Music has no LICENSE file yet, so add one there too |

## Branding

- **Mark:** a red rounded rectangle (10:7, the "screen") with YouPipe Music's white 3/4-view **cylinder** inside, replacing YouTube's play triangle. The concept is drafted in `design/`:
  - `design/logo.svg`: the mark.
  - `design/logo_wordmark.svg`: the top-bar wordmark (mark + "YouPipe", Roboto Bold).
  - `design/logo_preview.html`: the mark on its own, as a launcher icon, at 24 px, in the dark top bar, and next to YouPipe Music.
- **Launcher icon:** an adaptive icon with a white background layer and a foreground of the red screen + cylinder inside the 66 dp safe zone, plus a monochrome layer (screen outline, cylinder cut out). Generate it with `flutter_launcher_icons`, using the ImageMagick render step from `docs/ui.md`.
- **Splash** (`flutter_native_splash`): `#0F0F0F` background with the mark in the centre. **Notification icon:** a white screen silhouette with the cylinder cut out.
- **Same rules as YouPipe Music:** no YouTube logos or play-triangle, no YouTube Sans; Roboto + Material Symbols.
- **Trademark caution:** "You…" plus a red rounded rectangle sits closer to YouTube's trade dress than the music badge did. That's fine for GitHub/F-Droid distribution; don't take it to the Play Store.

## UI: match YouTube Android (2026), with YouPipe branding

**Theme tokens** (`lib/ui/theme/yt_theme.dart`):

| Token | Dark | Light |
|---|---|---|
| Background | `#0F0F0F` | `#FFFFFF` |
| Surface / sheets | `#212121` | `#FFFFFF` |
| Chip / pill | `#272727` | `#F2F2F2` |
| Selected chip | `#F1F1F1`, black text | `#0F0F0F`, white text |
| Text | `#F1F1F1` | `#0F0F0F` |
| Secondary text | `#AAAAAA` | `#606060` |
| Brand / progress | `#FF0000` | `#FF0000` |

Thumbnails are 16:9 with an 8–12 dp radius; avatars are circular.

**Screens**

- **Shell:**
  - Top bar: wordmark, then cast, search and (signed in) avatar.
  - Bottom nav: **Home · Shorts · Subscriptions · You** (no Create or Notifications).
  - The watch page minimises into a **mini player above the nav**: drag down to minimise, swipe away to close. Reuse `app_shell.dart`'s single-`AnimationController` panel logic.
- **Home:**
  - A chips row (All, Music, Gaming, Live…, from the response).
  - A feed of full-width video cards: thumbnail with a duration badge, avatar, title, and "channel · views · age", plus ⋮.
  - A Shorts shelf (2-column, 9:16).
  - Infinite continuation.
- **Watch page:**
  - The player at the top (16:9). Below it: title, "views · age · …more" (description sheet with chapters), and a channel row with the Subscribe pill.
  - A horizontally scrolling action-pill row: Like | Dislike (RYD count), Share, Download, Save, Report → ⋮.
  - A comments teaser card that opens the comments sheet. Then the related feed.
- **Player chrome:**
  - Double-tap ±10 s, a seek bar with **storyboard preview thumbnails**, chapter markers, and SponsorBlock segment colours.
  - A settings sheet: quality, speed, captions, loop, sleep timer.
  - Fullscreen in landscape (swipe up for related), **PiP**, and background play.
- **Shorts:** a vertical `PageView` of full-screen looping players (preload ±1). Right rail: like, dislike, comments, share, ⋮. Channel + Subscribe at the bottom.
- **Search:**
  - Suggestions and local history.
  - Results mix videos, channels, playlists, Shorts shelves and "People also watched" shelves.
  - Filter sheet: Upload date, Type, Duration, Features, Sort.
- **Channel:** banner, avatar, handle, subscriber/video count, description, Subscribe. Tabs: **Home, Videos, Shorts, Live, Playlists**, plus channel search. Videos are sortable (Latest / Popular / Oldest).
- **Playlist:** header (tinted from the thumbnail, reusing `TintedPage`), Play all / Shuffle, and the video list.
- **You:** History, Playlists, Watch later, Liked videos, Downloads, Settings, and an account switcher/sign-in.
- **Video ⋮ sheet:** Play next in queue, Save to Watch later, Save to playlist, Download, Share, Not interested (signed in), Don't recommend channel (signed in).

## Architecture

```
Flutter UI (Riverpod 3, go_router)
   │
   ├─► InnerTube (pure Dart, lib/innertube/) ── dio → www.youtube.com/youtubei/v1   [client WEB]
   │      browse · search · next · reel · account
   │
   ├─► VideoPlayerService (lib/player/) ── video_player (ExoPlayer) + audio_service (notification, background)
   │      └─ StreamResolver ──► youpipe/stream_extractor (Kotlin, NewPipeExtractor)
   │             video info: DASH MPD (≤ 4K), muxed 360p, live HLS, captions, storyboards, chapters, comments
   │
   ├─► Downloads ── youpipe/downloader (OkHttp 1 MB ranges) + youpipe/muxer (MediaMuxer: mp4/webm)
   └─► Local data: drift (history, subscriptions, playlists, watch later, downloads, resume positions)
```

### InnerTube (WEB client)

- **Request format:** `POST https://www.youtube.com/youtubei/v1/<endpoint>?prettyPrint=false`, with `clientName: WEB`, `X-YouTube-Client-Name: 1`, `Origin: https://www.youtube.com`, and visitorData as today.
  - Read the client version from `INNERTUBE_CLIENT_VERSION` in youtube.com's page source, and keep it in `clients.dart` (the remote config comes later).
  - **Signed in:** compute SAPISIDHASH over the origin `https://www.youtube.com`.
- **Endpoints**

  | Feature | Endpoint |
  |---|---|
  | Home | `browse` `FEwhat_to_watch` (chips are `browse` + `params`) |
  | Subscriptions feed (signed in) | `browse` `FEsubscriptions` |
  | History, library (signed in) | `browse` `FEhistory`, `FElibrary` / `FEyou` |
  | Watch later, Liked | `browse` `VLWL`, `VLLL` |
  | Channel | `browse` `UC…`, with each tab's `params` taken from the tab's endpoint in the first response |
  | Playlist | `browse` `VL<id>` |
  | Search | `search` (`query`, filter `params`), plus continuation |
  | Suggestions | `suggestqueries-clients6.youtube.com/complete/search?ds=yt&client=youtube` (JSONP; verify in Phase 0) |
  | Watch page | `next` (`videoId`): primary/secondary info, channel, like state, related continuation, chapters, comments token |
  | Shorts feed | `reel/reel_watch_sequence` / `reel/reel_item_watch` (verify in Phase 0; fallback: Shorts from search and channel Shorts tabs) |
  | Actions (signed in) | the same `like/*`, `subscription/*`, `playlist/create` and `browse/edit_playlist` as the music app, plus `feedback` |

- **Parsers:** YouTube is mid-migration from legacy renderers to view-models, so every parser handles **both**:
  - legacy `videoRenderer`, `richItemRenderer` and `reelItemRenderer`;
  - newer `lockupViewModel` and `shortsLockupViewModel`, plus `frameworkUpdates.entityBatchUpdate` for like/subscribe state.

  Keep the `json_nav.dart` tolerant-navigation style and the recorded-fixture tests.

### Streams (extend `StreamExtractorChannel.kt`)

- **New `getVideoInfo({videoId, hl, gl, maxHeight})`**, one extraction returning:
  - `mpd`: the existing `buildMpd`, raised to ≤ 2160p. Prefer AVC ≤ 1080p for compatibility, and add VP9/AV1 above that when `MediaCodecList` reports a decoder.
  - `muxed360` (fallback / data saver).
  - `hlsUrl` for live streams (`getHlsUrl()`; `getLength() == 0`).
  - `subtitles` (`getSubtitlesDefault()`, VTT URLs incl. auto-generated).
  - `frames` (`getFrames()`, storyboards for seek previews).
  - `segments` (`getStreamSegments()`, chapters).
  - `isShort`, `ageLimit`, and the `userAgent`.
- **New `getComments({videoId, page?})`** and **`getReplies({page})`**, from NewPipe `CommentsInfo` / `getMoreItems`. The page token is passed back as an opaque string.
- **Keep the existing rules:** URLs are IP- and client-bound, cache them until `expire − 10 min`, and refresh once on a mid-play error. **When playback breaks, bump NewPipeExtractor first.**

### Player

- **`VideoPlayerService`** owns a `VideoPlayerController` (from `VideoOutput`) plus an `audio_service` handler for the notification, lock-screen controls, headset buttons and background play.
- **Captions:**
  - Fetch the VTT in Dart.
  - Render with `ClosedCaptionFile` (WebVTT) in our own overlay, so the styling matches YouTube.
- **Quality change:**
  - Auto lets ExoPlayer adapt across the manifest's Representations.
  - A fixed quality rebuilds the MPD with `onlyBest` at that height, then seeks to the saved position. A sub-second gap is acceptable.
- **Background audio-only** (optional setting): when the app goes to background, switch to the existing `just_audio` audio pipeline to save data, and resume video on return.
- **Other playback features:**
  - **PiP:** `enterPictureInPictureMode` from `MainActivity` (auto-enter on home press while playing, Android 12+ `setAutoEnterEnabled`). Flutter renders only the video surface while in PiP.
  - **Resume positions** are stored per video. History records a watch after 10 s or 30%.
  - **SponsorBlock:** all categories (sponsor, selfpromo, interaction, intro, outro, preview, filler, music_offtopic), each set to skip / mute / show / off.
  - **Return YouTube Dislike:** `returnyoutubedislikeapi.com/votes?videoId=`.

### Local data (drift)

- **Tables:** `history(videoId, watchedAt, positionMs, durationMs)`, `subscriptions(channelId, name, avatar, addedAt)`, `feed_cache(channelId, videoId, publishedAt, …)`, `playlists` and `playlist_items` (including a built-in Watch later), `downloads`, and `search_history`.
- **Local subscriptions feed:**
  - Source: `https://www.youtube.com/feeds/videos.xml?channel_id=UC…`, which is cheap (15 latest per channel) and parsed with the `xml` package.
  - Refresh: in parallel, rate-limited, cached for 30 min.
  - The channel Videos tab is used for "load more".
- **Import:** subscriptions from Google Takeout (`subscriptions.csv`) and from NewPipe's JSON export.

### Downloads

- **Pick a pair of matching streams:** AVC video + AAC m4a (itag 140) → **mp4**, or VP9 + Opus → **webm**.
- **Fetch them** natively with the existing `DownloadChannel` (1 MB ranges, matching UA). Then **mux** with Android `MediaMuxer` in a new `youpipe/muxer` channel.
- **Other options:** "Audio only" reuses the music app's path. Captions can be saved as a `.vtt` sidecar.
- **Fix the music app's known gap:** run downloads in a foreground `WorkManager` job, so they survive process death.

## What carries over from YouPipe Music

| Keep as-is | Adapt | Rewrite | Drop |
|---|---|---|---|
| `Googlevideo.kt`, `DownloadChannel.kt`, `CookieChannel.kt`, `UpdateChannel.kt`, `CastProxy.kt`; `data/error_log.dart`, `updater.dart`; `.github/workflows/*`; `tool/*.py` | `innertube.dart`, `clients.dart`, `auth.dart` (WEB, www origin); `StreamExtractorChannel.kt` (`getVideoInfo`, comments); `stream_resolver.dart`; `video_output.dart` → `VideoPlayerService`; `sponsorblock.dart` (all categories); `login_screen.dart` (youtube.com); `app_shell.dart` panel → watch-page minimise; cast (`CastChannel.kt`, `dlna.dart`) for video | All parsers and models, theme, every screen, `audio_handler.dart` (video-centric, much smaller) | Lyrics/LRCLIB, Android Auto browser, lock-screen player, equalizer (optional later) |

Copy **AGENTS.md / CLAUDE.md and the `docs/` module structure** too (architecture, apis, innertube, streaming, playback, ui, data, testing, roadmap). Then record the decisions above as ADRs from day one.

## Phases

### Phase 0: spike (go/no-go gate)

1. `flutter create --org com.youpipe --project-name youpipe --platforms android .`, then copy the native channels and `build.gradle.kts` setup (JitPack, desugaring, R8 keep rules).
2. WEB-client `home`, `search` and `next` against live YouTube. Record fixtures.
3. `getVideoInfo` → play through `VideoPlayerService`:
   - 20 random videos at 1080p to the end;
   - one 4K video (VP9);
   - one live stream (HLS);
   - 5 Shorts;
   - one age-restricted video (expect a friendly error).
4. Background play with the screen off for 10+ minutes; PiP enter and exit.
5. Check that the Shorts feed endpoint, the suggestions endpoint and `CommentsInfo` work.

**Exit:** all of the above work on the test phone (ZD22248D34), with no 403s past 1 MB. **If PiP or quality switching is unworkable with `video_player`, decide D2 here.**

### Phase 1: MVP

1. Branding (final logo, launcher icons, splash, notification icon) and the theme (dark/light). The shell: top bar, bottom nav, mini player.
2. InnerTube WEB module: models, parsers (legacy + view-model), continuations, typed errors, fixture tests, and a `live` smoke test.
3. Home (chips + feed), Search (suggestions, history, filters), Channel (tabs, sorting), Playlist.
4. The watch page with the player: quality, speed, double-tap seek, fullscreen, minimise to the mini player, related feed, background play with notification controls, resume positions.
5. The local library: history, local subscriptions + RSS feed, Watch later, playlists. Settings: region/language, default quality on Wi-Fi and mobile, and clear cache.

### Phase 2: YouTube parity

Shorts tab, comments (with replies), captions, chapters, storyboard seek previews, PiP, live streams (with a DVR seek window where available), SponsorBlock (all categories), Return YouTube Dislike, sleep timer, loop, and play queue.

### Phase 3: offline and account

- Video downloads (mux) with WorkManager.
- Import of Takeout/NewPipe subscriptions.
- Google sign-in (WebView, youtube.com): personalised Home, the Subscriptions feed, history, Liked/WL, playlists, and like/subscribe/save sync (best-effort, local-first, as in the music app).

### Phase 4: polish and distribution

- Cast: Chromecast and DLNA, relaying the muxed or progressive stream through `CastProxy`. Video over DLNA needs a single-file stream, so 360p muxed or a downloaded file.
- In-app updater pointed at `SanuSanal/YouPipe`, the tag-triggered release workflow, a GitHub Pages site, and screenshots.
- Remote client config (WEB client version, parser toggles), shipped without a release.

### Phase 5: shared core (deferred)

**Deferred (2026-10-03):** YouPipe is an independent project, so no shared core is planned. Fixes worth having in both apps (such as YouPipe Music's `PlaybackProxy.kt`) are copied across instead.

The original idea was to extract `youpipe_core` (a Flutter plugin) holding the InnerTube base, the NewPipe channel, the downloader/muxer, the updater, cast and the error log, and move both apps onto it.

## Risks

| Risk | Mitigation |
|---|---|
| Renderer churn on `www.youtube.com` (the view-model migration) | Dual parsers, fixture tests, a `live` test tag, renderer-tree tooling (`tool/renderer_tree.py`) |
| Stream breakage (PO token, client changes) | Bump NewPipeExtractor first. The extraction path is shared with the music app, so a fix there applies here |
| **Rate limiting / reCAPTCHA (429):** a video app makes many more calls than a music app | Cache aggressively (feeds, video info until `expire`), throttle the RSS refresh, show a friendly 429 error, and back off |
| 4K/VP9/AV1 decoding on low-end phones | Choose codecs from `MediaCodecList`; AVC ≤ 1080p is the default |
| `video_player` limits (PiP, track selection) | D2's escape hatch: a native Media3 plugin |
| ToS / trademark | GitHub/F-Droid only, GPL-3.0, no YouTube marks |

## Verification

- `flutter analyze` must report nothing; `dart format -l 120`; `flutter test` (parser fixtures, resolver and queue logic); `flutter test --tags live --run-skipped` whenever InnerTube code changes.
- **On the device:**
  - Home → watch at 1080p with no ads;
  - minimise, then background, then screen off, then notification controls;
  - PiP;
  - quality/speed/captions;
  - a Shorts swipe-through;
  - comments paging;
  - a live stream;
  - a download, then playback while offline;
  - subscribe locally, then the feed shows new uploads;
  - airplane mode shows friendly errors.
- **Visual parity:** side-by-side comparison against reference screenshots of YouTube Android (kept in `design/reference/`, not shipped), plus golden tests for the shell, Home card, watch page and Shorts.
