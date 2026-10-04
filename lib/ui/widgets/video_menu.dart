import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../navigation.dart';
import '../theme/yt_theme.dart';
import 'common.dart';

String videoUrl(String id, {bool short = false}) => short ? 'https://youtube.com/shorts/$id' : 'https://youtu.be/$id';

Future<void> shareVideo(VideoItem v) => SharePlus.instance.share(
  ShareParams(
    text: videoUrl(v.id, short: v.isShort),
    subject: v.title,
  ),
);

/// Hook for the download manager (Phase 3): starts a download from the ⋮ menu. Null hides the entry.
typedef DownloadStarter = Future<void> Function(BuildContext context, WidgetRef ref, VideoItem video);
DownloadStarter? downloadStarter;

/// The watch page's Download pill, showing progress (set by the downloads feature).
Widget Function(BuildContext context, WidgetRef ref, VideoItem video)? downloadPillBuilder;

/// The ⋮ sheet under any video, with YouTube's entries and order.
Future<void> showVideoMenu(
  BuildContext context,
  WidgetRef ref,
  VideoItem video, {
  VoidCallback? onRemove,
  String? removeLabel,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  builder: (sheet) {
    void close() => Navigator.of(sheet).pop();
    final playing = ref.read(playbackProvider) != null;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playing && !video.isShort)
            _MenuTile(
              icon: Symbols.queue_play_next,
              label: 'Play next in queue',
              onTap: () {
                close();
                ref.read(playbackProvider.notifier).playNext(video);
                showSnack(context, 'Video will play next');
              },
            ),
          _WatchLaterTile(video: video, close: close, context: context),
          _MenuTile(
            icon: Symbols.playlist_add,
            label: 'Save to playlist',
            onTap: () {
              close();
              showSaveToPlaylist(context, ref, video);
            },
          ),
          if (downloadStarter != null && !video.isLive)
            _MenuTile(
              icon: Symbols.download,
              label: 'Download video',
              onTap: () {
                close();
                downloadStarter!(context, ref, video);
              },
            ),
          _MenuTile(
            icon: Symbols.share,
            label: 'Share',
            onTap: () {
              close();
              shareVideo(video);
            },
          ),
          if (video.channelId != null)
            _MenuTile(
              icon: Symbols.account_box,
              label: 'Go to channel',
              onTap: () {
                close();
                openChannel(context, ref, video.channelId!);
              },
            ),
          if (onRemove != null)
            _MenuTile(
              icon: Symbols.delete,
              label: removeLabel ?? 'Remove',
              onTap: () {
                close();
                onRemove();
              },
            ),
        ],
      ),
    );
  },
);

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, weight: 300),
    title: Text(label, style: const TextStyle(fontSize: 15)),
    minLeadingWidth: 24,
    horizontalTitleGap: 20,
    onTap: onTap,
  );
}

class _WatchLaterTile extends ConsumerWidget {
  const _WatchLaterTile({required this.video, required this.close, required this.context});

  final VideoItem video;
  final VoidCallback close;
  final BuildContext context;

  @override
  Widget build(BuildContext sheet, WidgetRef ref) {
    final ids = ref.watch(playlistsContainingProvider(video.id)).value ?? const {};
    final wl = ref.watch(localPlaylistsProvider).value?.where((p) => p.playlist.isWatchLater).firstOrNull;
    final saved = wl != null && ids.contains(wl.playlist.id);
    return _MenuTile(
      icon: Symbols.schedule,
      label: saved ? 'Remove from Watch later' : 'Save to Watch later',
      onTap: () async {
        close();
        await ref.read(libraryProvider).toggleWatchLater(video);
        if (context.mounted) showSnack(context, saved ? 'Removed from Watch later' : 'Saved to Watch later');
      },
    );
  }
}

/// YouTube's "Save video to…" sheet: Watch later and every local playlist with checkboxes, plus "New playlist".
Future<void> showSaveToPlaylist(BuildContext context, WidgetRef ref, VideoItem video) async {
  await ref.read(libraryProvider).watchLaterId();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final playlists = ref.watch(localPlaylistsProvider).value ?? const [];
        final inIds = ref.watch(playlistsContainingProvider(video.id)).value ?? const {};
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Save video to...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in playlists)
                      CheckboxListTile(
                        value: inIds.contains(p.playlist.id),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: context.yt.link,
                        title: Text(p.playlist.name),
                        secondary: Icon(p.playlist.isWatchLater ? Symbols.schedule : Symbols.lock, size: 20),
                        onChanged: (v) async {
                          final lib = ref.read(libraryProvider);
                          v == true
                              ? await lib.addToPlaylist(p.playlist.id, video)
                              : await lib.removeFromPlaylist(p.playlist.id, video.id);
                          if (context.mounted) {
                            showSnack(
                              context,
                              v == true ? 'Saved to ${p.playlist.name}' : 'Removed from ${p.playlist.name}',
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Symbols.add),
                title: const Text('New playlist'),
                onTap: () async {
                  final name = await promptText(sheet, title: 'New playlist', hint: 'Choose a title');
                  if (name == null || name.trim().isEmpty) return;
                  final lib = ref.read(libraryProvider);
                  final id = await lib.createPlaylist(name.trim());
                  await lib.addToPlaylist(id, video);
                  if (context.mounted) showSnack(context, 'Saved to ${name.trim()}');
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<String?> promptText(BuildContext context, {required String title, String? hint, String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: const UnderlineInputBorder(),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: d.yt.link, width: 2)),
        ),
        onSubmitted: (v) => Navigator.of(d).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(d).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(d).pop(controller.text), child: const Text('Save')),
      ],
    ),
  );
}
