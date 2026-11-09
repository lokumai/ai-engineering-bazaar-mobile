import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fact = CurriculumFact(slug: 'a', number: 1, level: 'l', drawn: true);

  test(
    'trackView of For Engineers is the record itself',
    () => expect(trackView(RecordData.empty, Track.engineers), same(RecordData.empty)),
  );

  test('trackView of For Everyone reads everyoneSheets under sheets, at the same position', () {
    final data = normaliseRecord({
      'everyoneSheets': {
        'a': {'signedOff': '2026-03-14'},
      },
    });
    final view = trackView(data, Track.everyone);
    expect(view.raw.keys, data.raw.keys);
    expect(view.signedOff('a', Track.engineers), '2026-03-14');
    expect(isSigned(fact, view), isTrue);
    expect(isSigned(fact, data), isFalse);
  });

  test('trackView of For Everyone is deeply unmodifiable', () {
    final view = trackView(normaliseRecord({}), Track.everyone);
    expect(() => view.raw['sheets'] = const {}, throwsUnsupportedError);
  });

  test('isSigned is false for a module that is not drawn, even when completed', () {
    final data = normaliseRecord({
      'sheets': {
        'a': {'signedOff': '2026-03-14'},
      },
    });
    expect(isSigned(fact, data), isTrue);
    expect(isSigned(const CurriculumFact(slug: 'a', number: 1, level: 'l', drawn: false), data), isFalse);
  });

  test('isSigned reads signedOff through asInstant', () {
    final data = normaliseRecord({
      'sheets': {
        'a': {'signedOff': 'yesterday', 'reachedEnd': true},
      },
    });
    expect(isSigned(fact, data), isFalse);
  });

  test('signedCount counts every module in of, drawn or not', () {
    const curriculum = Curriculum(
      levels: [],
      modules: [
        CurriculumFact(slug: 'a', number: 1, level: 'l', drawn: true),
        CurriculumFact(slug: 'b', number: 2, level: 'l', drawn: false),
        CurriculumFact(slug: 'c', number: 3, level: 'l', drawn: true),
      ],
    );
    final data = normaliseRecord({
      'sheets': {
        'a': {'signedOff': '2026-03-14'},
        'b': {'signedOff': '2026-03-14'},
      },
    });
    expect(signedCount(data, curriculum), const SignedCount(signed: 1, toGo: 2, of: 3));
  });

  test('categoryProgress lists declared levels first, then undeclared ones counted from their modules', () {
    const curriculum = Curriculum(
      levels: [
        LevelTotal(slug: 'z', total: 9),
        LevelTotal(slug: 'l', total: 4),
      ],
      modules: [
        CurriculumFact(slug: 'a', number: 1, level: 'l', drawn: true),
        CurriculumFact(slug: 'b', number: 2, level: 'new', drawn: true),
        CurriculumFact(slug: 'c', number: 3, level: 'new', drawn: false),
      ],
    );
    final data = normaliseRecord({
      'sheets': {
        'a': {'signedOff': '2026-03-14'},
        'b': {'signedOff': '2026-03-14'},
      },
    });
    final progress = categoryProgress(data, curriculum);
    expect(progress.keys, ['z', 'l', 'new']);
    expect(progress, {
      'z': const LevelCount(approved: 0, total: 9),
      'l': const LevelCount(approved: 1, total: 4),
      'new': const LevelCount(approved: 1, total: 2),
    });
  });

  test('nextUnsigned sorts by number and keeps the listed order on a tie', () {
    const curriculum = Curriculum(
      levels: [],
      modules: [
        CurriculumFact(slug: 'b', number: 2, level: 'l', drawn: true),
        CurriculumFact(slug: 'c', number: 1, level: 'l', drawn: true),
        CurriculumFact(slug: 'd', number: 1, level: 'l', drawn: true),
      ],
    );
    expect(nextUnsigned(RecordData.empty, curriculum), 'c');
  });

  test('nextUnsigned skips modules that are not drawn or are completed, and is null when none is left', () {
    const curriculum = Curriculum(
      levels: [],
      modules: [
        CurriculumFact(slug: 'a', number: 1, level: 'l', drawn: false),
        CurriculumFact(slug: 'b', number: 2, level: 'l', drawn: true),
        CurriculumFact(slug: 'c', number: 3, level: 'l', drawn: true),
      ],
    );
    final data = normaliseRecord({
      'sheets': {
        'b': {'signedOff': '2026-03-14'},
      },
    });
    expect(nextUnsigned(data, curriculum), 'c');
    final all = normaliseRecord({
      'sheets': {
        'b': {'signedOff': '2026-03-14'},
        'c': {'signedOff': '2026-03-14'},
      },
    });
    expect(nextUnsigned(all, curriculum), isNull);
  });

  test('carriesNothing and tally read both maps and ignore prefs', () {
    expect(
      carriesNothing(
        normaliseRecord({
          'prefs': {'charKeys': false},
        }),
      ),
      isTrue,
    );
    expect(
      carriesNothing(
        normaliseRecord({
          'everyoneSheets': {
            'a': {'reachedEnd': true},
          },
        }),
      ),
      isFalse,
    );
    expect(
      carriesNothing(
        normaliseRecord({
          'meta': {'lastExport': '2026-03-14T00:00:00.000Z'},
        }),
      ),
      isFalse,
    );
    expect(
      tally(
        normaliseRecord({
          'sheets': {
            'a': {'reachedEnd': true},
          },
          'everyoneSheets': {
            'a': {'reachedEnd': true},
          },
        }),
      ),
      const Tally(sheets: 2),
    );
  });

  test('carriesNothing is false when a day is recorded', () {
    expect(
      carriesNothing(
        normaliseRecord({
          'days': ['2026-03-14'],
        }),
      ),
      isFalse,
    );
    expect(carriesNothing(RecordData.empty), isTrue);
    expect(tally(RecordData.empty), const Tally(sheets: 0));
  });
}
