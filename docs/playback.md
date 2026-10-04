# Playback

## Pieces

- **`VideoPlayerService`** (`lib/player/video_player_service.dart`) owns the one `VideoPlayerController`.
  - **`open(id)` picks the source:**
    1. a downloaded file (no network needed);
    2. live → HLS;
    3. the DASH manifest;
    4. muxed 360p.
  - **Recovery:** a mid-play error (an expired or rejected URL, or the network dropping) re-resolves and resumes at the same position.
    - Up to 3 re-resolves in a row (`VideoPlayerService.nextRecovery`); playing a minute past the last recovery point earns a fresh budget, so a long video recovers as often as it needs to but a broken stream doesn't loop. Before 2026-10-04 it was once per video, so a long background session ended on "Tap to retry".
    - **Offline:** if the re-resolve fails and `www.youtube.com` doesn't resolve, the video stays loading and tries again after 5, 15, 30 s and then every minute, for about 5 minutes. The media notification shows buffering meanwhile (still "playing", so the service stays in the foreground). Only then does the error show.
  - **Completion:** it fires `completed` when a video ends.
- **`YouPipeAudioHandler`** mirrors the player to the media session (notification, lock screen, headset):
  - previous / play-pause / next / stop, seek ±10 s;
  - next and previous call the `PlaybackController`.
- **`PlaybackController`** (`playbackProvider`):
  - **State:** `NowPlaying` (video, queue, index, loop).
  - **Commands:** `play`, `next`, `previous`, `playNext`, `addToQueue`, `toggleLoop`, `stop`.
  - **Resume:** uses `LibraryRepository.resumePosition`.
  - **History:** records each watch and saves the position every 5 s.
  - **Video info:** when it arrives, fills in the channel avatar and other details.
- **Autoplay:**
  - When a video ends, the next queued video plays.
  - Otherwise, if Autoplay is on, the first related video that isn't a Short, live, or already finished plays (`upNextProvider`).
  - The Next button always does this, even with Autoplay off.
  - **Fetched early and kept alive:** `PlaybackController` listens to the current video's `upNextProvider` from the moment it starts. The mini player and the background show no related list, and Riverpod 3 drops an unlistened `autoDispose` provider, so the old one-off `ref.read` at the end of the video could be lost and nothing played (reported 2026-10-04). A failed fetch is tried once more.
  - **The switch is in the player**, like YouTube: the small play/pause toggle in the top row (`_AutoplaySwitch`), with "Autoplay is on/off" over the video. It's no longer in Settings; the stored setting (`autoplay`) is unchanged.
  - **Up next countdown:** on the watch page or in fullscreen, with the app in front, the player shows "Up next in 5" with the video, Cancel and Play now (`upNextCountdownProvider`; Play now has focus on a TV). Cancel leaves the ended video with its replay button. In the mini player, PiP or the background the next video starts straight away.

## Watch-page features

- **Quality:**
  - The setting caps the manifest's height. Auto is ≤1080p.
  - In the player sheet, a fixed height rebuilds the manifest at that cap (`setMaxHeight`), keeping position, speed and play state.
  - ExoPlayer also caps to the display size.
- **Captions (`captionsProvider`):**
  - The VTT track is set on the controller (`WebVTTCaptionFile`) and drawn by `CaptionOverlay` (white on 75% black).
  - Auto-generated tracks carry karaoke markup (`word<00:00:15.080><c> next</c>`), which `cleanVtt` strips first; otherwise it shows as text.
  - The chosen language carries over to the next videos (`captionLang`); the manual track is preferred over the auto-generated one.
- **Chapters and storyboards** come from video info. The seek bar shows chapter gaps, and the storyboard frame and chapter title while dragging.
- **Speed:** 0.25–2×. Hold the video for 2× while held.
- **Sleep timer:** 10–60 min, or the end of the video.
- **Loop:** `setLooping`.
- **SponsorBlock:**
  - **Off by default** (`sb_enabled`, since 2026-10-04): skipping changes how videos play compared with YouTube, so the user turns it on in Settings → SponsorBlock ("Skip sponsors and more"). While it's off nothing is fetched and the seek bar has no segment colours.
  - `sbSkipperProvider` seeks past "skip" segments once each.
  - A toast with Undo appears, and closes by itself after 4 s.
  - The segments are coloured on the seek bar.
- **PiP:**
  - Armed while a video plays (if enabled), only when the play state or shape changes. Never on devices without the PiP feature (most TVs, Fire TV): `SystemChannel.supportsPip`.
  - Android 12+ enters automatically on Home; older versions enter from `onUserLeaveHint`.
  - The window then shows only the video. The app root draws it (`MaterialApp.router` `builder` in `main.dart`) above every route, with the pages kept mounted but offstage, so it covers Settings, Diagnostics and sign-in too. Those open above the shell, and before 2026-10-04 PiP from Settings showed the Settings page.
- **Fullscreen:** `fullscreenProvider`. The shell switches to immersive mode (plus landscape on phones and tablets) and shows `PlayerView(fullscreen: true)`. On a TV a picked video starts fullscreen (`playVideo`).
  - Swipe up on the expanded video to enter it, swipe down in fullscreen to leave (more than 48 dp or a fling), like YouTube.
- **Staying awake:** while a video plays (not paused, ended or failed), `VideoPlayerService` tells `youpipe/system` → `playing`:
  - the activity keeps the screen on (`FLAG_KEEP_SCREEN_ON`), which only matters while the app is visible: the watch page, fullscreen, the mini player or PiP;
  - a Wi-Fi lock (`WIFI_MODE_FULL_HIGH_PERF`, what ExoPlayer's `WAKE_MODE_NETWORK` uses) keeps Wi-Fi out of power save with the screen off. audio_service already holds the CPU wakelock while playing, but video_player's ExoPlayer holds no Wi-Fi lock.
- **Remote and keyboard keys:** see docs/ui.md, "The TV remote".
- **Background:**
  - `VideoPlayerOptions(allowBackgroundPlayback: true)` plus the audio_service foreground service.
  - Tested for 11 minutes screen-off in Phase 0.

## Shorts

`ShortsScreen` (the tab, or `…/short/:id`) gives each page its own controller (looping), preloads ±1, and pauses the main player while visible. Shorts are recorded in history.

A Short plays only while its page is the current route, its tab is on screen and the watch page is closed. "On screen" comes from `TickerMode`: the shell keeps the Shorts tab alive offstage, and Riverpod pauses an offstage widget's listeners, so watching `currentTabProvider` alone missed the switch. Back from the Shorts tab used to leave the Short playing behind Home (fixed 2026-10-04).
