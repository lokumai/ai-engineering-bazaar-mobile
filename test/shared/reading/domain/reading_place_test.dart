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
  });
}
