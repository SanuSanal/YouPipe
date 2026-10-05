# Testing

## Automated

```bash
flutter analyze                          # must report no issues
flutter test                             # offline: parsers against the recorded fixtures
flutter test --tags live --run-skipped   # hits the real InnerTube API (smoke test for YouTube changes)
```

| Test | Covers |
|---|---|
| `test/innertube/parsers_test.dart` | Home (signed-out nudge), search (videos, Shorts shelf, continuation, a channel's official card), related (`lockupViewModel`), channel (header, tabs, items, `[views, age]` lockups), playlist, comments, Shorts sequence |
| `test/innertube/live_test.dart` | The same against the live API, plus every continuation and suggestions. Tagged `live`, skipped by default (`dart_test.yaml`) |
| `test/util/format_test.dart` | View counts, "3 hours ago", durations |
| `test/features/captions_test.dart` | Stripping the word timings of auto-generated captions (`cleanVtt`) |
| `test/home_cache_test.dart` | The Home launch cache: round trip, max age, unreadable data |
| `test/source_hygiene_test.dart` | No control characters in sources (a heredoc once turned a regex's word boundary into a backspace); `longAge` |
| `test/import_export_test.dart` | Takeout CSV and NewPipe JSON subscriptions |
| `test/updater_test.dart` | Release parsing, version comparison, APK choice, notes |

## Tablets and TVs (emulators)

- **AVDs** (created 2026-10-04):
  - `YouPipe_TV`: Google TV, Android 16, 1080p (`system-images;android-36;google-tv;x86_64`). The older API 30 TV image is 32-bit x86, which Flutter can't run on.
  - `YouPipe_Tablet`: Pixel C, Android 13 (`system-images;android-33;google_apis;x86_64`), 1280×900 dp.
  - Start: `emulator -avd YouPipe_TV -no-snapshot-save` (it's `emulator-5554`; pass `-s` to adb when the phone is connected too).
- **Install the `x86_64` split** of the release build (`build/app/outputs/flutter-apk/app-x86_64-release.apk`).
- **The remote:** `adb shell input keyevent KEYCODE_DPAD_UP|DOWN|LEFT|RIGHT|DPAD_CENTER|BACK|MEDIA_PLAY_PAUSE`; text with `adb shell input text`.
- **The TV launcher:** `adb shell cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.LEANBACK_LAUNCHER` must list `com.youpipe.app`. The emulator's first-run "Set up Google TV" screen sits on the launcher; start the app with `am start` and don't cancel the setup (it disables the network).
- **Rotate the tablet:** `settings put system accelerometer_rotation 0`, then `settings put system user_rotation 0|1`.
- **Debug focus:** debug builds log every focus change (`FOCUS …` in logcat).

## On a device

- **Build and install:** `flutter build apk --debug`, then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
- **Debug builds are slow** (JIT, no R8): about 3.6 s to the first frame, against about 0.4 s for a release build. Judge startup and scrolling speed on a release build (`flutter build apk --release --split-per-abi`, then install the arm64 APK). Without `key.properties` it's signed with the debug key, so it installs over a debug build and keeps the data.
- **Forcing the muxed stream:** `flutter build apk --release --split-per-abi --dart-define=FORCE_MUXED=true` skips the DASH manifest, so the muxed stream and its relay (`PlaybackProxy.kt`) get exercised. Don't ship that build.
- **Startup timing:** `adb shell am start -W -n com.youpipe.app/.MainActivity` (TotalTime) after `am force-stop`.
- **Launch** with `adb shell monkey -p com.youpipe.app -c android.intent.category.LAUNCHER 1`.
- **Use the Android SDK's adb** (`%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`), not the "Minimal ADB" on PATH. The test phone is a Moto edge 20 (`ZD22248D34`, 1080×2400, Android 13).
- **Bottom nav** at y≈2235: Home x≈135, Shorts x≈405, Subscriptions x≈675, You x≈945. Top-bar search is at (1005, 147).
- **Raw responses:** debug builds save InnerTube responses to `cache/innertube` (docs/innertube.md).
- **Logs:** `adb logcat -s flutter:I | grep "YouPipe:"`. Native extraction logs use the `YouPipe` tag (`getVideoInfo <id> fetched/streams/done +ms`, and the `clients:` line).
- **Raise the logcat buffer** (`adb logcat -G 16M`) before a full suite run, or early results rotate out.
- **Read results from the device.** Stream URLs are bound to the phone's IP, so they can't be replayed from the PC.
- **Screenshots:** stay inside the app; don't capture the user's home screen.
