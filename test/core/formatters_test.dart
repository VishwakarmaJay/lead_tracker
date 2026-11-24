import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/utils/formatters.dart';

void main() {
  final now = DateTime(2026, 11, 24, 18);

  test('formatTime uses 12-hour clock', () {
    expect(formatTime(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(formatTime(DateTime(2026, 1, 1, 15, 30)), '3:30 PM');
    expect(formatTime(DateTime(2026, 1, 1, 12)), '12:00 PM');
  });

  test('formatDateTime says Today / Yesterday, else the date', () {
    expect(
      formatDateTime(DateTime(2026, 11, 24, 9), now: now),
      'Today, 9:00 AM',
    );
    expect(
      formatDateTime(DateTime(2026, 11, 23, 21, 15), now: now),
      'Yesterday, 9:15 PM',
    );
    expect(
      formatDateTime(DateTime(2026, 11, 2, 9), now: now),
      '2 Nov 2026, 9:00 AM',
    );
  });

  test('formatCallDuration', () {
    expect(formatCallDuration(45), '45s');
    expect(formatCallDuration(125), '2m 05s');
    expect(formatCallDuration(3720), '1h 02m');
  });
}
