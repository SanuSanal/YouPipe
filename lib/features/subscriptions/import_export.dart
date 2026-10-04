import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/widgets/common.dart';

/// Reads subscriptions from a Google Takeout `subscriptions.csv` ("Channel Id,Channel Url,Channel Title") or a
/// NewPipe export (`{"subscriptions": [{"url": …/channel/UC…, "name": …}]}`).
List<ChannelItem> parseSubscriptionsFile(String text) {
  final trimmed = text.trimLeft();
  if (trimmed.startsWith('{')) {
    final data = jsonDecode(trimmed);
    final subs = data is Map ? data['subscriptions'] : null;
    if (subs is! List) return const [];
    return [
      for (final s in subs.whereType<Map>())
        if (_channelId(s['url'] as String? ?? '') case final id?)
          ChannelItem(id: id, name: (s['name'] as String?) ?? id),
    ];
  }
  final out = <ChannelItem>[];
  for (final line in const LineSplitter().convert(text)) {
    final cells = _csvCells(line);
    if (cells.length < 2) continue;
    final id = cells[0].startsWith('UC') ? cells[0] : _channelId(cells[1]);
    if (id == null) continue;
    out.add(ChannelItem(id: id, name: cells.length > 2 && cells[2].isNotEmpty ? cells[2] : id));
  }
  return out;
}

String? _channelId(String url) => RegExp(r'(UC[\w-]{22})').firstMatch(url)?.group(1);

/// Splits one CSV line, honouring quotes (channel titles can contain commas).
List<String> _csvCells(String line) {
  final cells = <String>[];
  final cur = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        cur.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (ch == ',' && !quoted) {
      cells.add(cur.toString().trim());
      cur.clear();
    } else {
      cur.write(ch);
    }
  }
  cells.add(cur.toString().trim());
  return cells;
}

/// NewPipe's export format, which NewPipe, LibreTube and YouPipe all read.
String exportSubscriptions(List<ChannelItem> channels) => const JsonEncoder.withIndent('  ').convert({
  'app_version': 'YouPipe',
  'app_version_int': 1,
  'subscriptions': [
    for (final c in channels) {'service_id': 0, 'url': 'https://www.youtube.com/channel/${c.id}', 'name': c.name},
  ],
});

Future<void> importSubscriptions(BuildContext context, WidgetRef ref) async {
  final files = await FilePicker.pickFiles(
    dialogTitle: 'Choose subscriptions.csv or a NewPipe export',
    type: FileType.custom,
    allowedExtensions: const ['csv', 'json'],
  );
  if (files.isEmpty) return;
  final text = utf8.decode(await files.first.readAsBytes(), allowMalformed: true);
  final channels = parseSubscriptionsFile(text);
  if (!context.mounted) return;
  if (channels.isEmpty) {
    showSnack(context, 'No channels found in that file');
    return;
  }
  await ref.read(libraryProvider).importSubscriptions(channels);
  await ref.read(subscriptionsFeedServiceProvider).refresh(force: true);
  if (context.mounted) showSnack(context, 'Imported ${channels.length} subscriptions');
}

Future<void> exportSubscriptionsFile(BuildContext context, WidgetRef ref) async {
  final channels = await ref.read(libraryProvider).subscriptionsOnce();
  final bytes = Uint8List.fromList(utf8.encode(exportSubscriptions(channels)));
  final uri = await FilePicker.saveFile(
    fileName: 'youpipe_subscriptions.json',
    bytes: bytes,
    mimeType: 'application/json',
  );
  if (context.mounted && uri != null) showSnack(context, 'Exported ${channels.length} subscriptions');
}

/// The ⋮ on All subscriptions.
Widget subscriptionsMenu(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
  icon: const Icon(Symbols.more_vert),
  onSelected: (v) => v == 'import' ? importSubscriptions(context, ref) : exportSubscriptionsFile(context, ref),
  itemBuilder: (_) => const [
    PopupMenuItem(value: 'import', child: Text('Import (Google Takeout or NewPipe)')),
    PopupMenuItem(value: 'export', child: Text('Export')),
  ],
);
