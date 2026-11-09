import 'package:ai_engineering_bazaar/shared/utils/short_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The web's SignOff.tsx shortDate: en-GB, UTC, the first ten characters.
  test('shortDate writes the day, the short month and the year', () {
    expect(shortDate('2026-10-11T08:00:00.000Z'), '11 Oct 2026');
    // en-GB writes Sept, as Node and intl 0.20.3 en_GB do.
    expect(shortDate('2026-09-03T23:59:00.000Z'), '3 Sept 2026');
    expect(shortDate('2026-01-31'), '31 Jan 2026');
    expect(shortDate('2026-12-01T00:00:00.000Z'), '1 Dec 2026');
  });

  test('shortDate keeps the first ten characters when they are not a real date', () {
    expect(shortDate('2026-13-40'), '2026-13-40');
    // A day that would roll over into the next month.
    expect(shortDate('2026-02-30T10:00:00.000Z'), '2026-02-30');
    expect(shortDate('not a date at all'), 'not a date');
  });
}
