# Releases and updates

## Publishing a release

1. **One-time setup:** create the repo `SanuSanal/YouPipe` and add these repository secrets: `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
   - Using the same keystore as YouPipe Music is fine; the application IDs differ.
2. **Releasing:** bump `version:` in `pubspec.yaml`, commit, then tag and push `vMAJOR.MINOR.PATCH`.
3. **What the workflow does** (`.github/workflows/release.yml`):
   - runs `flutter analyze` and `flutter test`;
   - builds split-per-ABI signed APKs (`YouPipe-v<version>-<abi>.apk`), writes notes from commit subjects, and creates the GitHub release.
4. **Local release builds:**
   - Signing comes from `android/key.properties`, or the env vars `ANDROID_KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`; without them the debug key is used.
   - `key.properties` and `*.jks` are git-ignored.
5. **R8:** `android/app/proguard-rules.pro` keeps NewPipeExtractor and Rhino, which load classes by reflection, and the no-arg constructors of Room databases. WorkManager opens `WorkDatabase_Impl` by reflection; without that rule the release build crashed at launch in `InitializationProvider` (found 2026-10-03).
   - **Resource shrinking:** `android/app/src/main/res/raw/keep.xml` keeps the drawables that are only looked up by name at runtime: audio_service's notification icon (`ic_stat_youpipe`) and its button icons (`audio_service_*`).
     - Without them, on Android 13+ audio_service throws "You must specify an icon resource id to build a CustomAction" for the Stop button on every state update. The media session then never updates, so there was no media notification, no lock-screen controls and no foreground service (found 2026-10-05).
   - **Always launch a release build on the phone before tagging**, play a video and check its notification: debug builds don't run R8 or shrink resources. Checked on 2026-10-03 (arm64 APK about 26 MB, cold start about 380 ms).

## Android TV, Google TV and Fire TV

- The same APKs install on TVs: the manifest makes leanback and the touchscreen optional, and `LEANBACK_LAUNCHER` plus `android:banner` (`res/drawable-xhdpi/tv_banner.png`, 320×180, drawn by `python tool/tv_banner.py`) put YouPipe on the TV home screen.
- **Which APK:** most Android/Google TV boxes take `arm64-v8a`; many Fire TV sticks run 32-bit Android and need `armeabi-v7a`.
- **Sideloading:** with a file manager or Downloader app, or `adb install` over Wi-Fi after enabling developer options.
- Fire OS has no Google Play services; Cast is off on TVs anyway, and `CastChannel` already checks for Play services.

## In-app updates (`lib/features/update/`)

- **On launch** (3 s after the shell appears, release builds only, unless turned off):
  - checks `api.github.com/repos/SanuSanal/YouPipe/releases/latest`;
  - compares versions, picks the APK for the phone's ABI, and offers the update sheet.
- **Installing:** the APK is downloaded, checked against GitHub's SHA-256 digest, and installed with `PackageInstaller` (`UpdateChannel.kt`). The user confirms in Android's dialog.
- **Settings → Updates:** an auto-check switch and "Check for updates" (with the version).

## Website

`site/` is published by `.github/workflows/pages.yml` to `https://sanusanal.github.io/YouPipe/`. One-time setup: repo Settings → Pages → Source: GitHub Actions. Details (live download buttons, screenshots, design) are in [site.md](site.md).
