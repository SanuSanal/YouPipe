/// Plain immutable models for what the WEB InnerTube client returns. Items compare equal by type and id.
library;

sealed class YtItem {
  const YtItem();

  String get id;

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType && other is YtItem && other.id == id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

class VideoItem extends YtItem {
  const VideoItem({
    required this.id,
    required this.title,
    this.channelName,
    this.channelId,
    this.channelAvatar,
    this.thumbnail,
    this.durationText,
    this.viewsText,
    this.publishedText,
    this.isShort = false,
    this.isLive = false,
  });

  @override
  final String id;
  final String title;
  final String? channelName;
  final String? channelId;
  final String? channelAvatar;
  final String? thumbnail;
  final String? durationText;
  final String? viewsText;
  final String? publishedText;
  final bool isShort;
  final bool isLive;

  /// The thumbnail for [id], when the response didn't carry one.
  String get thumbnailOrDefault => thumbnail ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg';

  /// For local caches (the Home feed shown at launch).
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'channelName': channelName,
    'channelId': channelId,
    'channelAvatar': channelAvatar,
    'thumbnail': thumbnail,
    'durationText': durationText,
    'viewsText': viewsText,
    'publishedText': publishedText,
    'isShort': isShort,
    'isLive': isLive,
  };

  factory VideoItem.fromJson(Map<String, Object?> j) => VideoItem(
    id: j['id']! as String,
    title: j['title']! as String,
    channelName: j['channelName'] as String?,
    channelId: j['channelId'] as String?,
    channelAvatar: j['channelAvatar'] as String?,
    thumbnail: j['thumbnail'] as String?,
    durationText: j['durationText'] as String?,
    viewsText: j['viewsText'] as String?,
    publishedText: j['publishedText'] as String?,
    isShort: j['isShort'] as bool? ?? false,
    isLive: j['isLive'] as bool? ?? false,
  );
}

class ChannelItem extends YtItem {
  const ChannelItem({required this.id, required this.name, this.avatar, this.subscribersText});

  @override
  final String id;
  final String name;
  final String? avatar;
  final String? subscribersText;
}

class PlaylistItem extends YtItem {
  const PlaylistItem({required this.id, required this.title, this.thumbnail, this.channelName, this.countText});

  @override
  final String id;
  final String title;
  final String? thumbnail;
  final String? channelName;
  final String? countText;
}

/// A page of items plus the token for the next one.
class Paged<T> {
  const Paged(this.items, this.continuation);

  final List<T> items;
  final String? continuation;
}

/// One entry of a feed: a single item, or a titled shelf of items (Shorts shelf, "People also watched", a channel's
/// playlist shelves).
sealed class FeedEntry {
  const FeedEntry();
}

class ItemEntry extends FeedEntry {
  const ItemEntry(this.item);

  final YtItem item;
}

class ShelfEntry extends FeedEntry {
  const ShelfEntry(this.title, this.items, {this.shorts = false});

  final String title;
  final List<YtItem> items;

  /// A Shorts shelf (vertical 9:16 cards).
  final bool shorts;
}

extension FeedEntries on List<FeedEntry> {
  /// Every item, shelves flattened.
  Iterable<YtItem> get allItems => expand(
    (e) => switch (e) {
      ItemEntry(:final item) => [item],
      ShelfEntry(:final items) => items,
    },
  );
}

class FeedPage {
  const FeedPage(this.entries, this.continuation);

  final List<FeedEntry> entries;
  final String? continuation;
}

/// The Home feed. Signed out with no watch history, YouTube returns no videos, only a [nudge] message.
class HomeFeed extends Paged<YtItem> {
  const HomeFeed(super.items, super.continuation, {this.nudge});

  final String? nudge;
}

class SearchFilterOption {
  const SearchFilterOption(this.label, this.params, {this.selected = false});

  final String label;

  /// The search `params` that apply this option (null when it's the current state, e.g. "Relevance").
  final String? params;
  final bool selected;
}

class SearchFilterGroup {
  const SearchFilterGroup(this.title, this.options);

  final String title;
  final List<SearchFilterOption> options;
}

class SearchPage extends FeedPage {
  const SearchPage(super.entries, super.continuation, {this.filters = const []});

  /// The filter sheet's groups (Type, Duration, Upload date, Features, Prioritize), straight from the response.
  final List<SearchFilterGroup> filters;
}

/// A sort chip on a channel's Videos/Shorts/Live tab (Latest, Popular, Oldest); [token] reloads the list sorted.
class SortChip {
  const SortChip(this.label, this.token, {this.selected = false});

  final String label;
  final String? token;
  final bool selected;
}

class ChannelTab {
  const ChannelTab(this.title, this.params, {this.selected = false});

  final String title;
  final String? params;
  final bool selected;
}

class ChannelPage {
  const ChannelPage({
    required this.id,
    required this.name,
    this.avatar,
    this.banner,
    this.handle,
    this.metadata = const [],
    this.description,
    this.tabs = const [],
    this.sortChips = const [],
    required this.content,
  });

  final String id;
  final String name;
  final String? avatar;
  final String? banner;
  final String? handle;

  /// "4.55M subscribers", "437 videos", …
  final List<String> metadata;
  final String? description;
  final List<ChannelTab> tabs;
  final List<SortChip> sortChips;

  /// The selected tab's content.
  final FeedPage content;

  ChannelItem get asItem => ChannelItem(id: id, name: name, avatar: avatar, subscribersText: metadata.firstOrNull);
}

class PlaylistPage {
  const PlaylistPage({
    required this.id,
    required this.title,
    this.owner,
    this.ownerId,
    this.thumbnail,
    this.metadata = const [],
    this.description,
    required this.videos,
  });

  final String id;
  final String title;
  final String? owner;
  final String? ownerId;
  final String? thumbnail;

  /// "Playlist", "183 videos", "1,045,668,940 views".
  final List<String> metadata;
  final String? description;
  final Paged<YtItem> videos;

  PlaylistItem get asItem => PlaylistItem(id: id, title: title, thumbnail: thumbnail, channelName: owner);
}

class AccountInfo {
  const AccountInfo({required this.name, this.email, this.handle, this.photo});

  final String name;
  final String? email;
  final String? handle;
  final String? photo;
}

/// One page of the Shorts feed: video ids only; metadata comes with each Short's video info.
class ShortsPage {
  const ShortsPage(this.videoIds, this.continuation);

  final List<String> videoIds;
  final String? continuation;
}

/// A comment or reply, from the watch page's comment entities.
class CommentData {
  const CommentData({
    required this.id,
    required this.text,
    required this.author,
    this.authorAvatar,
    this.authorChannelId,
    this.published,
    this.likes,
    this.replyCount = 0,
    this.repliesToken,
    this.pinnedText,
    this.hearted = false,
    this.isCreator = false,
    this.verified = false,
  });

  final String id;

  /// Plain text; links and timestamps are recognised when shown.
  final String text;
  final String author;
  final String? authorAvatar;
  final String? authorChannelId;
  final String? published;

  /// "322K", as YouTube shows it.
  final String? likes;
  final int replyCount;
  final String? repliesToken;

  /// "Pinned by @channel".
  final String? pinnedText;
  final bool hearted;

  /// Written by the video's channel.
  final bool isCreator;
  final bool verified;
}

class CommentsPage {
  const CommentsPage(this.comments, this.continuation, {this.count, this.sorts = const []});

  final List<CommentData> comments;
  final String? continuation;

  /// "2,458,072".
  final String? count;

  /// Top comments / Newest first; each [SortChip.token] reloads the list.
  final List<SortChip> sorts;
}
