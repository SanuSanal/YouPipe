# UI

## Product rule: look like YouTube Android, with YouPipe branding

- **Match YouTube Android:** screens, layouts, interactions and wording follow the YouTube Android app (2025–26). When in doubt, match YouTube.
- **Branding:**
  - The mark is a red rounded "screen" with the YouPipe Music white cylinder inside (`assets/branding/logo.svg`).
  - The wordmark is the mark plus "YouPipe" in Roboto Bold (`Wordmark` widget).
  - The Shorts glyph is our own: a phone-shaped outline with a play triangle (`ShortsIcon`), not YouTube's mark.
  - **Never ship** YouTube logos, YouTube's Shorts icon or YouTube Sans. Use Roboto and Material Symbols (`material_symbols_icons`, outlined, weight 300; `fill: 1` for selected).
- **App name:** "YouPipe", applicationId `com.youpipe.app`.
- **Icons:**
  - Adaptive launcher icon: white background with the red mark (`logo_foreground.svg`), plus a monochrome themed icon (`logo_monochrome.svg`, pipe cut out).
  - Splash: the mark on white, or on `#0F0F0F` in dark mode.
  - Notification icon: `res/drawable/ic_stat_youpipe.xml`.
- **Regenerating:**
  1. Render the SVGs with ImageMagick: `magick -background none -density 512 x.svg -resize 1024x1024 x_1024.png`.
  2. Run `dart run flutter_launcher_icons`.
  3. Run `dart run flutter_native_splash:create`.

## Theme (`lib/ui/theme/yt_theme.dart`)

Both themes follow the device setting by default (Settings → Appearance). Read the tokens with `context.yt`.

| Token | Dark | Light |
|---|---|---|
| background | `#0F0F0F` | `#FFFFFF` |
| raised (sheets, panels) | `#212121` | `#FFFFFF` |
| chip / pill | `#272727` | `#F2F2F2` |
| chipSelected / onChipSelected | `#F1F1F1` / `#0F0F0F` | `#0F0F0F` / `#FFFFFF` |
| textPrimary / textSecondary | `#F1F1F1` / `#AAAAAA` | `#0F0F0F` / `#606060` |
| link | `#3EA6FF` | `#065FD4` |
| subscribe / onSubscribe | `#F1F1F1` / `#0F0F0F` | `#0F0F0F` / `#FFFFFF` |
| progress (seek bar, watched bar) | `#FF0033` | `#FF0033` |

**Sizes (`YtSizes`):**
- top bar 48, nav bar 48 (+ inset), mini player 55% of the width (16:9, radius 12, margin 8);
- chip 32 high, radius 8; pill 36 high, stadium;
- feed avatar 36; row thumbnail 160 wide, radius 8; sheets radius 12.

**Type (`YtText`):**
- feed title 15/w400;
- row title 14;
- meta 12, secondary colour;
- watch title 18/w700;
- section title 20/w700.

**Toasts** use `showSnack` (in a widget, 3 s) or `showGlobalSnack` (outside one, 4 s). Both set `persist: false`: Flutter otherwise keeps a toast with an action (Undo, View) on screen until it's tapped, which left the SponsorBlock "Skipped…" toast up for good.

## Screens

- **Shell (`lib/ui/shell/app_shell.dart`):**
  - **Bottom nav:** Home · Shorts · Subscriptions · You, with filled icons for the selected tab. Each tab is a go_router `StatefulShellBranch`, and detail pages push inside the tab.
  - **Watch panel:** one `AnimationController` (0 = mini player, 1 = watch page) morphs the video's rect between the mini player and the full player.
    - **The mini player** is YouTube's floating one: a 16:9 card with rounded corners (12), 55% of the screen width, 8 above the nav bar in the bottom-right corner. It floats over the page (the page reserves no space for it) and has a red progress line along its bottom.
    - A tap on the card shows its controls for 3 s: expand (top left), close (top right), and previous · play/pause · next. A tap on the shown controls opens the watch page.
    - **Room at the end of pages:** while the card shows, the shell sets the pages' bottom padding to its height plus margins, so plain lists end above it and sliver pages end with `SliverBottomInset`. The last item (Settings on You, say) can always scroll clear of the card.
    - **Swipe up** on the card expands it (it follows the finger); **swipe down** closes it (it slides down and fades, then playback stops); **drag sideways** moves it between the bottom-left and bottom-right corners.
    - Drag the expanded video down to minimise; swipe it up to go fullscreen. In fullscreen, swipe down to leave.
    - One keyed `GestureDetector` wraps the video at every size, so a drag survives the switch between the mini card, the morphing video and `PlayerView`.
    - The nav bar slides away as it expands. The status bar over the expanded player is black.
    - The mini player is hidden on the Shorts tab.
  - **Fullscreen** switches to landscape (phones and tablets; never on a TV) and immersive mode.
  - **PiP** shows only the video.
  - **Back order:** fullscreen → open panel (description/comments/queue) → expanded player → pages → Home → exit.
  - **Android 16's predictive back** asks the app up front whether it will handle Back. The shell's `PopScope` claims it whenever fullscreen, the expanded player or another tab is showing; otherwise Back would close the app instead of reaching the `BackButtonListener` (found on the Android 16 TV emulator, 2026-10-04).

## Tablets and TVs (`lib/ui/layout.dart`)

- **Form factor:**
  - TV comes from the platform: `youpipe/system` → `device` (television UI mode or the leanback feature; Fire TV too), read once in `main.dart` as `DeviceInfo.current`.
  - Tablet means a shortest side of at least 600 dp; everything else is a phone.
- **Orientation:** phones stay portrait (fullscreen turns to landscape), tablets rotate freely, TVs are left alone (`appOrientations`).
- **Feed grids:**
  - `feedColumns`: 1 below 600 dp, 2 below 900, 3 below 1200, then 4. TVs always get 4 across: they report very different widths in dp, and at 6 the thumbnails were too small from the sofa (2026-10-04).
  - `VideoGridSliver` lays videos out (on phones, today's full-width cards); `VideosWithShortsSliver` puts the Shorts shelf after the first grid row (Home, Subscriptions); `FeedSliver` turns search results and channel tabs into grids with Shorts, shelves and rows between (`feedRuns`).
  - Grid cards (`VideoCard(grid: true)`) have rounded thumbnails decoded at their cell size.
  - Channel and playlist rows in feeds, and row pages (playlist, history, downloads, settings, search suggestions, subscriptions), stay within 840 dp (`MaxContentWidth`).
  - The Shorts grids use a max cell width, so phones keep 2 and 3 across.
- **Wide screens** (`isWide`: landscape and at least 900 dp, so landscape tablets and TVs):
  - A **side rail** (`_SideNav`, 72 dp) replaces the bottom bar and slides out as the player expands.
  - The **watch page** has two columns: the video (64% of the width) with the details under it, and the related list as compact rows on the right. The Description, Comments and Queue panels open in the right column instead of over the details.
  - **Shorts** play in a centred 9:16 column instead of a cropped band.
- **The mini player** is capped at 360 dp wide.
- **TV top bar:** the search box comes first, on the left (a field-like pill, "Search"; Select opens the search page and its keyboard), and the wordmark or page title sits on the right (`YtTopBar`).

## The TV remote (and keyboards)

- **Focus ring:** `FocusHighlight` draws a rounded ring just outside a widget while it or something inside it has focus, so it shows on any colour (a white chip too). It's on cards, rows, chips, pills, nav items, Shorts buttons, the mini player, the watch page's title, channel, comments and chapters. Focused icon buttons get an outline from the theme (`iconButtonTheme`), and list rows a tint (`focusColor`).
- **When it shows:** only after key input (`FocusHighlightMode.traditional`), so touch users never see it. TVs always show it (`FocusHighlightStrategy.alwaysTraditional`).
- **Starting focus:** on a TV the rail's selected item takes focus whenever no widget has it (at launch, on a tab change, after the watch page closes).
- **Reaching the rail:** each tab's pages are their own focus scope, which arrow keys don't leave, so the shell turns a Left that can't move any further into focusing the rail (`_leftToRail`).
- **Under the watch page** the tabs and the rail are excluded from focus, so the remote can't move behind it.
- **Player** (`PlayerView._onKey`):
  - With the controls hidden, the player itself has focus. Select shows the controls with play/pause focused; Left/Right seek 10 s (with the ripple); Up shows the controls; Down moves on to the details (or shows the controls in fullscreen).
  - Media keys (play/pause, play, pause, fast-forward, rewind) always work.
  - Hidden controls are excluded from focus; when they hide, focus goes back to the player.
  - The seek bar takes focus: Left/Right move the storyboard preview 10 s, releasing the key seeks.
  - The Autoplay switch is in the top row with CC and Settings; at the end of a video the Up next card's Play now has focus.
- **On a TV, a picked video opens fullscreen**, like YouTube for TV; Back shows the watch page, Back again the mini player.
- **Shorts:** Up/Down change Short and Select pauses while the video has focus; Left reaches the side buttons (or the rail); the buttons, channel and Subscribe are focusable.
- **Not on a TV:** Cast (the TV is the big screen) and PiP (most TVs and Fire TV have none; `MainActivity` won't arm it without the feature).
- **Known gaps:**
  - links inside descriptions and comments stay touch-only;
  - the small history and shelf cards have no ⋮ (their rows are too short), so their menu is long-press only; the video's own page has the same actions;
  - there's no pull-to-refresh with a remote (Home refreshes at launch);
  - playlists can't be reordered with a remote.
- **Home:**
  - The top bar floats: wordmark, Cast, search. Once it has floated away, `StatusBarScrim` keeps the status bar strip filled with the page background (Home, Subscriptions, You), so the feed doesn't scroll visibly under the clock.
  - A floating chip bar.
  - Full-width feed cards: edge-to-edge 16:9 thumbnail with a duration/LIVE badge and a red watched bar, then avatar, title, `channel · views · age`, and ⋮.
  - A Shorts shelf after the second video, a first-run card, pull-to-refresh, and infinite scroll.
- **Watch page:**
  - The player, then the title, then `views  age  ...more` (opens the Description panel).
  - The channel row with Subscribe.
  - Pills: like | dislike (Return YouTube Dislike), Share, Download (with progress), Save, Watch later.
  - The comments card (opens the Comments panel, with Top/Newest chips), the Queue card, and related cards.
  - **Panels open under the player** (the player keeps playing), as in YouTube.
- **Player controls (`player_view.dart`):**
  - Tap to show; they auto-hide after 3 s.
  - Minimise chevron, CC, Cast, settings.
  - Previous / play / next.
  - Time, fullscreen, and the seek bar: red, buffered range, chapter gaps, SponsorBlock colours, and a storyboard preview with time and chapter while dragging.
  - Double-tap ±10 s with a ripple; hold for 2× speed.
  - **Settings sheet:** Quality, Playback speed, Captions, Loop, Sleep timer.
- **Shorts:**
  - A vertical pager, black, with the right rail: like, dislike, comments, share, ⋮.
  - Channel and Subscribe at the bottom left, the title, and a thin white progress bar.
  - Tap to pause; the neighbours preload.
- **Search:**
  - A rounded grey field; history rows with a clock icon (long-press to remove) and suggestions with ↖ to fill.
  - **Results:** feed cards, channel rows with Subscribe, and Shorts and titled shelves. The filter sheet uses YouTube's own groups.
- **Channel:**
  - Banner (rounded), avatar 72, name, handle · subscribers · videos, an About sheet, and full-width Subscribe.
  - Scrollable tabs (Home shelves, Videos/Shorts/Live with Latest/Popular/Oldest chips, Releases, Playlists, Podcasts).
  - Shorts show in a 3-column grid.
- **Playlist** (YouTube and local):
  - A thumbnail-tinted header with the big thumbnail, title, owner and metadata.
  - White "Play all" and grey "Shuffle" pills, plus save and share.
  - Rows with ⋮. Your own playlists and Watch later can be reordered by dragging.
  - **Subscribed** asks "Unsubscribe from <channel>?" before unsubscribing, like YouTube (it reaches the account when signed in).
  - Your own playlists have ⋮ → Rename and Delete playlist; deleting asks first ("Delete playlist?"), like YouTube.
- **Subscriptions:**
  - A strip of channel avatars plus "All".
  - Chips: All, Today, Videos, Shorts, Continue watching, Unwatched.
  - The feed with a Shorts shelf. The empty state invites you to find channels.
- **You:**
  - The account header (or the optional sign-in), a History carousel, and Playlists (Liked videos, Watch later, yours, saved).
  - Downloads, Your subscriptions, History, Settings.
- **Settings:**
  - General (appearance, language, location, PiP).
  - Playback (resume where you left off). Autoplay is switched in the player, like YouTube.
  - Video quality preferences (YouTube's three).
  - SponsorBlock, Updates, history controls, About (diagnostics, licences).
