# Phase 0 spike: results (2026-10-03)

**Test phone:** Moto edge 20 (Android 13, 1080×2400), on Wi-Fi in Ireland. **Libraries:** NewPipeExtractor v0.26.5, WEB client `2.20261002.01.00`, media3 1.9.2 (through `video_player`).

## Verdict: go

Every Phase 0 exit criterion passed on the device, including picture-in-picture. The architecture in `/PLAN.md` holds, with one change: signed-out **Home has to be built locally** (below).

## Playback (automated suite, final run: 30/30)

| Case | Result |
|---|---|
| 20 random VODs, opened at 75% of their length, at ≤1080p | **20/20**. DASH H.264 at 1080p (some at 720/854/858p, the video's own maximum). Load time (extraction + ExoPlayer ready) was **1.5–2.7 s**, typically about 1.8 s. Positions up to 9,872 s into a 3.6-hour video, far past the old 1 MB cap |
| 4K (`maxHeight: 2160`) | **2/2**. A VP9 manifest up to 2160p was built (hardware VP9 decoder present). ExoPlayer played it at 1080–1280p, capped to the display |
| Live | **2/2**, through HLS at 720p and 1080p, with load times of 1.6–2.7 s |
| Shorts from the Shorts feed | **5/5**, through DASH at 854–1080p and 1.5–1.6 s |
| Age-restricted (`6kLq3WMV1nU`) | **Friendly error:** `AGE_RESTRICTED` |
| Comments | 3,392 total; pages of 20; page 2 and a reply thread loaded |
| Captions / chapters / storyboards | VTT tracks (auto-generated included) on most videos, chapters where the uploader set them, and 2 storyboard levels on every VOD |
| **Background, screen off, dozing** | **659 s of continuous playback** over 11 minutes, no errors (`SPIKE|bg pos` every 30 s) |
| Picture-in-picture | **Pass.** Home during playback → the task went `mode=pinned` (480×270, 16:9). The window showed only the video, edge to edge, and playback continued (30.8 s → 41.5 s). Reopening the app restored the full watch page at 1080p without restarting the video |

## Problems found and fixed during the spike

1. **Self-waiting future.** In `VideoInfoService`, `whenComplete(() => _pending.remove(key))` returned the pending future itself, so every first `getVideoInfo` hung forever. The callback now returns nothing.
2. **User-Agent mismatch → 403.** The DASH streams come from the VISIONOS client and the muxed stream from ANDROID. The manifest had been sent with the muxed (ANDROID) User-Agent, and 2 of 20 VODs got 403 in an earlier run. Each source now has its own User-Agent.
3. **A Short failed extraction** on a NewPipe metadata getter (NPE in `nanojson`), after its streams were already found. Metadata getters are now best-effort.
4. **Transient `EXTRACTION_FAILED`:** NewPipe's `visitor_id` call got an HTML page. Extraction is retried once.
5. **Remaining occasional 403 on VISIONOS DASH** even with the right User-Agent: 1 of about 25 in one run, 0 in the next two. The player re-resolves once and resumes. The root cause is open (see streaming.md).

## InnerTube (WEB client, signed out)

| Feature | Result |
|---|---|
| **Home** (`FEwhat_to_watch`) | **Empty.** No videos, only "Your YouTube history is off". The same on the WEB, MWEB and TVHTML5 clients |
| Trending (`FEtrending`), Explore (`FEexplore`) | HTTP 400. These pages are gone |
| Search, continuation, filters | OK (`videoRenderer` + `shortsLockupViewModel` shelf) |
| Suggestions | OK through `suggestqueries.google.com` (`client=firefox`, `ds=yt`) |
| Related (`next`) | OK (`lockupViewModel`) with continuation |
| Channel | OK. Header from `pageHeaderViewModel`; tabs Home/Videos/Shorts/Live/Releases/Playlists/Posts with `params`; continuation |
| **Shorts feed** (`reel/reel_watch_sequence`) | **OK signed out.** A fresh sequence returns 1 entry; its continuation gives 12 per page (45 unique over 4 pages) |

**Consequence for Phase 1:** signed-out Home is assembled locally:
- related videos of recently watched videos;
- uploads from local subscriptions (RSS);
- chips that run topic searches.

Signed-in Home (Phase 3) uses `FEwhat_to_watch` as normal.

## Harness issues (not product bugs yet)

- **The UI disappears after `adb shell input text` in the search field,** until the next tap. Check it with a real keyboard in Phase 1.
- **One blank start after `install -r` + `am start`.** It didn't reproduce with `monkey`, or after a force-stop.
