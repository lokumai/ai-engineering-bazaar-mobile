import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/listen_place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListenPlace (the owner, 2026-11-18)', () {
    test('heard whole once every part is heard', () {
      const place = ListenPlace(count: 3, heard: {0, 2});
      expect(place.heardAll, isFalse);
      expect(place.hearing(1).heardAll, isTrue);
      expect(place.at(1).heard, {0, 2}, reason: 'moving on keeps what was heard');
      expect(const ListenPlace(count: 3).isEmpty, isTrue);
      expect(const ListenPlace(count: 3, index: 0).isEmpty, isFalse);
    });

    test('a file keeps the places and reads them back', () {
      final places = {
        listenPlaceKey('alpha/first', Track.engineers): const ListenPlace(count: 4, index: 2, heard: {0, 1}),
        listenPlaceKey('alpha/first', Track.everyone): const ListenPlace(count: 2, heard: {1}),
      };
      expect(decodeListenPlaces(encodeListenPlaces(places)), places);
      expect(listenPlaceKey('alpha/first', Track.engineers), 'engineers/alpha/first');
    });

    test('a file of another shape, or a place out of its bounds, reads as nothing of it', () {
      expect(decodeListenPlaces('not json'), isEmpty);
      expect(decodeListenPlaces('{"schema": 2, "places": {}}'), isEmpty);
      expect(
        decodeListenPlaces(
          '{"schema": 1, "places": {"a": {"count": 0}, "b": {"count": 2, "index": 5, "heard": [1, 7, "x"]}}}',
        ),
        {
          'b': const ListenPlace(count: 2, heard: {1}),
        },
      );
    });
  });
}
