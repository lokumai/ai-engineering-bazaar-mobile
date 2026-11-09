import 'package:ai_engineering_bazaar/shared/record/domain/instant.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the constants the fixture does not carry', () {
    expect(RecordConstants.shortHash, r'^[0-9a-f]{4,40}$'); // web validate.ts:56
    expect(RecordConstants.undoWindow, const Duration(seconds: 10)); // web erase.ts:99
    expect(RecordConstants.eraseWord, 'ERASE'); // web erase.ts:41
  });

  test('isRealDay accepts a calendar day that exists and nothing else', () {
    for (final day in ['2026-02-28', '2024-02-29', '0000-01-01', '9999-12-31']) {
      expect(isRealDay(day), isTrue, reason: day);
    }
    for (final day in [
      '2026-02-29',
      '2026-02-31',
      '2026-00-10',
      '2026-13-01',
      '2026-01-00',
      '2026-1-01',
      'yesterday',
      '',
    ]) {
      expect(isRealDay(day), isFalse, reason: day);
    }
  });

  test('asInstant accepts what V8 accepts with the T separator', () {
    for (final tail in [
      'T09:26',
      'T09:26:53',
      'T09:26:53.589Z',
      'T09:26:53.1234567',
      'T00:00',
      'T24:00',
      'T24:00Z',
      'T24:00:00',
      'T24:00:00.000',
      'T24:00+03:00',
      'T09:26+23:59',
      'T09:26-0530',
      'T09:26:53+0300',
      '',
    ]) {
      expect(asInstant('2026-03-14$tail'), '2026-03-14$tail', reason: tail);
    }
  });

  test('asInstant refuses what V8 refuses with the T separator', () {
    for (final tail in [
      'T09',
      'T9:26',
      'T09:2',
      'T0926',
      'T09:26:5',
      'T09:26:53.',
      'T24:00:00.001',
      'T24:00:01',
      'T25:00',
      'T23:60',
      'T23:59:60',
      'T09:26+3:00',
      'T09:26+24:00',
      'T09:26+03',
      'T09:26Z+03:00',
      'T12',
      'T--:--',
    ]) {
      expect(asInstant('2026-03-14$tail'), isNull, reason: tail);
    }
  });

  test('asInstant refuses a date that does not exist, a tail over ISO_TIME and anything not a string', () {
    expect(asInstant('2026-02-31T09:26:53.589Z'), isNull);
    expect(asInstant('2026-03-14T09:26:53.589123+03:00'), isNull); // 21-character tail, ISO_TIME refuses it
    expect(asInstant('yesterday'), isNull);
    expect(asInstant(''), isNull);
    expect(asInstant(1773480413589), isNull);
    expect(asInstant(null), isNull);
  });

  test('A20: a space-separated shape only V8 legacy parser accepts is a recorded divergence', () {
    expect(asInstant('2026-03-14 09:26:53.589Z'), '2026-03-14 09:26:53.589Z');
    for (final value in ['2026-03-14 9:26', '2026-03-14 Z', '2026-03-14 09::26', '2026-03-14 09:26+24:00']) {
      expect(asInstant(value), isNull, reason: '$value: V8 accepts it, the app does not (Decision A20)');
    }
  });

  test('dayOf reads the day of an instant and refuses one that does not exist', () {
    expect(dayOf('2026-03-14T09:26:53.589Z'), '2026-03-14');
    expect(dayOf('2026-03-14'), '2026-03-14');
    expect(dayOf('2026-03-14 anything'), '2026-03-14');
    expect(dayOf('2026-02-31T12:00:00.000Z'), isNull);
    expect(dayOf('2026-03-14x'), isNull);
    expect(dayOf('20260314'), isNull);
  });

  test('nowIso truncates to milliseconds', () {
    expect(withClock(Clock.fixed(DateTime.utc(2026, 11, 9, 1, 2, 3, 456, 789)), nowIso), '2026-11-09T01:02:03.456Z');
    expect(withClock(Clock.fixed(DateTime.utc(2026, 11, 9, 1, 2, 3)), nowIso), '2026-11-09T01:02:03.000Z');
  });

  test('Review Focus 3: a completion near midnight away from UTC is stamped with the UTC day', () {
    final local = DateTime.utc(2026, 3, 14, 22, 30).toLocal(); // 2026-03-15 07:30 in Tokyo
    final now = withClock(Clock.fixed(local), nowIso);
    expect(now, '2026-03-14T22:30:00.000Z');
    expect(dayOf(now), '2026-03-14');
    // Truncation, never rounding: rounding would move this instant to the next day.
    expect(withClock(Clock.fixed(DateTime.utc(2026, 3, 14, 23, 59, 59, 999, 999)), nowIso), '2026-03-14T23:59:59.999Z');
  });
}
