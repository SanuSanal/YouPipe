# Playback

## Pieces

- **`VideoPlayerService`** (`lib/player/video_player_service.dart`) owns the one `VideoPlayerController`.
  - **`open(id)` picks the source:**
    1. a downloaded file (no network needed);
    2. live → HLS;
    3. the DASH manifest;
    4. muxed 360p.
  - **Recovery:** a mid-play error re-resolves once and resumes at the same position.
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
  - `sbSkipperProvider` seeks past "skip" segments once each.
  - A toast with Undo appears.
  - The segments are coloured on the seek bar.
- **PiP:**
  - Armed while a video plays (if enabled), only when the play state or shape changes. Never on devices without the PiP feature (most TVs, Fire TV): `SystemChannel.supportsPip`.
  - Android 12+ enters automatically on Home; older versions enter from `onUserLeaveHint`.
  - The shell then shows only the video.
- **Fullscreen:** `fullscreenProvider`. The shell switches to immersive mode (plus landscape on phones and tablets) and shows `PlayerView(fullscreen: true)`. On a TV a picked video starts fullscreen (`playVideo`).
- **Remote and keyboard keys:** see docs/ui.md, "The TV remote".
- **Background:**
  - `VideoPlayerOptions(allowBackgroundPlayback: true)` plus the audio_service foreground service.
  - Tested for 11 minutes screen-off in Phase 0.

## Shorts

`ShortsScreen` (the tab, or `…/short/:id`) gives each page its own controller (looping), preloads ±1, and pauses the main player while visible. Shorts are recorded in history.
