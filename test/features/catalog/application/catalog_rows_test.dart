import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/catalog_fixture_index.dart';

/// The record with `alpha/first` completed For Engineers (the reducer's default track), seen through [track].
RecordData view(Track track) =>
    trackView(signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-09T10:00:00.000Z'), track);

void main() {
  final index = catalogFixtureIndex();

  group('catalogRows', () {
    test('For Engineers rows in index order', () {
      final engineers = catalogRows(index, Track.engineers, view(Track.engineers));
      expect(engineers.map((r) => r.key), [
        'alpha/first',
        'alpha/second',
        'alpha/third',
        'beta/fourth',
        'beta/fifth',
        'gamma/sixth',
      ]);
      expect(engineers.map((r) => r.drawn), [true, true, false, true, false, true]);
      expect(engineers.map((r) => r.signed), [true, false, false, false, false, false]);
      expect(engineers[2].requires, [1, 2]);
      expect(engineers[0].summary, 'Summary of the first module.');
      expect(engineers[0].level, 'alpha');
      expect(engineers[0].number, 1);
      expect(engineers[0].minutes, 20);
    });

    test('For Everyone rows keep the For Engineers title and count only their own completions', () {
      final everyone = catalogRows(index, Track.everyone, view(Track.everyone));
      expect(everyone.map((r) => r.title).first, 'First Module'); // For Engineers title in both tracks
      expect(everyone.map((r) => r.drawn), [true, false, false, true, false, true]);
      expect(everyone.every((r) => !r.signed), isTrue); // a For Engineers completion does not count For Everyone
      expect(everyone[0].summary, 'Story of the first module.');
    });

    test('no view: nothing signed', () {
      expect(catalogRows(index, Track.engineers, null).any((r) => r.signed), isFalse);
    });

    test('titles are in the language, the English one where a module has none in it (web D139)', () {
      final titled = catalogFixtureIndex(
        titles: {
          'alpha/first': {'en': 'First Module', 'tr': 'Birinci Modül'},
        },
      );
      for (final track in Track.values) {
        final rows = catalogRows(titled, track, null, language: 'tr');
        expect(rows[0].title, 'Birinci Modül', reason: 'the For Engineers title in both tracks');
        expect(rows[1].title, 'Second Module');
      }
      expect(catalogRows(titled, Track.engineers, null).first.title, 'First Module');
      expect(catalogRows(titled, Track.engineers, null, language: 'fa').first.title, 'First Module');
    });
  });

  group('filters', () {
    final engineers = catalogRows(index, Track.engineers, view(Track.engineers));

    test('applyLevel', () {
      expect(applyLevel(engineers, 'beta').map((r) => r.number), [4, 5]);
      expect(applyLevel(engineers, null).length, 6);
    });

    test('levelsOf', () {
      expect(levelsOf(index, applyLevel(engineers, 'beta')).map((l) => l.slug), ['beta']);
      expect(levelsOf(index, engineers).map((l) => l.slug), ['alpha', 'beta', 'gamma']);
      expect(levelsOf(index, const []), isEmpty);
    });
  });
}
