# InnerTube (WEB client)

Request format and endpoints are listed in [apis.md](apis.md). This page covers the response shapes and how `lib/innertube/parsers.dart` reads them.

## Renderer families

youtube.com is midway through replacing `*Renderer` items with `*ViewModel` items, and one response can mix both. As of 2026-10-03:

| Response | Video items | Other |
|---|---|---|
| Search | `videoRenderer`; Shorts shelf of `shortsLockupViewModel` | `channelRenderer`, `playlistRenderer` (or `lockupViewModel` with a playlist content type). Searching a channel's name returns **`officialCardViewModel`** first: a `pageHeaderViewModel` (name, avatar in `contentPreviewImageViewModel`, rows `[@handle] [subscribers, videos]`) plus a `horizontalShelfViewModel` of the channel's video lockups. It's parsed as a channel card followed by an untitled horizontal shelf |
| Next (related) | `lockupViewModel` (`contentType: LOCKUP_CONTENT_TYPE_VIDEO`) | |
| Account lists | `FEchannels`: `itemSectionRenderer` → `shelfRenderer` → `expandedShelfContentsRenderer` of `channelRenderer`s (none at all when the account has no subscriptions; then only a sort chip menu). `guide`: `guideSubscriptionsSectionRenderer` of `guideEntryRenderer`s, folded ones under `guideCollapsibleEntryRenderer` (`parseGuideSubscriptions`). Watch later / Liked videos: `playlistHeaderRenderer` | |
| Channel | `lockupViewModel`, `shortsLockupViewModel`. Playlists tab: lockups of content type `PLAYLIST` or `SHOW` (a series; its id is a `PL…` playlist), whose rows hold only labels ("Playlist", "View full playlist"), so they have no owner | Header: `pageHeaderRenderer.content.pageHeaderViewModel`; tabs: `twoColumnBrowseResultsRenderer.tabs[].tabRenderer` |
| Shorts sequence | none; `entries[].command.reelWatchEndpoint.videoId` only | Metadata comes from the Short's video info |

## How the parsers work

- **`parseItems(root)`** walks the tree in document order. Each known item key (`videoRenderer`, `gridVideoRenderer`, `compactVideoRenderer`, `lockupViewModel`, `shortsLockupViewModel`, `reelItemRenderer`, `channelRenderer`, `playlistRenderer`) gets parsed, and the walk doesn't descend into it. Duplicates are dropped.
- **Big branches that never hold items are skipped:** `frameworkUpdates`, `topbar`, `engagementPanels`, `overlay`, `microformat`, `playerOverlays`, `menu`, `sheetViewModel`.
- **`findContinuation(root)`** returns the first `continuationItemRenderer` token, from `continuationEndpoint` or `button.buttonRenderer.command`.
- **Continuation responses** put their items under `onResponseReceivedCommands` (search), `onResponseReceivedEndpoints` (next) or `onResponseReceivedActions` (browse). `parseList` checks all of them.

## Comments (`parseComments`)

- **First page:** `next(videoId)`, then the `itemSectionRenderer` with `sectionIdentifier: comment-item-section`, then its continuation token, then `next(continuation)`.
- **Response shape:**
  - `onResponseReceivedEndpoints[].reloadContinuationItemsCommand` holds a `commentsHeaderRenderer` (`countText`, and `sortMenu` with Top/Newest tokens) and the `commentThreadRenderer`s.
  - Later pages use `appendContinuationItemsAction`.
- **Where the data is:**
  - Each thread's `commentViewModel` only holds keys (`commentKey`, `toolbarStateKey`). The data is in `frameworkUpdates.entityBatchUpdate.mutations`.
  - `commentEntityPayload` holds `properties` (`commentId`, `content.content`, `publishedTime`), `author` (`displayName`, **`avatarThumbnailUrl`**, `channelId`, `isVerified`, `isCreator`) and `toolbar` (`likeCountNotliked`, `replyCount`).
  - `engagementToolbarStateEntityPayload` has `heartState`. `pinnedText` is on the view model.
- **Replies:** the thread's `replies.commentRepliesRenderer` continuation token, through the same parser.
- **Why not NewPipe:** this was planned to come from NewPipe, but NewPipeExtractor v0.26.5 reads `commentEntityPayload.avatar`, which YouTube no longer fills, so every avatar was missing.

## Playlists, channels, search filters

- **Playlist:**
  - The header is `pageHeaderViewModel`: title, owner from `avatarStack` ("by …"), metadata parts, and `heroImage`.
  - Items are `lockupViewModel`; the continuation is a **`continuationItemViewModel`** (`continuationCommand.innertubeCommand.continuationCommand.token`).
  - Continuation responses repeat an empty `contents`, so continuation parsers prefer `onResponseReceived*`.
- **Channel:**
  - Home tab shelves are `shelfRenderer`/`reelShelfRenderer` (as `ShelfEntry`), and the featured video is `channelVideoPlayerRenderer`.
  - Videos/Shorts/Live tabs carry `chipViewModel` sort chips whose `tapCommand` continuation re-sorts the list.
- **Search:**
  - Shelves are `gridShelfViewModel` (Shorts) and `shelfRenderer` ("Latest from …", "People also watched").
  - **Ads** (`adSlotRenderer` and friends) are in `_skip` and never parsed.
  - The filter sheet's `searchFilterGroupRenderer`s give each option's `params`, including the params that turn it off.

## `lockupViewModel` fields

| Field | Path |
|---|---|
| Video id | `contentId` |
| Title | `metadata.lockupMetadataViewModel.title.content` |
| Metadata parts | `metadata.lockupMetadataViewModel.metadata.contentMetadataViewModel.metadataRows[].metadataParts[].text.content`. The row layout differs between experiments, so each part is **classified by content**: "views"/"watching" or a bare count like `3.6M` → views; "ago"/"Streamed"/"Premiered" → age; anything else first → the channel. The patterns use word boundaries (``). A channel's own lockups (its Videos tab, the official card's row) have only `[views, age]`, so their channel is null and the card shows no avatar. Short ages ("3mo ago", "1y ago") are expanded to the long form (`longAge`) |
| Avatar | the first `avatarViewModel.image` under the metadata |
| Channel id | the first `browseEndpoint.browseId` starting with `UC` under `….image` |
| Duration / LIVE | badges in `contentImage.thumbnailViewModel.overlays[].thumbnailBottomOverlayViewModel.badges[].thumbnailBadgeViewModel.text` |
| Playlist | `contentImage.collectionThumbnailViewModel.primaryThumbnail.thumbnailViewModel` |

## Fixtures and tests

- **Fixtures:** `test/innertube/fixtures/*.json` are signed-out responses recorded on 2026-10-03 (home, search, next, channel, reel_seq). `ip=` values and `visitorData` are scrubbed.
- **Tests:** `test/innertube/parsers_test.dart` runs offline. `test/innertube/live_test.dart` is tagged `live`.
- **More fixtures:** comments, playlist, channel_videos, channel_playlists and search_channel (a search for "fireship" with an `officialCardViewModel`), all 2026-10-03.
- **Scrubbing:** besides `ip=` and `visitorData`, the `visitor_data` value in `responseContext.serviceTrackingParams` is replaced with `SCRUBBED`.
- **Recording from the phone:** debug builds save every InnerTube response to the app cache (`InnerTube.debugDump`). List them with `adb shell run-as com.youpipe.app ls cache/innertube` and fetch one with `adb exec-out run-as com.youpipe.app cat cache/innertube/<file>`. **Scrub `ip=` and `visitorData` before committing.**
- **Inspecting:** `dart run tool/inspect_feed.dart <file.json>` prints how the parsers read a response.
