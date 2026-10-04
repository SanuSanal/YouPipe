import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/util/format.dart';

void main() {
  test('compact counts round down like YouTube', () {
    expect(compactCount(999), '999');
    expect(compactCount(1000), '1K');
    expect(compactCount(1290000), '1.2M');
    expect(compactCount(12900000), '12M');
    expect(compactCount(3392), '3.3K');
    expect(compactCount(2500000000), '2.5B');
  });

  test('views labels', () {
    expect(viewsLabel(0), 'No views');
    expect(viewsLabel(1), '1 view');
    expect(viewsLabel(45000), '45K views');
  });

  test('time ago', () {
    final now = DateTime(2026, 10, 3, 12);
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 hours ago');
    expect(timeAgo(now.subtract(const Duration(days: 1)), now: now), '1 day ago');
    expect(timeAgo(now.subtract(const Duration(days: 400)), now: now), '1 year ago');
  });

  test('durations', () {
    expect(formatDuration(const Duration(seconds: 187)), '3:07');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });
}
