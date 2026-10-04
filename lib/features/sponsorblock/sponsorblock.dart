import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../ui/messenger.dart';

/// SponsorBlock categories with their community-standard colours (docs/features.md).
enum SbCategory {
  sponsor('Sponsor', 'Paid promotion', Color(0xFF00D400), SbAction.skip),
  selfpromo('Unpaid/self promotion', 'Merch, donations, shout-outs', Color(0xFFFFFF00), SbAction.skip),
  interaction('Interaction reminder', '"Like and subscribe"', Color(0xFFCC00FF), SbAction.skip),
  intro('Intermission/intro', 'Intro animations, pauses', Color(0xFF00FFFF), SbAction.show),
  outro('Endcards/credits', 'Credits and end screens', Color(0xFF0202ED), SbAction.show),
  preview('Preview/recap', 'Clips of what is coming or was shown', Color(0xFF008FD6), SbAction.show),
  filler('Filler tangent', 'Off-topic jokes and tangents', Color(0xFF7300FF), SbAction.off),
  musicOfftopic('Non-music section', 'In music videos', Color(0xFFFF9900), SbAction.skip);

  const SbCategory(this.label, this.description, this.color, this.defaultAction);

  final String label;
  final String description;
  final Color color;
  final SbAction defaultAction;

  /// The API name.
  String get key => this == musicOfftopic ? 'music_offtopic' : name;
}

enum SbAction { skip, show, off }

class SbSegment {
  const SbSegment(this.category, this.start, this.end);

  final SbCategory category;
  final Duration start;
  final Duration end;
}

/// Uses the hash-prefix endpoint, so only the first 4 hex characters of sha256(videoId) leave the device.
class SponsorBlockService {
  SponsorBlockService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://sponsor.ajay.app/api/',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;
  final _cache = <String, List<SbSegment>>{};

  Future<List<SbSegment>> segmentsFor(String videoId) async {
    final cached = _cache[videoId];
    if (cached != null) return cached;
    final prefix = sha256.convert(utf8.encode(videoId)).toString().substring(0, 4);
    List<SbSegment> result;
    try {
      final res = await _dio.get<List<dynamic>>(
        'skipSegments/$prefix',
        queryParameters: {
          'categories': jsonEncode([for (final c in SbCategory.values) c.key]),
          'actionType': 'skip',
        },
      );
      final entry = (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .where((e) => e['videoID'] == videoId)
          .firstOrNull;
      final byKey = {for (final c in SbCategory.values) c.key: c};
      result = [
        for (final s in (entry?['segments'] as List? ?? const []).cast<Map<String, dynamic>>())
          if ((s['segment'], byKey[s['category']]) case ([final num start, final num end], final SbCategory cat)
              when end - start >= 1)
            SbSegment(
              cat,
              Duration(milliseconds: (start * 1000).round()),
              Duration(milliseconds: (end * 1000).round()),
            ),
      ]..sort((a, b) => a.start.compareTo(b.start));
    } on DioException catch (e) {
      // 404: no segments for any video with this prefix.
      if (e.response?.statusCode != 404) return const [];
      result = const [];
    }
    _cache[videoId] = result;
    return result;
  }
}

final sponsorBlockServiceProvider = Provider<SponsorBlockService>((ref) => SponsorBlockService());

/// Per-category actions plus the master switch, in prefs (`sb_enabled`, `sb_<category>`).
@immutable
class SbSettings {
  const SbSettings(this.enabled, this.actions);

  final bool enabled;
  final Map<SbCategory, SbAction> actions;

  SbAction actionFor(SbCategory c) => enabled ? actions[c] ?? c.defaultAction : SbAction.off;
}

final sbSettingsProvider = NotifierProvider<SbSettingsController, SbSettings>(SbSettingsController.new);

class SbSettingsController extends Notifier<SbSettings> {
  @override
  SbSettings build() {
    final p = ref.watch(prefsProvider);
    return SbSettings(p.getBool('sb_enabled') ?? true, {
      for (final c in SbCategory.values) c: SbAction.values.asNameMap()[p.getString('sb_${c.name}')] ?? c.defaultAction,
    });
  }

  Future<void> setEnabled(bool v) async {
    state = SbSettings(v, state.actions);
    await ref.read(prefsProvider).setBool('sb_enabled', v);
  }

  Future<void> setAction(SbCategory c, SbAction a) async {
    state = SbSettings(state.enabled, {...state.actions, c: a});
    await ref.read(prefsProvider).setString('sb_${c.name}', a.name);
  }
}

/// The segments of a video that aren't turned off.
final sbSegmentsProvider = FutureProvider.autoDispose.family<List<SbSegment>, String>((ref, videoId) async {
  if (videoId.isEmpty) return const [];
  final settings = ref.watch(sbSettingsProvider);
  if (!settings.enabled) return const [];
  final all = await ref.read(sponsorBlockServiceProvider).segmentsFor(videoId);
  return all.where((s) => settings.actionFor(s.category) != SbAction.off).toList();
});

/// Skips "skip" segments of the playing video and says so in a toast with Undo, like SponsorBlock's extension.
/// Watched from the app root.
final sbSkipperProvider = Provider<void>((ref) {
  final controller = ref.watch(playerControllerProvider);
  final videoId = ref.watch(currentInfoProvider)?.videoId;
  if (controller == null || videoId == null) return;
  final segments = ref.watch(sbSegmentsProvider(videoId)).value ?? const <SbSegment>[];
  final settings = ref.watch(sbSettingsProvider);
  final skippable = segments.where((s) => settings.actionFor(s.category) == SbAction.skip).toList();
  if (skippable.isEmpty) return;
  final done = <SbSegment>{};
  void check() {
    final v = controller.value;
    if (!v.isPlaying) return;
    for (final s in skippable) {
      if (done.contains(s)) continue;
      if (v.position >= s.start && v.position < s.end - const Duration(milliseconds: 500)) {
        done.add(s);
        final from = v.position;
        controller.seekTo(s.end);
        showGlobalSnack(
          'Skipped ${s.category.label.toLowerCase()}',
          action: 'Undo',
          onAction: () => controller.seekTo(from),
        );
        break;
      }
    }
  }

  controller.addListener(check);
  ref.onDispose(() => controller.removeListener(check));
});

/// For the seek bar: (start, end, colour) of the playing video's segments.
List<(Duration, Duration, Color)> sbSeekBarSegments(WidgetRef ref, String videoId) => [
  for (final s in ref.watch(sbSegmentsProvider(videoId)).value ?? const <SbSegment>[])
    (s.start, s.end, s.category.color),
];

/// The settings section.
Widget sponsorBlockSettings(BuildContext context, WidgetRef ref) {
  final s = ref.watch(sbSettingsProvider);
  final ctl = ref.read(sbSettingsProvider.notifier);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          'SponsorBlock',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      SwitchListTile(
        title: const Text('Skip sponsors and more'),
        subtitle: const Text('Community-submitted segments from sponsor.ajay.app'),
        value: s.enabled,
        onChanged: ctl.setEnabled,
      ),
      if (s.enabled)
        for (final c in SbCategory.values)
          ListTile(
            leading: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
            ),
            title: Text(c.label),
            subtitle: Text(c.description),
            trailing: DropdownButton<SbAction>(
              value: s.actions[c] ?? c.defaultAction,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: SbAction.skip, child: Text('Skip')),
                DropdownMenuItem(value: SbAction.show, child: Text('Show')),
                DropdownMenuItem(value: SbAction.off, child: Text('Off')),
              ],
              onChanged: (a) {
                if (a != null) ctl.setAction(c, a);
              },
            ),
          ),
    ],
  );
}
