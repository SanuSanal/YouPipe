# Website and README

The public landing page lives in `site/` and is published to GitHub Pages at https://sanusanal.github.io/YouPipe/ by `.github/workflows/pages.yml` whenever `site/**` changes on `main` (or by running the workflow by hand). It follows YouPipe Music's site (same layout, fonts and pipe band), with video content.

- **One-time setup:** repo Settings → Pages → Build and deployment → Source: **GitHub Actions**.
- **Plain static files, no build step:** `index.html` has all its CSS and JS inline. `logo.svg` is a copy of `assets/branding/logo.svg`, and `og.png` of `assets/branding/logo_1024.png` (the link preview image). Update the copies if the logo changes.
- **Download buttons are live:** on load, the page reads `api.github.com/repos/SanuSanal/YouPipe/releases/latest` and points the buttons at that release's APKs, with the version and size. It relies on the release workflow's asset names (`YouPipe-v<version>-<abi>.apk`; see [release.md](release.md)). Without the API (offline, rate-limited, or before the first release) the buttons fall back to the Releases page.
- **Which APK:** arm64 by default. On an Android browser that reports a 32-bit ARM or x86 CPU (User-Agent Client Hints), it offers that APK instead. It never guesses from a desktop browser, since people often download on a PC for their phone.
- **Design:** porcelain background (dark variant via `prefers-color-scheme`), brand red, Unbounded for headings, Instrument Sans for text, JetBrains Mono for versions and ABIs. The signature is the red band with the logo's white pipe, which features scroll along into the bore; the motion stops under `prefers-reduced-motion`.
- **Hero mockup:** the watch page drawn in CSS with a made-up video (a cabin at dusk, "Slow Roads"): player with a SponsorBlock skip chip, title, channel row, action pills, comments teaser and the next video. No real thumbnails and no YouTube logos.
- **Screenshots** ("Take a look", `#screenshots`): real captures from the app in dark theme, on a rail that scrolls sideways. Make them with `python tool/screenshots.py <dir of raw PNGs>` from 1080×2400 `adb exec-out screencap -p` captures. It swaps the real status bar for a clean one (time 2:10, signal, Wi-Fi and a battery; dark icons on light screens) and writes:
  - `site/screenshots/<name>.webp`: the bare screen, which the site puts in its CSS frame;
  - `assets/screenshots/<name>.webp`: the same screen already framed (transparent WebP), for the README.

  The file name sets the order (`1-home`, `2-watch`, …). Add each new one to the `.shots` list in `index.html` and the README table. They show real thumbnails, unlike the hero mockup. Capture from the app only, never the launcher or other apps.
- **The set (2026-10-04):** Home, watch page, mini player, Shorts, search, channel, playlist, Subscriptions.
- **Phone frame:** one style everywhere, flat sides with thin even bezels, a punch-hole camera and two side keys on the right, with no brand marks. On the site it's the `.device` class (hero mockup and gallery); for the README it's drawn by `tool/screenshots.py` with the same proportions.
- **Preview locally:** `python -m http.server 8124 --directory site` (the `site` entry in `.claude/launch.json`). Opening the file directly breaks the relative logo path in some viewers.

## README

`README.md` mirrors YouPipe Music's: logo, badges (release, downloads, platform, Flutter), the GitHub and website buttons, a screenshot table from `assets/screenshots/`, features, download, privacy, support links, credits, a collapsed developer section and the disclaimer. Keep its feature list in step with the website's.
