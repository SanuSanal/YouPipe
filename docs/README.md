# YouPipe docs

YouPipe is an ad-free YouTube client for Android, built with Flutter. It copies the YouTube Android app's UI and uses its own logo.
- **Browse, search, comments and the optional account** call YouTube's internal **InnerTube** API (the `WEB` client) directly from Dart.
- **Streams, captions, storyboards and chapters** come from **NewPipeExtractor**, which runs on the Android side.

| Doc | Read when you touch |
|---|---|
| [architecture.md](architecture.md) | anything: layers, folder map, decisions, feature hooks |
| [apis.md](apis.md) | any network call or platform channel |
| [innertube.md](innertube.md) | `lib/innertube/**`: endpoints, renderers, parsers, comments, fixtures |
| [streaming.md](streaming.md) | `StreamExtractorChannel.kt`, `lib/data/video_info.dart`, NewPipeExtractor |
| [playback.md](playback.md) | `lib/player/**`, `PlaybackController`, captions, quality, PiP, fullscreen, Shorts playback |
| [ui.md](ui.md) | screens, widgets, theme tokens, branding, navigation, the watch panel |
| [data.md](data.md) | drift schema, library, subscriptions feed, local Home, settings keys |
| [downloads.md](downloads.md) | `DownloadWorker.kt`, `lib/features/downloads/` |
| [account.md](account.md) | optional Google sign-in and account sync |
| [cast.md](cast.md) | Chromecast, DLNA, the LAN relay |
| [release.md](release.md) | release workflow, signing, R8, in-app updates |
| [site.md](site.md) | the GitHub Pages website (`site/`), screenshots (`tool/screenshots.py`), README |
| [remote_config.md](remote_config.md) | `config/remote.json` |
| [testing.md](testing.md) | tests, fixtures, running on the device |
| [phase0.md](phase0.md) | what the Phase 0 spike measured |
| [roadmap.md](roadmap.md) | status, next steps, known issues |

The overall plan is in [`/PLAN.md`](../PLAN.md). Docs describe the **current** state. When code changes a documented behaviour, update the doc in the same change.
