# AGENTS.md

YouPipe: a Flutter (Android) YouTube client. It copies the YouTube Android UI and uses our own branding (the cylinder-in-a-screen logo). It's the sibling of YouPipe Music (`D:\claude\YouPipe Music`, repo SanuSanal/YouPipe-Music), and reuses that app's approach:
- browse, search, comments and account calls go through a pure-Dart InnerTube client (the `WEB` client on www.youtube.com);
- streams, captions, storyboards and chapters come from NewPipeExtractor.

## Before planning or changing code

1. Read `docs/README.md`, then the doc for every area your task touches. At minimum, read `docs/architecture.md`. `PLAN.md` holds the overall plan and the open decisions.
2. Respect the decisions recorded in the docs. Don't reverse one silently. If a task needs to change one, say so to the user and update the doc.

Decisions that are easy to break by accident:

- **No YouTube.js or other JS client.** Browse, search and account stay in `lib/innertube/` (pure Dart).
- **Stream URLs come from NewPipeExtractor** through the Kotlin channel. InnerTube `/player` URLs stop at about 1 MB without a PO token.
- **Each stream source has its own User-Agent.** The DASH streams and the muxed stream can come from different InnerTube clients, and a URL only plays with its own client's User-Agent (docs/streaming.md).
- **Comments are parsed in Dart** (`parseComments`); NewPipeExtractor v0.26.5 misses comment avatars (docs/innertube.md).
- **Optional features register through hooks** in `lib/features.dart`; core screens don't import them (docs/architecture.md).
- **The UI must match YouTube Android**, with YouPipe branding. Never ship YouTube logos or YouTube Sans.

## After making changes

- **Update the docs in the same change** when you alter architecture, a decision, an endpoint or parser behaviour, or the status in `docs/roadmap.md`. Any added, removed or changed network call or platform channel also goes in `docs/apis.md`.
- **Keep docs modular:** edit the relevant `docs/*.md`, or add a new module (linked from `docs/README.md`).

## Working rules

- **Verification:**
  - `flutter analyze` must report no issues.
  - Run `flutter test`, and run `flutter test --tags live --run-skipped` when InnerTube code changes.
  - Format with `dart format -l 120`.
- **On the device:** use the SDK adb (`%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`), not the "Minimal ADB" on PATH. See `docs/testing.md`.
- **Secrets and personal data:**
  - Never commit cookies, signed-in responses or personal data. Fixtures must have `ip=` and visitorData scrubbed.
  - Never type Google credentials; the user signs in themselves.
- **Git:** commit only when asked. End commit messages with the attribution line the environment provides.
