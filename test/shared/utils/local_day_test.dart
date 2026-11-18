import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayNumber', () {
    test('turns at local midnight, not before', () {
      expect(dayNumber(DateTime(2026, 11, 16, 23, 59)), dayNumber(DateTime(2026, 11, 16)));
      expect(dayNumber(DateTime(2026, 11, 17)), dayNumber(DateTime(2026, 11, 16)) + 1);
    });
  });

  // A UTC clock east of UTC once read the UTC date as the local one: the next midnight fell in the past, the card's
  // timer fired at once and armed itself again, and the app froze (CI at UTC+14, 2026-11-17).
  group('untilLocalMidnight', () {
    test('a UTC moment waits for the next local midnight, never less than none', () {
      final halfPastMidnight = DateTime(2026, 11, 9, 0, 30);
      const wait = Duration(hours: 23, minutes: 30, seconds: 1);
      expect(untilLocalMidnight(halfPastMidnight), wait);
      expect(untilLocalMidnight(halfPastMidnight.toUtc()), wait);
    });
  });

  group('dayNumber of a UTC moment', () {
    test('is the local day', () {
      final halfPastMidnight = DateTime(2026, 11, 9, 0, 30);
      expect(dayNumber(halfPastMidnight.toUtc()), dayNumber(halfPastMidnight));
    });
  });
}
