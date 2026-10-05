import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/ui/widgets/html_text.dart';

void main() {
  test('HTML entities are decoded once, including &apos; and numeric ones', () {
    // A Lofi Girl description showed "I&apos;m almost ready" (2026-10-05).
    expect(htmlToPlain('I&apos;m almost ready'), "I'm almost ready");
    expect(htmlToPlain('Tom &amp; Jerry &lt;3 &quot;hi&quot; &#39;a&#x27;'), 'Tom & Jerry <3 "hi" \'a\'');
    expect(htmlToPlain('It&#8217;s &#x1F383;'), 'It’s \u{1F383}');
    expect(htmlToPlain('&amp;lt;b&amp;gt;'), '&lt;b&gt;');
    expect(htmlToPlain('a&nbsp;b<br>c'), 'a b\nc');
    expect(htmlToPlain('&unknown; &#xZZ; & alone'), '&unknown; &#xZZ; & alone');
  });
}
