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
| 4 | In-app updater, release workflow, signing, R8 release build, website (like YouPipe Music's), README, remote config | Release build runs on the phone (after the R8 fix); website previewed locally; publishing needs the GitHub repo |

## Next

1. **On-device pass** over everything still marked "not yet" above. Capture the watch page, mini player and Shorts screenshots for the website (site.md).
2. **Publish:** create `SanuSanal/YouPipe`, add the signing secrets, push, tag `v0.1.0`, and enable Pages.

**Phase 5 (shared core) is deferred:** YouPipe is an independent project, so the two apps don't share a package. Useful fixes are copied across by hand.

## Known issues

- **YouTube's bot check:** after heavy use, YouTube may answer "Sign in to confirm that you're not a bot" for anonymous playback from an address. The app switches to the other address family (IPv4/IPv6) and retries, which fixed it on 2026-10-03 (streaming.md). If both are flagged, the player says so (`BOT_CHECK`). Signing in doesn't help: extraction uses NewPipe's mobile clients.

- **Occasional 403 on VISIONOS DASH requests:** recovered by one re-resolve (streaming.md).
- **4K plays at the display's resolution** (ExoPlayer's viewport cap).
- **Casting is 360p** unless the video is downloaded (cast.md).
