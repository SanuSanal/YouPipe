import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../data/video_info.dart';
import '../../providers.dart';
import '../../ui/theme/yt_theme.dart';
import '../../util/format.dart';

/// YouTube's seek bar: red played part, light buffered part, gaps between chapters, a thumb, and while dragging a
/// storyboard preview with the time and chapter title.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, required this.controller, this.minimal = false, this.onDragging});

  final VideoPlayerController controller;

  /// The thin line shown while the controls are hidden (not draggable).
  final bool minimal;
  final ValueChanged<bool>? onDragging;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _drag;

  /// Focused with the TV remote or a keyboard: Left/Right move the preview 10 s, releasing the key seeks.
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(currentInfoProvider);
    final chapters = info?.chapters ?? const <Chapter>[];
    final segments = info == null
        ? const <(Duration, Duration, Color)>[]
        : seekBarSegments?.call(ref, info.videoId) ?? const [];
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, v, _) {
        final total = v.duration.inMilliseconds;
        if (total <= 0) return const SizedBox(height: 3);
        final played = _drag ?? v.position.inMilliseconds / total;
        final buffered = v.buffered.isEmpty ? 0.0 : v.buffered.last.end.inMilliseconds / total;
        final starts = [for (final ch in chapters) ch.start.inMilliseconds / total];
        final bar = CustomPaint(
          size: Size(double.infinity, widget.minimal ? 3 : 4),
          painter: _BarPainter(
            played: played.clamp(0, 1),
            buffered: buffered.clamp(0, 1),
            chapterStarts: starts,
            segments: [for (final s in segments) (s.$1.inMilliseconds / total, s.$2.inMilliseconds / total, s.$3)],
            thumb: !widget.minimal,
            dragging: _drag != null || _focused,
          ),
        );
        if (widget.minimal) return SizedBox(height: 3, child: bar);
        return LayoutBuilder(
          builder: (context, box) {
            double frac(double dx) => (dx / box.maxWidth).clamp(0.0, 1.0);
            void end() {
              final d = _drag;
              if (d != null) widget.controller.seekTo(Duration(milliseconds: (d * total).round()));
              setState(() => _drag = null);
              widget.onDragging?.call(false);
            }

            KeyEventResult onKey(FocusNode _, KeyEvent e) {
              final left = e.logicalKey == LogicalKeyboardKey.arrowLeft;
              final right = e.logicalKey == LogicalKeyboardKey.arrowRight;
              if (!left && !right) return KeyEventResult.ignored;
              if (e is KeyUpEvent) {
                end();
              } else {
                final step = 10000 / total * (left ? -1 : 1);
                if (_drag == null) widget.onDragging?.call(true);
                setState(() => _drag = ((_drag ?? played) + step).clamp(0.0, 1.0));
              }
              return KeyEventResult.handled;
            }

            return Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              onKeyEvent: onKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) {
                  widget.onDragging?.call(true);
                  setState(() => _drag = frac(d.localPosition.dx));
                },
                onHorizontalDragUpdate: (d) => setState(() => _drag = frac(d.localPosition.dx)),
                onHorizontalDragEnd: (_) => end(),
                onTapUp: (d) {
                  widget.controller.seekTo(Duration(milliseconds: (frac(d.localPosition.dx) * total).round()));
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Align(alignment: Alignment.center, child: bar),
                    ),
                    if (_drag != null)
                      Positioned(
                        bottom: 28,
                        left: (_drag! * box.maxWidth - 80).clamp(4.0, box.maxWidth - 164),
                        child: _Preview(
                          info: info,
                          at: Duration(milliseconds: (_drag! * total).round()),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Coloured stretches drawn on the seek bar (SponsorBlock segments); set by the SponsorBlock feature.
List<(Duration, Duration, Color)> Function(WidgetRef ref, String videoId)? seekBarSegments;

class _Preview extends StatelessWidget {
  const _Preview({required this.info, required this.at});

  final VideoInfo? info;
  final Duration at;

  @override
  Widget build(BuildContext context) {
    final chapter = info?.chapters.lastWhere(
      (c) => c.start <= at,
      orElse: () => const Chapter('', Duration.zero, null),
    );
    final boards = info?.storyboards ?? const <Storyboard>[];
    final board = boards.isEmpty ? null : boards.last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (board != null)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _StoryboardFrame(board: board, at: at),
            ),
          ),
        const SizedBox(height: 4),
        if (chapter != null && chapter.title.isNotEmpty)
          SizedBox(
            width: 160,
            child: Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12, shadows: [Shadow(blurRadius: 4)]),
            ),
          ),
        Text(
          formatDuration(at),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

/// One frame of a storyboard sprite sheet, cropped out of its page.
class _StoryboardFrame extends StatelessWidget {
  const _StoryboardFrame({required this.board, required this.at});

  final Storyboard board;
  final Duration at;

  @override
  Widget build(BuildContext context) {
    const w = 160.0;
    final h = w * board.frameHeight / board.frameWidth;
    final perPage = board.framesPerPageX * board.framesPerPageY;
    final ms = board.durationPerFrame.inMilliseconds;
    final index = ms <= 0 ? 0 : (at.inMilliseconds ~/ ms).clamp(0, board.totalCount - 1);
    final page = (index ~/ perPage).clamp(0, board.urls.length - 1);
    final inPage = index % perPage;
    final col = inPage % board.framesPerPageX;
    final row = inPage ~/ board.framesPerPageX;
    return SizedBox(
      width: w,
      height: h,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: w * board.framesPerPageX,
          maxHeight: h * board.framesPerPageY,
          child: Transform.translate(
            offset: Offset(-col * w, -row * h),
            child: Image.network(
              board.urls[page],
              width: w * board.framesPerPageX,
              height: h * board.framesPerPageY,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.played,
    required this.buffered,
    required this.chapterStarts,
    required this.segments,
    required this.thumb,
    required this.dragging,
  });

  final double played;
  final double buffered;
  final List<double> chapterStarts;

  /// Coloured segments as (start, end) fractions of the duration.
  final List<(double, double, Color)> segments;
  final bool thumb;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final h = dragging ? size.height + 2 : size.height;
    final y = (size.height - h) / 2;
    final w = size.width;
    // Chapter gaps: the bar is drawn as separate pieces.
    final cuts = [0.0, ...chapterStarts.where((s) => s > 0 && s < 1), 1.0];
    const gap = 2.0;
    for (var i = 0; i + 1 < cuts.length; i++) {
      final a = cuts[i] * w + (i == 0 ? 0 : gap / 2);
      final b = cuts[i + 1] * w - (i + 2 == cuts.length ? 0 : gap / 2);
      if (b <= a) continue;
      void seg(double from, double to, Color color) {
        final l = a + (from * w - a).clamp(0, b - a);
        final r = a + (to * w - a).clamp(0, b - a);
        if (r > l) canvas.drawRect(Rect.fromLTRB(l, y, r, y + h), Paint()..color = color);
      }

      seg(0, 1, Colors.white.withValues(alpha: 0.3));
      seg(0, buffered, Colors.white.withValues(alpha: 0.5));
      for (final s in segments) {
        seg(s.$1, s.$2, s.$3);
      }
      seg(0, played, YtColors.progress);
    }
    if (thumb) {
      canvas.drawCircle(Offset(played * w, size.height / 2), dragging ? 9 : 6, Paint()..color = YtColors.progress);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.played != played || old.buffered != buffered || old.dragging != dragging || old.thumb != thumb;
}
