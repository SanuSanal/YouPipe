import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/innertube/models.dart';
import 'package:youpipe/innertube/parsers.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/innertube/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('signed-out home has no videos, only the history nudge', () {
    final home = parseHome(fixture('home'));
    expect(home.items, isEmpty);
    expect(home.nudge, contains('history is off'));
  });

  test("the account's own lists (Watch later) read the older playlistHeaderRenderer", () {
    final page = parsePlaylist({
      'header': {
        'playlistHeaderRenderer': {
          'title': {'simpleText': 'Watch later'},
          'privacy': 'PRIVATE',
          'briefStats': [
            {
              'runs': [
                {'text': '1 video'},
              ],
            },
          ],
          'playlistHeaderBanner': {
            'heroPlaylistThumbnailRenderer': {
              'thumbnail': {
                'thumbnails': [
                  {'url': 'https://i.ytimg.com/vi/aaaaaaaaaaa/hqdefault.jpg', 'width': 168},
                ],
              },
            },
          },
        },
      },
    }, 'WL');
    expect(page.title, 'Watch later');
    expect(page.metadata, ['Private', '1 video']);
    expect(page.thumbnail, startsWith('https://i.ytimg.com/'));
  });

  test('the web sidebar lists subscriptions, including the folded ones, and nothing else', () {
    Map<String, Object?> entry(String id, String name) => {
      'guideEntryRenderer': {
        'formattedTitle': {'simpleText': name},
        'navigationEndpoint': {
          'browseEndpoint': {'browseId': id},
        },
        'thumbnail': {
          'thumbnails': [
            {'url': 'https://yt3.ggpht.com/$id', 'width': 88},
          ],
        },
      },
    };
    final guide = {
      'items': [
        {
          'guideSectionRenderer': {
            'items': [entry('FEwhat_to_watch', 'Home'), entry('UCnotASubscription00000', 'You')],
          },
        },
        {
          'guideSubscriptionsSectionRenderer': {
            'items': [
              entry('UCaaaaaaaaaaaaaaaaaaaaaa', 'First'),
              {
                'guideCollapsibleEntryRenderer': {
                  'expandableItems': [entry('UCbbbbbbbbbbbbbbbbbbbbbb', 'Second'), entry('FEchannels', 'Browse')],
                },
              },
            ],
          },
        },
      ],
    };
    final subs = parseGuideSubscriptions(guide);
    expect(subs.map((c) => c.name), ['First', 'Second']);
    expect(subs.first.avatar, 'https://yt3.ggpht.com/UCaaaaaaaaaaaaaaaaaaaaaa');
    expect(parseGuideSubscriptions({'items': <Object?>[]}), isEmpty);
  });

  test("search for a channel's name: its official card first, then a row of its videos", () {
    final page = parseSearch(fixture('search_channel'));
    final card = (page.entries.first as ItemEntry).item as ChannelItem;
    expect(card.id, 'UCsBjURrPoezykLs9EqgamOA');
    expect(card.name, 'Fireship');
    expect(card.avatar, startsWith('https://'));
    expect(card.subscribersText, '@Fireship • 4.29M subscribers');
    final row = page.entries[1] as ShelfEntry;
    expect(row.shorts, isFalse);
    final first = row.items.whereType<VideoItem>().first;
    expect(first.viewsText, endsWith('views'));
    expect(first.publishedText, endsWith('ago'));
  });

  test('search: videos, a Shorts shelf, filter groups, continuation, no ads', () {
    final page = parseSearch(fixture('search'));
    final videos = page.entries.whereType<ItemEntry>().map((e) => e.item).whereType<VideoItem>().toList();
    expect(videos.length, greaterThanOrEqualTo(10));
    final v = videos.first;
    expect(v.id, hasLength(11));
    expect(v.title, isNotEmpty);
    expect(v.channelName, isNotEmpty);
    expect(v.channelId, startsWith('UC'));
    expect(v.thumbnail, startsWith('https://'));
    expect(videos.where((v) => v.durationText != null).length, greaterThan(videos.length ~/ 2));
    final shelf = page.entries.whereType<ShelfEntry>().first;
    expect(shelf.shorts, isTrue);
    expect(shelf.title, 'Shorts');
    expect(shelf.items.first, isA<VideoItem>());
    expect(page.continuation, isNotNull);
    expect(page.filters.map((g) => g.title), containsAll(['Type', 'Duration', 'Upload date', 'Prioritize']));
    final type = page.filters.firstWhere((g) => g.title == 'Type');
    expect(type.options.firstWhere((o) => o.label == 'Videos').params, isNotNull);
  });

  test('next: related videos come from lockupViewModels', () {
    final page = parseNextRelated(fixture('next'));
    final videos = page.items.whereType<VideoItem>().toList();
    expect(videos.length, greaterThanOrEqualTo(10));
    expect(videos.first.channelName, isNotEmpty);
    expect(videos.first.channelId, startsWith('UC'));
    expect(videos.first.viewsText, isNotNull);
    expect(videos.first.durationText, matches(RegExp(r'^\d+(:\d\d)+$')));
    expect(page.continuation, isNotNull);
  });

  test('channel: header, tabs and the Home tab shelves', () {
    final page = parseChannel(fixture('channel'), 'UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(page.name, 'Rick Astley');
    expect(page.handle, '@RickAstleyYT');
    expect(page.metadata.first, contains('subscribers'));
    expect(page.avatar, startsWith('https://'));
    expect(page.tabs.map((t) => t.title), containsAll(['Home', 'Videos', 'Shorts', 'Playlists']));
    expect(page.tabs.firstWhere((t) => t.title == 'Videos').params, isNotNull);
    final shelves = page.content.entries.whereType<ShelfEntry>().toList();
    expect(shelves.length, greaterThan(3));
    expect(shelves.first.title, isNotEmpty);
    expect(shelves.any((s) => s.shorts), isTrue);
  });

  test('channel Videos tab: a grid of videos, sort chips, continuation', () {
    final page = parseChannel(fixture('channel_videos'), 'UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(page.tabs.firstWhere((t) => t.selected).title, 'Videos');
    final videos = page.content.entries.allItems.whereType<VideoItem>().toList();
    expect(videos.length, greaterThan(20));
    // A channel's own lockups have only [views, age]: neither may be mistaken for the channel name.
    expect(videos.first.viewsText, endsWith('views'));
    expect(videos.first.publishedText, endsWith('ago'));
    expect(videos.first.channelName, isNull);
    expect(page.sortChips.map((c) => c.label), ['Latest', 'Popular', 'Oldest']);
    expect(page.sortChips.first.selected, isTrue);
    expect(page.sortChips[1].token, isNotNull);
    expect(page.content.continuation, isNotNull);
  });

  test("channel Playlists tab: playlists and shows, labels aren't owners", () {
    final page = parseChannel(fixture('channel_playlists'), 'UCsBjURrPoezykLs9EqgamOA');
    final lists = page.content.entries.allItems.whereType<PlaylistItem>().toList();
    expect(lists.first.title, 'The Code Report');
    expect(lists.first.id, startsWith('PL'));
    expect(lists.map((p) => p.channelName).nonNulls, isEmpty);
  });

  test('playlist: header and videos with a view-model continuation', () {
    final page = parsePlaylist(fixture('playlist'), 'PLFgquLnL59alCl_2TQvOiD5Vgm1hCaGSI');
    expect(page.title, 'Popular Music Videos');
    expect(page.owner, 'Music');
    expect(page.ownerId, startsWith('UC'));
    expect(page.metadata, contains('Playlist'));
    expect(page.thumbnail, startsWith('https://'));
    expect(page.videos.items.whereType<VideoItem>().length, greaterThan(50));
    expect(page.videos.continuation, isNotNull);
  });

  test('shorts sequence: ids and a continuation', () {
    final page = parseShortsSequence(fixture('reel_seq'));
    expect(page.videoIds, isNotEmpty);
    expect(page.continuation, isNotNull);
  });

  test('comments: entities give author, avatar, text, likes, replies and the sort options', () {
    final page = parseComments(fixture('comments'));
    expect(page.comments.length, greaterThanOrEqualTo(10));
    final pinned = page.comments.first;
    expect(pinned.author, '@YouTube');
    expect(pinned.authorAvatar, startsWith('https://yt3.ggpht.com/'));
    expect(pinned.text, isNotEmpty);
    expect(pinned.pinnedText, contains('Pinned'));
    expect(pinned.likes, isNotNull);
    expect(pinned.replyCount, greaterThan(0));
    expect(pinned.repliesToken, isNotNull);
    expect(page.count, isNotNull);
    expect(page.sorts.map((s) => s.label), ['Top', 'Newest']);
    expect(page.continuation, isNotNull);
  });
}
