# Architecture

## Layers

```
Flutter UI (lib/features/*, lib/ui/*)  ── Riverpod 3 providers (lib/providers.dart), go_router (lib/ui/router.dart)
   │
   ├─► InnerTube (lib/innertube/, pure Dart) ── dio → www.youtube.com/youtubei/v1   [client WEB]
   │      search · suggestions · next (related, comments) · channel · playlist · reel (Shorts) · account
   │
   ├─► PlaybackController (providers.dart) ── queue, autoplay, resume, history
   │      └─ VideoPlayerService (lib/player/) ── video_player (ExoPlayer) + audio_service (notification, background)
   │             └─ VideoInfoService (lib/data/video_info.dart) ── youpipe/stream_extractor (Kotlin, NewPipeExtractor)
   │                    DASH manifest · muxed 360p · live HLS · captions · storyboards · chapters · download options
   │
   ├─► Local data: drift (lib/data/db), LibraryRepository, SubscriptionsFeed (RSS), HomeMixer (local Home)
   │
   └─► Features (lib/features/*): downloads (WorkManager), account (sign-in), cast, SponsorBlock, updates,
       remote config — registered in lib/features.dart through hooks, so core screens don't import them
```

## Folder map

| Path | Role |
|---|---|
| `lib/main.dart` | Creates the services, registers features, runs `ProviderScope`. `AudioService` starts right after, off the first frame's path (it took about 110 ms); `VideoPlayerService.handler` is null until then |
| `lib/features.dart` | **Feature registration.** Each optional feature plugs in its routes, menu entries, settings sections, hooks and root providers here |
| `lib/providers.dart` | Services, settings, `PlaybackController`, paged list controllers, library streams |
| `lib/innertube/` | InnerTube client, models, parsers. No Flutter imports, so tests run in plain Dart |
| `lib/data/` | `VideoInfoService`, drift DB, `LibraryRepository`, `SubscriptionsFeed`, `HomeMixer`, Return YouTube Dislike |
| `lib/player/` | `VideoPlayerService`, `YouPipeAudioHandler`, `Pip`, the cast/DLNA engine |
| `lib/ui/` | Theme (`yt_theme.dart`), router, navigation helpers, the shell (bottom nav + watch panel), shared widgets |
| `lib/features/<area>/` | Screens and optional features (home, search, watch, shorts, channel, playlist, subscriptions, you, settings, downloads, account, cast, sponsorblock, update, diagnostics) |
| `android/app/src/main/kotlin/com/youpipe/app/` | Native channels: stream extraction, downloads (WorkManager), cookies, cast + LAN relay, updater, PiP, notification permission |
| `tool/inspect_feed.dart` | Prints how the parsers read a recorded response |
| `config/remote.json` | Remote config read by the app (docs/remote_config.md) |
| `site/` | The GitHub Pages website |

## Key decisions (short ADRs)

1. **No JS client.** Browse, search, comments and account logic are our own Dart InnerTube code.
2. **NewPipeExtractor for per-video streams:** stream URLs, captions, storyboards and chapters. It's also used for download and cast streams.
3. **Comments are parsed in Dart** (changed from Phase 0's plan, 2026-10-03). NewPipeExtractor v0.26.5 reads comment avatars from a path YouTube no longer fills; the avatar now sits at `author.avatarThumbnailUrl`. The Dart parser also gives the Top/Newest sort that NewPipe doesn't expose. See innertube.md.
4. **One player: `video_player` (ExoPlayer).** HD plays through a local DASH manifest file; the player falls back to the muxed 360p stream. Live plays as HLS; downloads play from their file.
5. **Signed-out Home is built locally** (`HomeMixer`). YouTube returns an empty Home to signed-out users with no watch history (EU, 2026-10-03), and Trending is gone. Signed in, YouTube's own recommendations are mixed in.
6. **Local-first library.** History, likes, Watch later, playlists and subscriptions live on the device. Sign-in is optional; when signed in, likes, subscriptions and Watch later are mirrored to the account on a best-effort basis.
7. **YouTube's design, YouPipe's branding** (ui.md): Roboto, Material Symbols, our cylinder-in-a-screen mark and our own Shorts glyph. No YouTube logos or YouTube Sans.
8. **Flutter, Android first.**

## Conventions

- `dart format -l 120`; `flutter analyze` must report no issues.
- **Riverpod 3 without code generation.** Family notifiers take their argument through the constructor.
- **Plain immutable model classes** (no freezed). `YtItem` subclasses compare equal by type and id.
- **Paged lists** use `PagedList<T>` and the `_Paging` mixin (`loadMore()`); screens call it from `LoadMoreListener`.
- **Optional features don't edit core screens.** They register through the hooks in `lib/features.dart`: `topBarExtraActions`, `youExtraEntries`, `youHeaderBuilder`, `settingsExtraSections`, `extraRootRoutes`, `extraDetailRoutes`, `downloadStarter`, `downloadPillBuilder`, `seekBarSegments`, `remoteControlsOf`, `castingViewBuilder`, `playerCastButton`, `shellStartHooks`, `LibraryRepository.remoteSync`, `VideoPlayerService.localVideo`.
