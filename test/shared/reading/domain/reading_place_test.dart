import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 11, 9, 30);

  test('each track keeps its own place of a module', () {
    expect(readingPlaceKey(Track.engineers, 'alpha/first'), 'engineers:alpha/first');
    expect(readingPlaceKey(Track.everyone, 'alpha/first'), 'everyone:alpha/first');
  });

  group('the file', () {
    test('reads back what it wrote', () {
      final places = {
        'engineers:alpha/first': ReadingPlace(heading: 'one', offset: 120.5, share: 0.4, at: at),
        'everyone:beta/fourth': ReadingPlace(offset: 300, share: 0.1, at: at),
      };
      final text = encodeReadingPlaces(places);
      expect(text, contains('"schema":1'));
      expect(text, isNot(contains('"heading":null')), reason: 'a place above the first heading writes no heading');
      expect(decodeReadingPlaces(text), places);
    });

    test('keeps the seconds on the screen, and reads a file kept before as none (the owner, 2026-11-18)', () {
      final place = ReadingPlace(offset: 0, share: 0, at: at, seconds: 312);
      final text = encodeReadingPlaces({'engineers:alpha/first': place});
      expect(text, contains('"seconds":312'));
      expect(decodeReadingPlaces(text).values.single, place);
      expect(encodeReadingPlaces({'engineers:alpha/first': place.withSeconds(0)}), isNot(contains('seconds')));
      final before = decodeReadingPlaces(
        '{"schema":1,"places":{"engineers:alpha/first":{"offset":0,"share":0,"at":"2026-11-11T09:30:00.000Z"}}}',
      );
      expect(before.values.single.seconds, 0);
      final odd = decodeReadingPlaces(
        '{"schema":1,"places":{"engineers:alpha/first":{"offset":0,"share":0,"at":"2026-11-11T09:30:00.000Z",'
        '"seconds":"many"}}}',
      );
      expect(odd.values.single.seconds, 0, reason: 'seconds not a count read as none, the place kept');
    });

    test('a file that is not the shape reads as no place', () {
      for (final text in ['', 'not json', '[]', '{"schema":2,"places":{}}', '{"schema":1}']) {
        expect(decodeReadingPlaces(text), isEmpty, reason: text);
      }
    });

    test('a place that is not the shape is left out', () {
      const good = '{"offset":10,"share":0.5,"at":"2026-11-11T09:30:00.000Z"}';
      final text =
          '{"schema":1,"places":{"engineers:a/good":$good,'
          '"engineers:a/negative":{"offset":-1,"share":0.5,"at":"2026-11-11T09:30:00.000Z"},'
          '"engineers:a/share":{"offset":1,"share":1.5,"at":"2026-11-11T09:30:00.000Z"},'
          '"engineers:a/time":{"offset":1,"share":0.5,"at":"yesterday"},'
          '"engineers:a/text":"far"}}';
      expect(decodeReadingPlaces(text).keys, ['engineers:a/good']);
    });

    // Review 9, finding 15: a heading less than a pixel below the top gave an offset a little under 0, which the
    // decoder drops.
    test('a place a little above its heading reads back at the heading', () {
      final place = ReadingPlace(heading: 'why', offset: -0.4, share: 0.3, at: DateTime.utc(2026, 11, 24), seconds: 9);
      final read = decodeReadingPlaces(encodeReadingPlaces({'engineers:a/b': place}));
      expect(
        read['engineers:a/b'],
        ReadingPlace(heading: 'why', offset: 0, share: 0.3, at: DateTime.utc(2026, 11, 24), seconds: 9),
      );
    });

    // Review 8, finding 16: an offset of 1e999 read as infinity, which the next save could not write, so every later
    // place was lost.
    test('an offset too large to be a number is left out, and the places still save', () {
      const text =
          '{"schema":1,"places":{"engineers:a/far":{"offset":1e999,"share":0.5,"at":"2026-11-11T09:30:00.000Z"}}}';
      final places = decodeReadingPlaces(text);
      expect(places, isEmpty);
      expect(() => encodeReadingPlaces(places), returnsNormally);
    });
  });
}
