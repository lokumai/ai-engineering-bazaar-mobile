import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const signed = {
    'signedOff': '2026-03-14T09:26:53.589Z',
    'signedRevision': 'a1b2c3d',
    'reachedEnd': false,
    'dwellSeconds': 0,
    'checklist': <String, Object?>{},
  };

  test('A21: a record written before the tracks gets everyoneSheets right after sheets', () {
    final data = normaliseRecord({
      'sheets': {'alpha/first': signed},
      'days': ['2026-03-14'],
      'prefs': RecordConstants.emptyRecord['prefs'],
      'meta': RecordConstants.emptyRecord['meta'],
    });
    expect(data.raw.keys, ['sheets', 'everyoneSheets', 'days', 'prefs', 'meta']);
    expect(data.raw['everyoneSheets'], isEmpty);
  });

  test('A21: template keys first in template order, then unknown keys in their order', () {
    final data = normaliseRecord({
      'zeta': 1,
      'meta': {'x': 2},
      'days': [],
      'prefs': {'railFolded': true, 'zz': 1},
      'sheets': {
        'alpha/first': {
          'x': 1,
          'checklist': {'3': true},
          'signedOff': '2026-03-14T09:26:53.589Z',
        },
      },
    });
    expect(data.raw.keys, ['sheets', 'everyoneSheets', 'days', 'prefs', 'meta', 'zeta']);
    expect(
      jsonEncode((data.raw['sheets']! as Map)['alpha/first']),
      '{"signedOff":"2026-03-14T09:26:53.589Z","signedRevision":null,"reachedEnd":false,"dwellSeconds":0,'
      '"checklist":{"3":true},"x":1}',
    );
    expect(
      jsonEncode(data.raw['prefs']),
      '{"charKeys":true,"railFolded":true,"catalogView":null,"diagramTheme":null,"codePalette":null,"zz":1}',
    );
    expect(jsonEncode(data.raw['meta']), '{"lastExport":null,"persisted":null,"x":2}');
  });

  test('a prefs or meta that is not an object reads as the template', () {
    final data = normaliseRecord({
      'prefs': 'x',
      'meta': [1],
    });
    expect(jsonEncode(data.raw['prefs']), jsonEncode(RecordConstants.emptyRecord['prefs']));
    expect(jsonEncode(data.raw['meta']), jsonEncode(RecordConstants.emptyRecord['meta']));
  });

  test('a sheet map drops unsafe keys, non-objects and empty entries, and keeps unknown-valued ones raw', () {
    final data = normaliseRecord({
      'sheets': {
        '__proto__': signed,
        'a': 'signed',
        'b': {
          'quiz': {'q': 1},
        },
        'c': {'signedOff': 'yesterday'},
        'd': {'signedOff': 'yesterday', 'reachedEnd': true},
        'e': signed,
      },
    });
    expect((data.raw['sheets']! as Map).keys, ['d', 'e']);
    expect(((data.raw['sheets']! as Map)['d'] as Map)['signedOff'], 'yesterday');
    expect(data.signedOff('d', Track.engineers), isNull);
    expect(data.signedMap(Track.engineers), {'e': '2026-03-14T09:26:53.589Z'});
  });

  test('a sheet map that is not an object reads as empty, for both tracks', () {
    final data = normaliseRecord({'sheets': [], 'everyoneSheets': 'x'});
    expect(data.raw['sheets'], isEmpty);
    expect(data.raw['everyoneSheets'], isEmpty);
  });

  test('days keeps distinct real days, sorted', () {
    expect(
      normaliseRecord({
        'days': ['2026-03-14', '2026-03-01', '2026-03-14', '2026-02-31', 20260301],
      }).days,
      ['2026-03-01', '2026-03-14'],
    );
    expect(normaliseRecord({'days': 'x'}).days, isEmpty);
  });

  test('the record is deeply unmodifiable', () {
    final data = normaliseRecord({
      'sheets': {'e': signed},
      'extra': {
        'list': [1],
      },
    });
    expect(() => (data.raw['sheets']! as Map)['x'] = 1, throwsUnsupportedError);
    expect(() => ((data.raw['extra']! as Map)['list'] as List).add(2), throwsUnsupportedError);
    expect(() => data.raw['days'] = [], throwsUnsupportedError);
  });

  test(
    'RecordData.empty is the template',
    () => expect(jsonEncode(RecordData.empty.raw), jsonEncode(RecordConstants.emptyRecord)),
  );

  test('the views read the track named, and sheetsKey names its map', () {
    expect(sheetsKey(Track.engineers), 'sheets');
    expect(sheetsKey(Track.everyone), 'everyoneSheets');
    final data = normaliseRecord({
      'everyoneSheets': {'e': signed},
    });
    expect(data.signedOff('e', Track.everyone), '2026-03-14T09:26:53.589Z');
    expect(data.signedOff('e', Track.engineers), isNull);
    expect(data.signedOff('missing', Track.everyone), isNull);
    expect(data.signedMap(Track.everyone), {'e': '2026-03-14T09:26:53.589Z'});
    expect(data.signedMap(Track.engineers), isEmpty);
  });

  test('isEmptySheetEntry compares each template field and ignores unknown keys', () {
    expect(isEmptySheetEntry(const {}), isTrue);
    expect(isEmptySheetEntry(RecordConstants.emptySheet), isTrue);
    expect(isEmptySheetEntry(const {'quiz': 1, 'signedOff': 'yesterday'}), isTrue);
    expect(isEmptySheetEntry(const {'signedOff': '2026-03-14'}), isFalse);
    expect(isEmptySheetEntry(const {'signedRevision': 'a1b2c3d'}), isFalse);
    expect(isEmptySheetEntry(const {'reachedEnd': true}), isFalse);
    expect(isEmptySheetEntry(const {'dwellSeconds': 3}), isFalse);
    expect(isEmptySheetEntry(const {'dwellSeconds': 0.0}), isTrue);
    expect(
      isEmptySheetEntry(const {
        'checklist': {'0': true},
      }),
      isFalse,
    );
    expect(isEmptySheetEntry(const {'checklist': 'x'}), isFalse);
  });

  test('records compare by value', () {
    expect(normaliseRecord(const {}), RecordData.empty);
    expect(
      normaliseRecord({
        'sheets': {'e': signed},
      }),
      isNot(RecordData.empty),
    );
  });
}
