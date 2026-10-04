/// Renderer JSON → models.
///
/// youtube.com is midway through moving from the old `*Renderer` items to `*ViewModel` ones, and a single response
/// can mix both, so [parseItems] understands both families and collects items wherever they sit in the tree.
library;

import 'json_nav.dart';
import 'models.dart';

/// Branches that never hold feed items: large chrome, and every kind of ad (YouPipe never shows ads).
const _skip = {
  'frameworkUpdates',
  'topbar',
  'engagementPanels',
  'overlay',
  'microformat',
  'playerOverlays',
  'menu',
  'sheetViewModel',
  'adSlotRenderer',
  'promotedSparklesWebRenderer',
  'promotedVideoRenderer',
  'searchPyvRenderer',
  'statementBannerRenderer',
  'brandVideoShelfRenderer',
  'brandVideoSingletonRenderer',
};

typedef _ItemParser = YtItem? Function(Json);

const Map<String, _ItemParser> _parsers = {
  'videoRenderer': _video,
  'gridVideoRenderer': _video,
  'compactVideoRenderer': _video,
  'channelVideoPlayerRenderer': _video,
  'playlistVideoRenderer': _video,
  'lockupViewModel': _lockup,
  'shortsLockupViewModel': _shortsLockup,
  'reelItemRenderer': _reelItem,
  'channelRenderer': _channel,
  'gridChannelRenderer': _channel,
  'playlistRenderer': _playlist,
  'gridPlaylistRenderer': _playlist,
};

/// Every video, Short, channel and playlist under [root], in document order, without duplicates.
List<YtItem> parseItems(Object? root) {
  final out = <YtItem>[];
  final seen = <YtItem>{};
  void walk(Object? o) {
    if (o is Map) {
      for (final e in o.entries) {
        final parser = _parsers[e.key];
        if (parser != null) {
          final v = e.value;
          final item = v is Json ? parser(v) : null;
          if (item != null && seen.add(item)) out.add(item);
          continue;
        }
        if (_skip.contains(e.key)) continue;
        walk(e.value);
      }
    } else if (o is List) {
      for (final v in o) {
        walk(v);
      }
    }
  }

  walk(root);
  return out;
}

/// Titled groups inside a feed. Their items are kept together as a [ShelfEntry].
const _shelves = {
  'gridShelfViewModel',
  'reelShelfRenderer',
  'shelfRenderer',
  'richShelfRenderer',
  'horizontalCardListRenderer',
};

String? _shelfTitle(Json s) =>
    nav<String>(s, ['header', 'sectionHeaderViewModel', 'headline', 'content']) ??
    textOf(s['title']) ??
    textOf(nav(s, ['header', 'richListHeaderRenderer', 'title']));

/// Items and shelves under [root], in document order. Items already seen in an earlier entry are dropped.
List<FeedEntry> parseFeed(Object? root) {
  final out = <FeedEntry>[];
  final seen = <YtItem>{};
  void walk(Object? o) {
    if (o is Map) {
      for (final e in o.entries) {
        final v = e.value;
        // Searching a channel's name: its card, then a row of its videos.
        if (e.key == 'officialCardViewModel' && v is Json) {
          final channel = _officialCard(v);
          if (channel != null && seen.add(channel)) out.add(ItemEntry(channel));
          final items = parseItems(v['contents']).where(seen.add).toList();
          if (items.isNotEmpty) out.add(ShelfEntry('', items));
          continue;
        }
        if (_shelves.contains(e.key) && v is Json) {
          final items = parseItems(v).where(seen.add).toList();
          if (items.isNotEmpty) {
            final shorts = items.every((i) => i is VideoItem && i.isShort);
            out.add(ShelfEntry(_shelfTitle(v) ?? (shorts ? 'Shorts' : ''), items, shorts: shorts));
          }
          continue;
        }
        final parser = _parsers[e.key];
        if (parser != null) {
          final item = v is Json ? parser(v) : null;
          if (item != null && seen.add(item)) out.add(ItemEntry(item));
          continue;
        }
        if (_skip.contains(e.key)) continue;
        walk(v);
      }
    } else if (o is List) {
      for (final v in o) {
        walk(v);
      }
    }
  }

  walk(root);
  return out;
}

/// The subscribed channels in the web sidebar (`guide`): `guideEntryRenderer`s that browse to a `UC…` id, including
/// the ones folded under "Show more" (`guideCollapsibleEntryRenderer`).
List<ChannelItem> parseGuideSubscriptions(Json data) {
  final out = <String, ChannelItem>{};
  void walk(Object? o) {
    if (o is Map) {
      final entry = o['guideEntryRenderer'];
      if (entry is Json) {
        final id = nav<String>(entry, ['navigationEndpoint', 'browseEndpoint', 'browseId']);
        final name = textOf(entry['formattedTitle']) ?? textOf(entry['title']);
        if (id != null && id.startsWith('UC') && name != null) {
          out[id] = ChannelItem(id: id, name: name, avatar: _bestImage(entry['thumbnail']));
        }
      }
      for (final v in o.values) {
        walk(v);
      }
    } else if (o is List) {
      for (final v in o) {
        walk(v);
      }
    }
  }

  for (final section in navList(data, ['items'])) {
    if (section.containsKey('guideSubscriptionsSectionRenderer')) walk(section);
  }
  return out.values.toList();
}

/// The token of the first continuation item under [root] (the "load more" at the end of a list).
String? findContinuation(Object? root) {
  String? found;
  void walk(Object? o) {
    if (found != null) return;
    if (o is Map) {
      final c = o['continuationItemRenderer'];
      if (c is Json) {
        found =
            nav<String>(c, ['continuationEndpoint', 'continuationCommand', 'token']) ??
            nav<String>(c, ['button', 'buttonRenderer', 'command', 'continuationCommand', 'token']);
        if (found != null) return;
      }
      final vm = o['continuationItemViewModel'];
      if (vm is Json) {
        found = nav<String>(vm, ['continuationCommand', 'innertubeCommand', 'continuationCommand', 'token']);
        if (found != null) return;
      }
      for (final e in o.entries) {
        if (_skip.contains(e.key)) continue;
        walk(e.value);
      }
    } else if (o is List) {
      for (final v in o) {
        walk(v);
      }
    }
  }

  walk(root);
  return found;
}

String? _https(String? url) => url == null ? null : (url.startsWith('//') ? 'https:$url' : url);

/// The largest of `{thumbnails: [{url, width}]}` or `{sources: [{url, width}]}`.
String? _bestImage(Object? node) {
  final list = navList(node, ['thumbnails']).isNotEmpty ? navList(node, ['thumbnails']) : navList(node, ['sources']);
  if (list.isEmpty) return null;
  final best = list.reduce((a, b) => ((a['width'] as num?) ?? 0) >= ((b['width'] as num?) ?? 0) ? a : b);
  return _https(best['url'] as String?);
}

/// The first channel id (`UC…`) a `browseEndpoint` under [node] points to.
String? _channelIdIn(Object? node) {
  if (node is Map) {
    final id = nav<String>(node, ['browseEndpoint', 'browseId']);
    if (id != null && id.startsWith('UC')) return id;
    for (final v in node.values) {
      final found = _channelIdIn(v);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final v in node) {
      final found = _channelIdIn(v);
      if (found != null) return found;
    }
  }
  return null;
}

YtItem? _video(Json v) {
  final id = v['videoId'] as String?;
  final title = textOf(v['title']) ?? textOf(v['headline']);
  if (id == null || title == null) return null;
  final byline = v['longBylineText'] ?? v['ownerText'] ?? v['shortBylineText'];
  final length = textOf(v['lengthText']);
  final views = textOf(v['shortViewCountText']) ?? textOf(v['viewCountText']);
  final live =
      length == null &&
      (views?.contains('watching') == true ||
          navList(v, [
            'badges',
          ]).any((b) => nav<String>(b, ['metadataBadgeRenderer', 'style']) == 'BADGE_STYLE_TYPE_LIVE_NOW'));
  // Playlist rows put "views • age" in videoInfo.
  final info = runsOf(v['videoInfo']).map((r) => r['text'] as String? ?? '').where((t) => t.trim().length > 1);
  return VideoItem(
    id: id,
    title: title,
    channelName: textOf(byline),
    channelId: _channelIdIn(byline),
    channelAvatar: _bestImage(
      nav(v, ['channelThumbnailSupportedRenderers', 'channelThumbnailWithLinkRenderer', 'thumbnail']) ??
          nav(v, ['channelThumbnail']),
    ),
    thumbnail: _bestImage(v['thumbnail']) ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
    durationText: length,
    viewsText: views ?? info.firstOrNull,
    publishedText: textOf(v['publishedTimeText']) ?? (info.length > 1 ? info.last : null),
    isLive: live,
  );
}

YtItem? _lockup(Json v) {
  final id = v['contentId'] as String?;
  final meta = nav<Json>(v, ['metadata', 'lockupMetadataViewModel']);
  final title = nav<String>(meta, ['title', 'content']);
  if (id == null || title == null) return null;
  final rows = navList(meta, ['metadata', 'contentMetadataViewModel', 'metadataRows'])
      .map((r) => navList(r, ['metadataParts']).map((p) => nav<String>(p, ['text', 'content'])).nonNulls.toList())
      .where((r) => r.isNotEmpty)
      .toList();
  final type = v['contentType'] as String?;
  if (type == 'LOCKUP_CONTENT_TYPE_PLAYLIST' ||
      type == 'LOCKUP_CONTENT_TYPE_PODCAST' ||
      type == 'LOCKUP_CONTENT_TYPE_SHOW') {
    final image = nav(v, ['contentImage', 'collectionThumbnailViewModel', 'primaryThumbnail', 'thumbnailViewModel']);
    return PlaylistItem(
      id: id,
      title: title,
      thumbnail: _bestImage(nav(image, ['image'])),
      // A channel's own playlists have only labels ("Playlist", "View full playlist"), no owner.
      channelName: rows.expand((r) => r).where((t) => !_playlistLabel.hasMatch(t)).firstOrNull,
      countText: _badgeTexts(image).firstOrNull,
    );
  }
  if (type != null && type != 'LOCKUP_CONTENT_TYPE_VIDEO') return null;
  final image = nav(v, ['contentImage', 'thumbnailViewModel']);
  final badges = _badgeTexts(image);
  final duration = badges.where((b) => RegExp(r'^\d+(:\d\d)+$').hasMatch(b)).firstOrNull;
  // The rows' layout varies between experiments ([channel] [views, age], or [channel, views] …), so each part is
  // classified by what it says rather than where it sits.
  String? channel;
  String? views;
  String? age;
  for (final part in rows.expand((r) => r)) {
    final t = part.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    if (views == null && _viewsPattern.hasMatch(t)) {
      views = t;
    } else if (views == null && _bareCount.hasMatch(t)) {
      // Related videos show "3.6M" next to a play icon.
      views = '$t views';
    } else if (age == null && _agePattern.hasMatch(t)) {
      age = longAge(t);
    } else {
      channel ??= t;
    }
  }
  final avatar = _findAvatar(meta);
  return VideoItem(
    id: id,
    title: title,
    channelName: channel,
    channelId: _channelIdIn(meta),
    channelAvatar: avatar,
    thumbnail: _bestImage(nav(image, ['image'])),
    durationText: duration,
    viewsText: views,
    publishedText: age,
    isLive: duration == null && badges.any((b) => b.toUpperCase() == 'LIVE'),
  );
}

final _viewsPattern = RegExp(r'\b(views?|watching|No views)\b', caseSensitive: false);

/// YouTube's short ages ("3mo ago", "1y ago", "5d ago") in the long form the rest of the app uses ("3 months ago").
String longAge(String text) => text.replaceAllMapped(_shortAge, (m) {
  final n = int.parse(m[1]!);
  final unit = _shortUnits[m[2]!]!;
  return '$n $unit${n == 1 ? '' : 's'} ago';
});

final _shortAge = RegExp(r'\b(\d+)\s?(mo|y|w|d|h|min|m|s) ago\b');
const _shortUnits = {
  'y': 'year',
  'mo': 'month',
  'w': 'week',
  'd': 'day',
  'h': 'hour',
  'min': 'minute',
  'm': 'minute',
  's': 'second',
};

final _playlistLabel = RegExp(r'^(Playlist|Podcast|Mix|Course|View full playlist|Updated .*)$', caseSensitive: false);
final _bareCount = RegExp(r'^[\d.,]+[KMB]?$');
final _agePattern = RegExp(r'\b(ago|Streamed|Premiered|Scheduled)\b', caseSensitive: false);

/// The first `avatarViewModel` picture under [node].
String? _findAvatar(Object? node) {
  if (node is Map) {
    final a = node['avatarViewModel'];
    if (a is Json) return _bestImage(a['image']);
    for (final v in node.values) {
      final found = _findAvatar(v);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final v in node) {
      final found = _findAvatar(v);
      if (found != null) return found;
    }
  }
  return null;
}

/// The texts of the badges drawn over a lockup's thumbnail (duration, "LIVE", "12 videos").
List<String> _badgeTexts(Object? thumbnailViewModel) => [
  for (final o in navList(thumbnailViewModel, ['overlays']))
    for (final b in [
      ...navList(o, ['thumbnailBottomOverlayViewModel', 'badges']),
      ...navList(o, ['thumbnailOverlayBadgeViewModel', 'thumbnailBadges']),
    ])
      ?nav<String>(b, ['thumbnailBadgeViewModel', 'text']),
];

YtItem? _shortsLockup(Json v) {
  final reel = nav<Json>(v, ['onTap', 'innertubeCommand', 'reelWatchEndpoint']);
  final id = nav<String>(reel, ['videoId']);
  if (id == null) return null;
  return VideoItem(
    id: id,
    title: nav<String>(v, ['overlayMetadata', 'primaryText', 'content']) ?? '',
    viewsText: nav<String>(v, ['overlayMetadata', 'secondaryText', 'content']),
    thumbnail: _bestImage(nav(v, ['thumbnail'])) ?? _bestImage(nav(reel, ['thumbnail'])),
    isShort: true,
  );
}

YtItem? _reelItem(Json v) {
  final id = v['videoId'] as String?;
  if (id == null) return null;
  return VideoItem(
    id: id,
    title: textOf(v['headline']) ?? '',
    viewsText: textOf(v['viewCountText']),
    thumbnail: _bestImage(v['thumbnail']),
    isShort: true,
  );
}

YtItem? _channel(Json v) {
  final id = v['channelId'] as String?;
  final name = textOf(v['title']);
  if (id == null || name == null) return null;
  final handle = textOf(v['subscriberCountText']);
  return ChannelItem(
    id: id,
    name: name,
    avatar: _bestImage(v['thumbnail']),
    // YouTube puts the @handle in subscriberCountText and the subscriber count in videoCountText.
    subscribersText: [?handle, ?textOf(v['videoCountText'])].join(' • '),
  );
}

YtItem? _playlist(Json v) {
  final id = v['playlistId'] as String?;
  final title = textOf(v['title']);
  if (id == null || title == null) return null;
  return PlaylistItem(
    id: id,
    title: title,
    thumbnail: _bestImage(navList(v, ['thumbnails']).firstOrNull) ?? _bestImage(v['thumbnail']),
    channelName: textOf(v['longBylineText'] ?? v['shortBylineText']),
    countText: v['videoCount'] as String? ?? textOf(v['videoCountText']),
  );
}

// Pages --------------------------------------------------------------------------------------------------------

HomeFeed parseHome(Json data) => HomeFeed(
  parseItems(data['contents']),
  findContinuation(data['contents']),
  nudge: _findTitle(data['contents'], 'feedNudgeRenderer'),
);

String? _findTitle(Object? root, String renderer) {
  if (root is Map) {
    final r = root[renderer];
    if (r is Json) return textOf(r['title']);
    for (final v in root.values) {
      final t = _findTitle(v, renderer);
      if (t != null) return t;
    }
  } else if (root is List) {
    for (final v in root) {
      final t = _findTitle(v, renderer);
      if (t != null) return t;
    }
  }
  return null;
}

/// The root holding a page's items.
Object? _itemsRoot(Json data) => data['contents'] ?? _continuationRoot(data);

/// The root holding a continuation's items. Some continuations (playlists) repeat an empty `contents` too.
Object? _continuationRoot(Json data) =>
    data['onResponseReceivedActions'] ??
    data['onResponseReceivedCommands'] ??
    data['onResponseReceivedEndpoints'] ??
    data['continuationContents'] ??
    data['contents'];

/// Any continuation response (search, browse or next) as flat items.
Paged<YtItem> parseList(Json data) {
  final root = _continuationRoot(data);
  return Paged(parseItems(root), findContinuation(root));
}

/// Any response as entries (items and shelves).
FeedPage parseFeedPage(Json data) {
  final root = _continuationRoot(data);
  return FeedPage(parseFeed(root), findContinuation(root));
}

SearchPage parseSearch(Json data) {
  final root = _itemsRoot(data);
  final groups = <SearchFilterGroup>[];
  void walk(Object? o) {
    if (o is Map) {
      final g = o['searchFilterGroupRenderer'];
      if (g is Json) {
        groups.add(
          SearchFilterGroup(textOf(g['title']) ?? '', [
            for (final f in navList(g, ['filters']))
              if (nav<Json>(f, ['searchFilterRenderer']) case final r?)
                SearchFilterOption(
                  textOf(r['label']) ?? '',
                  nav<String>(r, ['navigationEndpoint', 'searchEndpoint', 'params']),
                  selected: r['status'] == 'FILTER_STATUS_SELECTED',
                ),
          ]),
        );
        return;
      }
      o.values.forEach(walk);
    } else if (o is List) {
      o.forEach(walk);
    }
  }

  walk(data);
  return SearchPage(parseFeed(root), findContinuation(root), filters: groups);
}

/// The watch page's related videos (the comments live in the main column and come from NewPipe instead).
Paged<YtItem> parseNextRelated(Json data) {
  final secondary = nav(data, ['contents', 'twoColumnWatchNextResults', 'secondaryResults']);
  return Paged(parseItems(secondary), findContinuation(secondary));
}

List<String> _metadataParts(Object? viewModel) => navList(viewModel, [
  'metadata',
  'contentMetadataViewModel',
  'metadataRows',
]).expand((r) => navList(r, ['metadataParts'])).map((p) => nav<String>(p, ['text', 'content'])).nonNulls.toList();

ChannelItem? _officialCard(Json v) {
  final header = nav<Json>(v, ['header', 'pageHeaderViewModel']);
  final name = nav<String>(header, ['title', 'dynamicTextViewModel', 'text', 'content']);
  final id = _channelIdIn(header);
  if (name == null || id == null) return null;
  return ChannelItem(
    id: id,
    name: name,
    avatar: _bestImage(nav(header, ['image', 'contentPreviewImageViewModel', 'image'])),
    // Rows: [@handle] [subscribers, videos].
    subscribersText: _metadataParts(header).where((p) => !p.contains('video')).join(' • '),
  );
}

ChannelPage parseChannel(Json data, String id) {
  final header = nav<Json>(data, ['header', 'pageHeaderRenderer']);
  final view = nav<Json>(header, ['content', 'pageHeaderViewModel']);
  final parts = _metadataParts(view);
  final tabs = <ChannelTab>[];
  Object? selectedContent;
  for (final t in navList(data, ['contents', 'twoColumnBrowseResultsRenderer', 'tabs'])) {
    final tab = nav<Json>(t, ['tabRenderer']);
    final title = nav<String>(tab, ['title']);
    if (tab == null || title == null) continue;
    final selected = tab['selected'] == true;
    tabs.add(ChannelTab(title, nav<String>(tab, ['endpoint', 'browseEndpoint', 'params']), selected: selected));
    if (selected) selectedContent = tab['content'];
  }
  return ChannelPage(
    id: id,
    name:
        nav<String>(header, ['pageTitle']) ?? nav<String>(data, ['metadata', 'channelMetadataRenderer', 'title']) ?? '',
    avatar: _bestImage(nav(view, ['image', 'decoratedAvatarViewModel', 'avatar', 'avatarViewModel', 'image'])),
    banner: _bestImage(nav(view, ['banner', 'imageBannerViewModel', 'image'])),
    handle: parts.where((r) => r.startsWith('@')).firstOrNull,
    metadata: parts.where((r) => !r.startsWith('@')).toList(),
    description:
        nav<String>(view, ['description', 'descriptionPreviewViewModel', 'description', 'content']) ??
        nav<String>(data, ['metadata', 'channelMetadataRenderer', 'description']),
    tabs: tabs,
    sortChips: parseSortChips(selectedContent),
    content: FeedPage(parseFeed(selectedContent), findContinuation(selectedContent)),
  );
}

/// Latest / Popular / Oldest on a channel's video tabs.
List<SortChip> parseSortChips(Object? root) {
  final chips = <SortChip>[];
  void walk(Object? o) {
    if (o is Map) {
      final c = o['chipViewModel'];
      if (c is Json) {
        chips.add(
          SortChip(
            c['text'] as String? ?? '',
            nav<String>(c, ['tapCommand', 'innertubeCommand', 'continuationCommand', 'token']),
            selected: c['selected'] == true,
          ),
        );
        return;
      }
      for (final e in o.entries) {
        if (e.key == 'contents' || e.key == 'items') continue;
        walk(e.value);
      }
    } else if (o is List) {
      o.forEach(walk);
    }
  }

  walk(root);
  return chips;
}

PlaylistPage parsePlaylist(Json data, String id) {
  final header = nav<Json>(data, ['header', 'pageHeaderRenderer']);
  final view = nav<Json>(header, ['content', 'pageHeaderViewModel']);
  final rows = navList(view, ['metadata', 'contentMetadataViewModel', 'metadataRows']);
  String? owner;
  String? ownerId;
  for (final r in rows) {
    for (final p in navList(r, ['metadataParts'])) {
      final stack = nav<Json>(p, ['avatarStack', 'avatarStackViewModel', 'text']);
      if (stack != null) {
        owner = (stack['content'] as String?)?.replaceFirst(RegExp(r'^by '), '');
        ownerId = _channelIdIn(stack);
      }
    }
  }
  final root = _itemsRoot(data);
  // The account's own lists (Watch later, Liked videos) still use the older header.
  final old = nav<Json>(data, ['header', 'playlistHeaderRenderer']);
  if (header == null && old != null) {
    return PlaylistPage(
      id: id,
      title: textOf(old['title']) ?? '',
      owner: textOf(old['ownerText']),
      ownerId: _channelIdIn(old['ownerText']),
      thumbnail: _bestImage(nav(old, ['playlistHeaderBanner', 'heroPlaylistThumbnailRenderer', 'thumbnail'])),
      metadata: [
        if (old['privacy'] == 'PRIVATE') 'Private' else 'Playlist',
        ...navList(old, ['briefStats']).map(textOf).nonNulls,
      ],
      description: textOf(old['descriptionText']),
      videos: Paged(parseItems(root), findContinuation(root)),
    );
  }
  return PlaylistPage(
    id: id,
    title: nav<String>(header, ['pageTitle']) ?? '',
    owner: owner,
    ownerId: ownerId,
    thumbnail: _bestImage(nav(view, ['heroImage', 'contentPreviewImageViewModel', 'image'])),
    metadata: _metadataParts(view),
    description: nav<String>(view, ['description', 'descriptionPreviewViewModel', 'description', 'content']),
    videos: Paged(parseItems(root), findContinuation(root)),
  );
}

ShortsPage parseShortsSequence(Json data) => ShortsPage(
  navList(data, ['entries']).map((e) => nav<String>(e, ['command', 'reelWatchEndpoint', 'videoId'])).nonNulls.toList(),
  nav<String>(data, ['continuationEndpoint', 'continuationCommand', 'token']),
);

// Comments ------------------------------------------------------------------------------------------------------

/// The watch page's comments section token (`next` → itemSectionRenderer `comment-item-section`).
String? findCommentsToken(Json next) {
  final sections = navList(next, ['contents', 'twoColumnWatchNextResults', 'results', 'results', 'contents']);
  for (final s in sections) {
    final isr = nav<Json>(s, ['itemSectionRenderer']);
    if (isr?['sectionIdentifier'] == 'comment-item-section') return findContinuation(isr);
  }
  return null;
}

/// A comments (or replies) continuation. Threads only hold keys; the text, author and counts are entities in
/// `frameworkUpdates` (YouTube's 2024+ comment format).
CommentsPage parseComments(Json data) {
  final entities = <String, Json>{};
  for (final m in navList(data, ['frameworkUpdates', 'entityBatchUpdate', 'mutations'])) {
    final payload = nav<Json>(m, ['payload']);
    final key = m['entityKey'] as String?;
    if (payload == null || key == null || payload.isEmpty) continue;
    entities[key] = payload.values.first as Json;
  }
  final comments = <CommentData>[];
  String? next;
  String? count;
  var sorts = <SortChip>[];
  void item(Json it) {
    final header = nav<Json>(it, ['commentsHeaderRenderer']);
    if (header != null) {
      count = runsOf(header['countText']).map((r) => r['text']).firstOrNull as String?;
      sorts = [
        for (final s in navList(header, ['sortMenu', 'sortFilterSubMenuRenderer', 'subMenuItems']))
          SortChip(
            s['title'] as String? ?? '',
            nav<String>(s, ['serviceEndpoint', 'continuationCommand', 'token']),
            selected: s['selected'] == true,
          ),
      ];
      return;
    }
    final thread = nav<Json>(it, ['commentThreadRenderer']);
    final vm = nav<Json>(thread ?? it, ['commentViewModel', 'commentViewModel']) ?? nav<Json>(it, ['commentViewModel']);
    if (vm != null) {
      final c = _comment(vm, entities, thread);
      if (c != null) comments.add(c);
      return;
    }
    final cont = nav<Json>(it, ['continuationItemRenderer']);
    if (cont != null) {
      next =
          nav<String>(cont, ['continuationEndpoint', 'continuationCommand', 'token']) ??
          nav<String>(cont, ['button', 'buttonRenderer', 'command', 'continuationCommand', 'token']);
    }
  }

  for (final e in navList(data, ['onResponseReceivedEndpoints'])) {
    for (final key in ['reloadContinuationItemsCommand', 'appendContinuationItemsAction']) {
      for (final it in navList(e, [key, 'continuationItems'])) {
        item(it);
      }
    }
  }
  return CommentsPage(comments, next, count: count, sorts: sorts);
}

CommentData? _comment(Json vm, Map<String, Json> entities, Json? thread) {
  final entity = entities[vm['commentKey']];
  if (entity == null) return null;
  final toolbarState = entities[vm['toolbarStateKey']];
  final props = nav<Json>(entity, ['properties']);
  final author = nav<Json>(entity, ['author']);
  final replies = nav<Json>(thread, ['replies', 'commentRepliesRenderer']);
  final replyCount = int.tryParse((nav<String>(entity, ['toolbar', 'replyCount']) ?? '').replaceAll(',', '')) ?? 0;
  return CommentData(
    id: nav<String>(props, ['commentId']) ?? '',
    text: nav<String>(props, ['content', 'content']) ?? '',
    author: nav<String>(author, ['displayName']) ?? '',
    authorAvatar: nav<String>(author, ['avatarThumbnailUrl']),
    authorChannelId: nav<String>(author, ['channelId']),
    published: nav<String>(props, ['publishedTime']),
    likes: nav<String>(entity, ['toolbar', 'likeCountNotliked']),
    replyCount: replyCount,
    repliesToken: replies == null ? null : findContinuation(replies),
    pinnedText: vm['pinnedText'] as String?,
    hearted: toolbarState?['heartState'] == 'TOOLBAR_HEART_STATE_HEARTED',
    isCreator: nav<bool>(author, ['isCreator']) ?? false,
    verified: nav<bool>(author, ['isVerified']) ?? false,
  );
}

AccountInfo? parseAccountMenu(Json data) {
  final header = nav<Json>(data, [
    'actions',
    0,
    'openPopupAction',
    'popup',
    'multiPageMenuRenderer',
    'header',
    'activeAccountHeaderRenderer',
  ]);
  final name = textOf(header?['accountName']);
  if (header == null || name == null) return null;
  return AccountInfo(
    name: name,
    email: textOf(header['email']),
    handle: textOf(header['channelHandle']),
    photo: _bestImage(header['accountPhoto']),
  );
}
