# Google account (optional)

- **Sign-in:**
  - You → "Sign in (optional)" opens Google's own sign-in page in a WebView, continuing to youtube.com. The user types their credentials into Google's page.
  - When a youtube.com page loads, the app reads the session cookie through `youpipe/cookies` (CookieManager, since the auth cookies are HttpOnly).
  - The cookie is stored in `flutter_secure_storage` (`yt_cookie`).
  - **Never type credentials on the user's behalf** (AGENTS.md).
- **Requests:** `InnerTube` adds `Cookie`, `Authorization: SAPISIDHASH …` (origin `https://www.youtube.com`), `X-Goog-AuthUser: 0` and `X-Origin` while the cookie holds `SAPISID` or `__Secure-3PAPISID`.
- **What signing in adds:**
  - The account's YouTube recommendations, mixed into Home (`HomeMixer`, weight 3).
  - In the You tab: YouTube history (`FEhistory`), YouTube playlists (`FEplaylist_aggregation`), Watch later (`VLWL`), Liked videos (`VLLL`).
  - **Import subscriptions from your account:** `FEchannels`, all pages, into the local subscriptions.
  - **Sync:** likes, subscribe/unsubscribe and Watch later are mirrored to the account (`LibraryRepository.remoteSync`). This is best-effort; the local library stays the source of truth.
- **Sign out:** deletes the stored cookie and clears the WebView cookies. The local library stays.
- **Status (2026-10-04, with the user's account, every change undone afterwards):**
  - Sign-in, the account's Home, YouTube playlists, Liked videos and Watch later pages: work.
  - Like → the video appears in the account's Liked videos; unlike removes it. `like/like` answers with a `runAttestationCommand` but the like counts anyway.
  - Subscribe/unsubscribe and Watch later add/remove reach the account (`edit_playlist` answers `STATUS_SUCCEEDED`).
  - Import from the account: the subscribed channel came back. An account without subscriptions gets "Your YouTube account has no subscriptions".
  - The account's own lists use the older `playlistHeaderRenderer`, which `parsePlaylist` reads too (title, Private, video count, banner thumbnail).
