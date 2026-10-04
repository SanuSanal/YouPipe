# Remote config

`config/remote.json` on the `main` branch lets some fixes ship without an app release.

- **When it's read:** the app fetches it from `raw.githubusercontent.com` at most every 12 hours. The last copy is cached in prefs and applied at startup, so it works offline too (`lib/features/remote_config.dart`).
- **Fields (schema 1):**

  | Field | Effect |
  |---|---|
  | `webClientVersion` | Replaces the built-in WEB `clientVersion`. Only well-formed values (`2.YYYYMMDD.NN.NN`) are applied |

- **When YouTube starts rejecting requests:**
  1. Read `INNERTUBE_CLIENT_VERSION` from youtube.com's page source.
  2. Put it in `config/remote.json` on `main`.
  3. Update `YouTubeClient.web` in the next release too.
- **Stream breakage** is fixed by bumping NewPipeExtractor, which needs a release.
