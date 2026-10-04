// Prints how the parsers read a recorded response: dart run tool/inspect_feed.dart <file.json>
import 'dart:convert';
import 'dart:io';

import 'package:youpipe/innertube/models.dart';
import 'package:youpipe/innertube/parsers.dart';

void main(List<String> args) {
  final data = jsonDecode(File(args.first).readAsStringSync()) as Map<String, dynamic>;
  final page = parseSearch(data);
  for (final e in page.entries.take(12)) {
    switch (e) {
      case ItemEntry(:final item):
        stdout.writeln('ITEM ${_describe(item)}');
      case ShelfEntry(:final title, :final items, :final shorts):
        stdout.writeln('SHELF "$title" shorts=$shorts n=${items.length} first=${_describe(items.first)}');
    }
  }
}

String _describe(YtItem i) => switch (i) {
  VideoItem v => 'video ${v.id} "${v.title}" ch=${v.channelName} avatar=${v.channelAvatar != null} views=${v.viewsText} age=${v.publishedText}',
  ChannelItem c => 'channel ${c.name} ${c.subscribersText}',
  PlaylistItem p => 'playlist ${p.title}',
};
