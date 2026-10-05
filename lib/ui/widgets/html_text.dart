import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/yt_theme.dart';

/// Renders the small HTML subset YouTube uses in descriptions and comments: links, line breaks, bold/italic.
/// Timestamp links (`…&t=123s` / `#t=`) call [onTimestamp] instead of opening a browser.
class HtmlText extends StatefulWidget {
  const HtmlText(this.html, {super.key, this.style, this.maxLines, this.onTimestamp, this.onHashtag});

  final String html;
  final TextStyle? style;
  final int? maxLines;
  final ValueChanged<Duration>? onTimestamp;
  final ValueChanged<String>? onHashtag;

  @override
  State<HtmlText> createState() => _HtmlTextState();
}

class _HtmlTextState extends State<HtmlText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final link = TextStyle(color: context.yt.link);
    final spans = <InlineSpan>[];
    var bold = false;
    var italic = false;
    final token = RegExp(
      r'<a\s[^>]*href="([^"]*)"[^>]*>(.*?)</a>|<br\s*/?>|<(/?)(b|strong|i|em)>|<[^>]+>',
      dotAll: true,
    );
    var last = 0;
    void addText(String t) {
      if (t.isEmpty) return;
      spans.add(
        TextSpan(
          text: _unescape(t),
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null, fontStyle: italic ? FontStyle.italic : null),
        ),
      );
    }

    // Plain-text descriptions (no tags) still get their URLs linked.
    final html = widget.html.contains('<') ? widget.html : _linkify(widget.html);
    for (final m in token.allMatches(html)) {
      addText(html.substring(last, m.start));
      last = m.end;
      final whole = m.group(0)!;
      if (m.group(1) != null) {
        final href = _unescape(m.group(1)!);
        final text = _unescape(m.group(2)!.replaceAll(RegExp(r'<[^>]+>'), ''));
        final r = TapGestureRecognizer()..onTap = () => _open(href, text);
        _recognizers.add(r);
        spans.add(TextSpan(text: text, style: link, recognizer: r));
      } else if (whole.startsWith('<br')) {
        spans.add(const TextSpan(text: '\n'));
      } else if (m.group(4) != null) {
        final closing = m.group(3) == '/';
        if (m.group(4) == 'b' || m.group(4) == 'strong') {
          bold = !closing;
        } else {
          italic = !closing;
        }
      }
    }
    addText(html.substring(last));
    return Text.rich(
      TextSpan(children: spans, style: widget.style),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }

  void _open(String href, String text) {
    final t = _timestamp(href);
    if (t != null && widget.onTimestamp != null) {
      widget.onTimestamp!(t);
      return;
    }
    if (text.startsWith('#') && widget.onHashtag != null) {
      widget.onHashtag!(text);
      return;
    }
    final uri = Uri.tryParse(href.startsWith('/') ? 'https://www.youtube.com$href' : href);
    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// `t=1h2m3s`, `t=123`, `#t=123` in a YouTube link.
Duration? _timestamp(String href) {
  final m = RegExp(r'[?&#]t=([0-9hms]+)').firstMatch(href);
  if (m == null) return null;
  final v = m.group(1)!;
  final plain = int.tryParse(v.replaceAll('s', ''));
  if (plain != null && !v.contains(RegExp('[hm]'))) return Duration(seconds: plain);
  var seconds = 0;
  for (final part in RegExp(r'(\d+)([hms])').allMatches(v)) {
    final n = int.parse(part.group(1)!);
    seconds += switch (part.group(2)) {
      'h' => n * 3600,
      'm' => n * 60,
      _ => n,
    };
  }
  return Duration(seconds: seconds);
}

String _linkify(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('\n', '<br>')
    .replaceAllMapped(RegExp(r'https?://[^\s<]+|\b(?:(\d{1,2}):)?(\d{1,2}):(\d{2})\b'), (m) {
      if (m[0]!.startsWith('http')) return '<a href="${m[0]}">${m[0]}</a>';
      // A timestamp like 1:02:03 or 4:05 seeks the video.
      final seconds = int.parse(m[1] ?? '0') * 3600 + int.parse(m[2]!) * 60 + int.parse(m[3]!);
      return '<a href="#t=$seconds">${m[0]}</a>';
    });

const _entities = {'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' '};

/// Decodes HTML entities in one pass (so "&amp;lt;" stays "&lt;"), including numeric ones like "&#8217;".
String _unescape(String s) => s.replaceAllMapped(RegExp(r'&(#[xX][0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
  final e = m[1]!;
  if (!e.startsWith('#')) return _entities[e] ?? m[0]!;
  final code = e[1] == 'x' || e[1] == 'X' ? int.tryParse(e.substring(2), radix: 16) : int.tryParse(e.substring(1));
  return code == null || code > 0x10FFFF ? m[0]! : String.fromCharCode(code);
});

/// The plain text of YouTube HTML (for one-line previews).
String htmlToPlain(String html) =>
    _unescape(html.replaceAll(RegExp(r'<br\s*/?>'), '\n').replaceAll(RegExp(r'<[^>]+>'), ''));
