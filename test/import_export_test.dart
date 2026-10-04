import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/features/subscriptions/import_export.dart';
import 'package:youpipe/innertube/models.dart';

void main() {
  test('Google Takeout CSV, with a quoted title containing a comma', () {
    const csv =
        'Channel Id,Channel Url,Channel Title\n'
        'UCuAXFkgsw1L7xaCfnd5JJOw,http://www.youtube.com/channel/UCuAXFkgsw1L7xaCfnd5JJOw,Rick Astley\n'
        'UCHnyfMqiRRG1u-2MsSQLbXA,http://www.youtube.com/channel/UCHnyfMqiRRG1u-2MsSQLbXA,"Veritasium, Inc"\n';
    final subs = parseSubscriptionsFile(csv);
    expect(subs.map((c) => c.id), ['UCuAXFkgsw1L7xaCfnd5JJOw', 'UCHnyfMqiRRG1u-2MsSQLbXA']);
    expect(subs[1].name, 'Veritasium, Inc');
  });

  test('NewPipe export round trip', () {
    final json = exportSubscriptions(const [ChannelItem(id: 'UCuAXFkgsw1L7xaCfnd5JJOw', name: 'Rick Astley')]);
    final subs = parseSubscriptionsFile(json);
    expect(subs.single.id, 'UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(subs.single.name, 'Rick Astley');
  });
}
