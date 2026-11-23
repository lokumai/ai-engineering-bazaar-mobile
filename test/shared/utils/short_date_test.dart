import 'package:ai_engineering_bazaar/shared/utils/short_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  DateTime utc(DateTime moment) => moment;
  DateTime istanbul(DateTime moment) => moment.add(const Duration(hours: 3));

  // The web's SignOff.tsx shortDate: en-GB, the first ten characters.
  test('shortDate writes the day, the short month and the year', () {
    expect(shortDate('2026-10-11T08:00:00.000Z', local: utc), '11 Oct 2026');
    // en-GB writes Sept, as Node and intl 0.20.3 en_GB do.
    expect(shortDate('2026-09-03T20:59:00.000Z', local: utc), '3 Sept 2026');
    expect(shortDate('2026-01-31'), '31 Jan 2026');
    expect(shortDate('2026-12-01T00:00:00.000Z', local: utc), '1 Dec 2026');
  });

  // The owner, 2026-11-16: the Turkish line read "16 Nov 2026 tarihinde tamamlandı".
  // The owner, 2026-11-23: Latin digits in every language, as the web writes them (review 5, finding 6).
  test('shortDate writes the month in the reader language, with Latin digits', () {
    expect(shortDate('2026-11-16T08:00:00.000Z', language: 'tr', local: utc), '16 Kas 2026');
    expect(shortDate('2026-11-16T08:00:00.000Z', language: 'fa', local: utc), '16 نوامبر 2026');
    expect(shortDate('2026-11-16', language: 'tr'), '16 Kas 2026');
  });

  // A module finished at 01:30 in Istanbul is 22:30 the day before in UTC.
  test('shortDate dates a moment on the reader own day, a bare day as it is', () {
    expect(shortDate('2026-11-15T22:30:00.000Z', local: istanbul), '16 Nov 2026');
    expect(shortDate('2026-11-15T22:30:00.000Z', language: 'tr', local: istanbul), '16 Kas 2026');
    expect(shortDate('2026-11-15', local: istanbul), '15 Nov 2026');
  });

  test('shortDate keeps the first ten characters when they are not a real date', () {
    expect(shortDate('2026-13-40'), '2026-13-40');
    // A day that would roll over into the next month.
    expect(shortDate('2026-02-30T10:00:00.000Z'), '2026-02-30');
    expect(shortDate('not a date at all'), 'not a date');
  });
}
