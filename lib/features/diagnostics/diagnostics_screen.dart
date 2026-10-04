import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/video_info.dart';
import '../../innertube/innertube.dart';
import '../../innertube/json_nav.dart';
import '../../providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The Phase 0 exit criteria, automated (docs/testing.md): reachable from Settings → About → Diagnostics. Every
/// result is also logged as `SPIKE|…` for `adb logcat`.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

enum _Kind { vod, uhd, live, short, ageRestricted }

class _Case {
  _Case(this.kind, this.videoId, this.title);

  final _Kind kind;
  final String videoId;
  final String title;
  String status = 'pending';
  bool? passed;
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  final _cases = <_Case>[];
  final _notes = <String>[];
  bool _running = false;
  Timer? _bgTimer;

  void _log(String line) {
    debugPrint('SPIKE|$line');
    setState(() => _notes.add(line));
  }

  InnerTube get _it => ref.read(innerTubeProvider);

  Future<List<VideoItem>> _videos(String q, {SearchFilter filter = SearchFilter.videos}) async => (await _it.search(
    q,
    params: filter.params,
  )).entries.allItems.whereType<VideoItem>().where((v) => !v.isShort).toList();

  Future<void> _gather() async {
    _cases.clear();
    final random = <VideoItem>[];
    for (final q in const [
      'music video',
      'documentary',
      'podcast',
      'tutorial',
      'gameplay',
      'news',
      'travel vlog',
      'cooking',
    ]) {
      final found = (await _videos(q)).where((v) {
        final d = parseDuration(v.durationText);
        return !v.isLive && d != null && d > const Duration(minutes: 1) && !random.contains(v);
      });
      random.addAll(found.take(3));
      if (random.length >= 20) break;
    }
    _cases.addAll(random.take(20).map((v) => _Case(_Kind.vod, v.id, v.title)));
    final uhd = (await _videos('4K 60fps nature drone')).where((v) => !v.isLive).take(2);
    _cases.addAll(uhd.map((v) => _Case(_Kind.uhd, v.id, v.title)));
    final live = (await _videos('live', filter: SearchFilter.live)).where((v) => v.isLive).take(2);
    _cases.addAll(live.map((v) => _Case(_Kind.live, v.id, v.title)));
    final shorts = await _it.shorts();
    _cases.addAll(shorts.videoIds.take(5).map((id) => _Case(_Kind.short, id, 'Short $id')));
    _cases.add(_Case(_Kind.ageRestricted, '6kLq3WMV1nU', 'Age-restricted (expect a friendly error)'));
    _log('gathered ${random.length} vod, ${uhd.length} uhd, ${live.length} live, ${shorts.videoIds.length} shorts');
  }

  Future<void> _runAll() async {
    if (_running) return;
    setState(() {
      _running = true;
      _notes.clear();
    });
    try {
      await _gather();
      for (final c in _cases) {
        await _run(c);
      }
      await _comments();
      final pass = _cases.where((c) => c.passed == true).length;
      _log('SUMMARY $pass/${_cases.length} passed');
      for (final k in _Kind.values) {
        final of = _cases.where((c) => c.kind == k);
        _log('  ${k.name}: ${of.where((c) => c.passed == true).length}/${of.length}');
      }
    } catch (e, st) {
      _log('ABORTED $e\n$st');
    } finally {
      await ref.read(playerServiceProvider).stop();
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _run(_Case c) async {
    final player = ref.read(playerServiceProvider);
    final sw = Stopwatch()..start();
    setState(() => c.status = 'loading');
    final ok = await player.open(c.videoId, maxHeight: c.kind == _Kind.uhd ? 2160 : 1080, autoplay: false);
    if (!ok) {
      final e = player.error.value;
      c.passed = c.kind == _Kind.ageRestricted && e is VideoUnavailable && e.code == 'AGE_RESTRICTED';
      c.status = e is VideoUnavailable ? '${e.code}: ${e.friendly}' : 'error: $e';
      _log('${c.passed! ? 'PASS' : 'FAIL'} ${c.kind.name} ${c.videoId} ${c.status}');
      return;
    }
    if (c.kind == _Kind.ageRestricted) {
      c.passed = true;
      c.status = 'played (not restricted for this client)';
      _log('PASS ${c.kind.name} ${c.videoId} ${c.status}');
      return;
    }
    final info = player.info.value!;
    final loadMs = sw.elapsedMilliseconds;
    // Past the first MB is where PO-token-less URLs used to 403, so seek deep into VODs.
    if (c.kind == _Kind.vod || c.kind == _Kind.uhd) {
      final vc = player.controller.value!;
      await vc.seekTo(vc.value.duration * 0.75);
    }
    await player.controller.value!.play();
    // Follow the service's current controller: after a mid-play error it re-resolves and swaps in a new one.
    Duration? start;
    VideoPlayerController? watched;
    var advanced = false;
    var recoveries = 0;
    for (var i = 0; i < 70 && !advanced; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final vc = player.controller.value;
      if (vc == null || !vc.value.isInitialized) continue;
      if (!identical(vc, watched)) {
        if (watched != null) recoveries++;
        watched = vc;
        start = vc.value.position;
      }
      final v = vc.value;
      if (v.hasError) continue;
      // A live position is relative to a sliding window and stays near its end, so check it keeps playing instead.
      advanced = c.kind == _Kind.live
          ? i >= 12 && v.isPlaying && !v.isBuffering
          : v.position - start! >= const Duration(seconds: 5);
    }
    final v = watched?.value ?? VideoPlayerValue.uninitialized();
    final height = v.size.height.round();
    c.passed = advanced && (c.kind != _Kind.uhd || info.dashHeights.isNotEmpty);
    c.status =
        '${player.source?.name} ${height}p (manifest ${info.dashHeights.isEmpty ? '-' : info.dashHeights.last} '
        '${info.dashCodec ?? ''}) load ${loadMs}ms @${v.position.inSeconds}/${v.duration.inSeconds}s '
        'cc ${info.captions.length} ch ${info.chapters.length} sb ${info.storyboards.length}'
        '${recoveries > 0 ? ' RECOVERED x$recoveries' : ''}${v.hasError ? ' ERR ${v.errorDescription}' : ''}';
    _log('${c.passed! ? 'PASS' : 'FAIL'} ${c.kind.name} ${c.videoId} ${c.status}');
    setState(() {});
  }

  Future<void> _comments() async {
    final first = _cases.firstWhere((c) => c.kind == _Kind.vod);
    try {
      final p1 = await _it.comments(first.videoId);
      _log(
        'comments ${first.videoId}: count ${p1.count}, page1 ${p1.comments.length}, next ${p1.continuation != null}',
      );
      if (p1.continuation != null) {
        final p2 = await _it.commentsContinuation(p1.continuation!);
        _log('comments page2 ${p2.comments.length}');
      }
      final withReplies = p1.comments.where((c) => c.repliesToken != null).firstOrNull;
      if (withReplies != null) {
        final r = await _it.commentsContinuation(withReplies.repliesToken!);
        _log('replies ${r.comments.length} of ${withReplies.replyCount}');
      }
    } catch (e) {
      _log('FAIL comments $e');
    }
  }

  /// Plays a long video from the start and logs its position every 30 s, to check background/screen-off playback.
  Future<void> _background() async {
    _bgTimer?.cancel();
    final long = (await _videos('full documentary 1 hour'))
        .firstWhere((v) => (parseDuration(v.durationText) ?? Duration.zero) > const Duration(minutes: 20));
    final ok = await ref.read(playerServiceProvider).open(long.id);
    _log('bg start ${long.id} ok=$ok "${long.title}"');
    _bgTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final v = ref.read(playerServiceProvider).controller.value?.value;
      debugPrint('SPIKE|bg pos=${v?.position.inSeconds}s playing=${v?.isPlaying} err=${v?.hasError}');
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Diagnostics'),
      leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
    ),
    body: Column(
      children: [
        ValueListenableBuilder(
          valueListenable: ref.read(playerServiceProvider).controller,
          builder: (context, c, _) => c == null
              ? const SizedBox(height: 0)
              : SizedBox(
                  height: 160,
                  child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _running ? null : _runAll,
                child: Text(_running ? 'Running…' : 'Run Phase 0 suite'),
              ),
              OutlinedButton(onPressed: _background, child: const Text('Background test')),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final c in _cases)
                ListTile(
                  dense: true,
                  leading: Icon(
                    c.passed == null ? Icons.hourglass_empty : (c.passed! ? Icons.check_circle : Icons.cancel),
                    color: c.passed == null ? null : (c.passed! ? Colors.green : Colors.red),
                  ),
                  title: Text('${c.kind.name} · ${c.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(c.status, style: const TextStyle(fontSize: 11)),
                ),
              for (final n in _notes.where((n) => !n.startsWith('PASS') && !n.startsWith('FAIL ')))
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(n, style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
