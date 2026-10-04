# Local data

## Database (drift, `lib/data/db/app_database.dart`), schema version 2

| Table | Holds |
|---|---|
| `Videos` | Metadata cache for every video the library refers to |
| `WatchHistory` | One row per video: `watchedAt`, `positionMs`, `durationMs` (resume + red watched bars) |
| `LikedVideos` | Liked videos |
| `Subscriptions` | Channels subscribed on this device |
| `FeedVideos` (`FeedVideoRow`) | Subscription uploads from RSS, last 60 days |
| `Playlists` / `PlaylistItems` (`PlaylistEntryRow`) | Local playlists; **Watch later** is the playlist with `isWatchLater` (created at first launch) |
| `SavedPlaylists` | YouTube playlists saved to the library |
| `SearchHistory` | Search queries |
| `Downloads` (v2) | Offline videos: state, height, path, sizes, error (docs/downloads.md) |

- **Changing the schema:** bump `schemaVersion`, add an `onUpgrade` step, and run `dart run build_runner build --delete-conflicting-outputs`.
- **Drift data classes** that would clash with model names are renamed with `@DataClassName`.

## LibraryRepository (`lib/data/library_repository.dart`)

- **History:**
  - `recordWatch` upserts on play.
  - `PlaybackController` saves the position every 5 s.
  - `resumePosition` returns null below 15 s or near the end.
- **Everything else:** likes, playlists (add/remove/move/rename/delete), Watch later toggle, saved playlists, subscriptions (incl. bulk import), search history.
- **`remoteSync`** (set by the account feature) mirrors likes, subscriptions and Watch later to a signed-in account; it's best-effort.

## Subscriptions feed (`lib/data/subscriptions_feed.dart`)

- `refresh()` fetches each subscription's RSS, six channels at a time. It runs at most every 30 min unless forced (pull-to-refresh, subscribing).
- `watch()` joins `FeedVideos` with `Subscriptions` (for avatars), newest first.

## Home (`lib/data/home_feed.dart`, `HomeMixer`)

Signed-out YouTube has no Home, so it's built on the device. **Sources:**

| Source | Weight |
|---|---|
| The signed-in account's Home (when signed in) | 3 |
| Related videos of the last 6 watched videos (with continuations) | 2 |
| Unwatched subscription uploads from the last 14 days | 2 |
| Topic searches | 1, or 2 when there's nothing personal |

**How they're mixed:**
- Round-robin by weight.
- No repeats, and nothing already ≥90% watched.
- Every source starts at once.

**Topic chips** (Music, Gaming, Live, News, …) are searches. "Recently uploaded" shows the subscription uploads.

**Launch cache (`HomeController`, `homeShortsProvider`):** the mix takes 1.3–1.7 s of network time, so the last first page of the "All" chip and its Shorts shelf are kept in preferences (`homeCache`, `homeShortsCache`: `{at, items}` of `VideoItem.toJson`, used for 12 hours).
- Once per launch, Home shows the cached page in the first frame while the fresh mix loads.
- The fresh page replaces it only if the user hasn't touched Home yet (`HomeController.touched`), so a tap never lands on a video that just changed. Otherwise the cached page stays, and "load more" continues from the fresh mix without repeats.
- The cached Shorts shelf stays for the session; the fresh one is saved for the next launch. That way the feed below the shelf never jumps.

## Settings (SharedPreferences keys)

| Key | Meaning |
|---|---|
| `themeMode` | system / dark / light |
| `hl`, `gl` | Language and region for InnerTube and NewPipe |
| `quality` | auto (≤1080p) / higher (≤2160p) / dataSaver (≤480p) |
| `autoplay`, `resume`, `pip` | Playback |
| `saveHistory`, `saveSearchHistory` | false = paused |
| `homeCache`, `homeShortsCache` | The Home launch cache (above) |
| `captionLang` | The last caption language (CC remembers it) |
| `sb_enabled`, `sb_<category>` | SponsorBlock master switch (off by default) and per-category skip/show/off |
| `autoUpdateCheck`, `skippedUpdateVersion` | Updater |
| `remoteConfig`, `remoteConfigAt` | Cached remote config |
| `visitorData` | The anonymous InnerTube session |

**Kept elsewhere:** the Google session cookie is in `flutter_secure_storage` (`yt_cookie`), never in prefs.
