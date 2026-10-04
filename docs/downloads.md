# Downloads

- **Starting:** the ⋮ menu or the watch page's Download pill opens YouTube's "Download quality" sheet. The options come from `getVideoInfo`'s `downloadOptions`: each height with its total size (H.264 video + AAC audio, or the muxed stream at 360p and below); the sheet shows up to 1080p.
- **The job (`DownloadWorker.kt`):**
  - **Why WorkManager:** it runs as a WorkManager job with a foreground data-sync notification, so downloads continue when the app is closed. This fixes YouPipe Music's known gap.
  - **The steps:**
    1. Resolve fresh streams with NewPipeExtractor. URLs are bound to this phone and expire, so they're never passed in from Dart.
    2. Fetch the H.264 video-only stream and the best AAC stream in 1 MB ranges with the matching User-Agent (`Googlevideo`).
    3. Mux them into `<appSupport>/downloads/<videoId>.mp4` with `MediaMuxer`. At ≤360p, the muxed stream is downloaded directly instead.
  - Progress goes to the notification and to WorkManager's progress data.
- **Tracking (`DownloadManager`, `lib/features/downloads/downloads.dart`):**
  - Dart keeps the `Downloads` table in sync by polling `youpipe/downloader.status` every second while any job is active, and once at startup.
  - Finished jobs are recorded, then pruned from WorkManager.
  - A toast says when a download finishes.
- **Playback:** `VideoPlayerService.localVideo` returns the file plus offline info, so downloads play with no network (no extraction at all).
- **Managing:**
  - The Downloads page (You → Downloads) shows progress, size and quality.
  - ⋮ offers Retry (when failed) and Delete or Cancel; deleting removes the file. Tapping a failed row, or its "Download failed. Tap to retry" line, retries straight away.
- **Not yet:** an "audio only" download, and saving captions next to the file.
