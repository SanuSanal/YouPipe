# Status and roadmap

## Done (2026-10-03)

| Phase | What | Checked on the phone |
|---|---|---|
| 0 | Spike: WEB InnerTube, NewPipe video info, playback, background, PiP | Yes, 30/30 plus background and PiP ([phase0.md](phase0.md)) |
| 1 | Branding (logo, launcher icons, splash, notification icon) and YouTube theme (dark + light) | Yes, light theme |
| 1 | Shell: bottom nav, morphing watch panel, floating mini player (swipe up/down/sideways), fullscreen | Yes |
| 1 | Home (local mix, chips, Shorts shelf), Search (suggestions, history, results, filters, a channel's official card) | Yes |
| 1 | Watch page (details, actions, description panel, comments panel, related, queue) | Yes |
| 1 | Channel (tabs, sort chips), Playlist (YouTube + local), Subscriptions (local + RSS), You, History, Settings | Yes |
| 2 | Shorts tab and pages | Yes |
| 2 | Comments in Dart (avatars, Top/Newest, replies) | Yes |
| 2 | Captions, chapters, storyboard previews, speed, loop, sleep timer, quality sheet, 2× hold, double-tap seek | Yes |
| 2 | SponsorBlock (all categories), Return YouTube Dislike | Yes (sponsor skipped with Undo, segments on the seek bar) |
| 3 | Downloads (WorkManager + MediaMuxer, offline playback) | Yes: 480p (73 MB in 30 s, muxed), offline playback, retry |
| 3 | Subscriptions import/export (Takeout, NewPipe) | Unit-tested; the user is trying the file picker |
| 3 | Optional Google sign-in, account feeds, sync | Yes (the user's account, 2026-10-04; account.md) |
| 4 | Casting (Chromecast, DLNA) for video | DLNA yes (the user's TV); Chromecast not tried |
| 4 | In-app updater, release workflow, signing, R8 release build, website (like YouPipe Music's), README, remote config | Release build runs on the phone; repo and website published 2026-10-04 (https://github.com/SanuSanal/YouPipe, https://sanusanal.github.io/YouPipe/); remote config served. First release waits for the signing secrets |
| 6 | Tablets (rotation, 2–4 column grids, side rail, two-column watch page) and Android TV / Fire TV (launcher banner, the remote: focus ring, keys, starting focus) | Google TV emulator (Android 16) and Pixel C tablet emulator, 2026-10-04; phone unchanged. A real TV not yet |

## Fixed after release (2026-10-04)

- **Screen sleep:** the screen stays on while a video plays (watch page, fullscreen, mini player).
- **Background playback:** up to 3 re-resolves in a row (was once per video), waiting for the network while offline, and a Wi-Fi lock while playing.
- **Autoplay:**
  - it failed from the mini player and the background; up-next is now fetched early and kept alive;
  - YouTube's Up next countdown;
  - the switch moved from Settings into the player.
- **Gestures:** swipe up on the expanded video for fullscreen, swipe down to leave it.
- **Shorts:** Back from the Shorts tab no longer leaves the Short playing behind Home.
- **Toasts** close by themselves, including those with an action (the SponsorBlock Undo toast stayed up).
- **SponsorBlock is off by default**; it can be turned on in Settings.
- **TV:**
  - always 4 cards across;
  - search box on the left of the top bar, wordmark on the right.
- **Media notification and lock-screen controls** were missing from release builds (2026-10-05). Resource shrinking removed the icons that audio_service looks up by name, so the media session never updated. `res/raw/keep.xml` now keeps them (release.md). Stop or closing the mini player mid-play also left a stale notification, and notification Stop now closes the video (playback.md).

## Next

1. **A real TV:** sideload on an Android/Google TV or a Fire TV stick (the emulators passed; docs/release.md).
2. **Releases:** the signing secrets are set (2026-10-04); a `vMAJOR.MINOR.PATCH` tag on `main` builds and publishes one (release.md). The first is `v1.0.0`.

**Phase 5 (shared core) is deferred:** YouPipe is an independent project, so the two apps don't share a package. Useful fixes are copied across by hand.

## Known issues

- **YouTube's bot check:** after heavy use, YouTube may answer "Sign in to confirm that you're not a bot" for anonymous playback from an address. The app switches to the other address family (IPv4/IPv6) and retries, which fixed it on 2026-10-03 (streaming.md). If both are flagged, the player says so (`BOT_CHECK`). Signing in doesn't help: extraction uses NewPipe's mobile clients.

- **Occasional 403 on VISIONOS DASH requests:** recovered by one re-resolve (streaming.md).
- **4K plays at the display's resolution** (ExoPlayer's viewport cap).
- **Casting is 360p** unless the video is downloaded (cast.md).
