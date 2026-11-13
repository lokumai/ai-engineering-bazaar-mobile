import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter_test/flutter_test.dart';

const now = '2026-03-15T07:10:00.000Z';

RecordData withSheets(Map<String, Object?> sheets) => normaliseRecord({'sheets': sheets});

Map<String, Object?> sheetsOf(RecordData data, [String key = 'sheets']) => data.raw[key]! as Map<String, Object?>;

void main() {
  test('signOff over a raw signedOff the views do not accept is not a no-op', () {
    final before = withSheets({
      'a': {'signedOff': 'yesterday', 'reachedEnd': true},
    });
    final after = signOff(before, 'a', 'a1b2c3d', now);
    expect(after, isNot(same(before)));
    expect(after.signedOff('a', Track.engineers), now);
    expect((sheetsOf(after)['a']! as Map)['reachedEnd'], isTrue);
    expect(after.days, ['2026-03-15']);
  });
  test('signOff on a completed module is a no-op', () {
    final before = withSheets({
      'a': {'signedOff': '2026-03-14T09:26:53.589Z'},
    });
    expect(signOff(before, 'a', 'a1b2c3d', now), same(before));
  });
  test('signOff with an unsafe slug is a no-op', () {
    expect(signOff(RecordData.empty, '__proto__', null, now), same(RecordData.empty));
    expect(signOff(RecordData.empty, '', null, now), same(RecordData.empty));
  });
  test('signOff on a day already recorded adds no day; a day that does not exist stamps none', () {
    final once = signOff(RecordData.empty, 'a', null, now);
    expect(signOff(once, 'b', null, '2026-03-15T23:59:59.999Z').days, ['2026-03-15']);
    final impossible = signOff(RecordData.empty, 'a', null, '2026-02-31T07:10:00.000Z');
    expect(impossible.signedOff('a', Track.engineers), isNull);
    expect((sheetsOf(impossible)['a']! as Map)['signedOff'], '2026-02-31T07:10:00.000Z');
    expect(impossible.days, isEmpty);
  });
  test('days stay sorted when an earlier day is stamped', () {
    final later = signOff(RecordData.empty, 'a', null, now);
    expect(signOff(later, 'b', null, '2026-03-01T00:00:00.000Z').days, ['2026-03-01', '2026-03-15']);
  });
  test('signOff For Everyone writes everyoneSheets only', () {
    final after = signOff(RecordData.empty, 'a', 'a1b2c3d', now, track: Track.everyone);
    expect(sheetsOf(after), isEmpty);
    expect(after.signedOff('a', Track.everyone), now);
  });
  test('unsign over values the views read as null is a no-op', () {
    final before = withSheets({
      'a': {'signedOff': 'yesterday', 'signedRevision': 'XYZ', 'reachedEnd': true},
    });
    expect(unsign(before, 'a'), same(before));
  });
  test('unsign of a module with no entry is a no-op', () {
    expect(unsign(RecordData.empty, 'a'), same(RecordData.empty));
    expect(unsign(RecordData.empty, 'a', track: Track.everyone), same(RecordData.empty));
  });
  test('unsign clears a revision the view accepts even with no sign-off', () {
    final before = withSheets({
      'a': {'signedOff': null, 'signedRevision': 'a1b2c3d'},
    });
    final after = unsign(before, 'a');
    expect((sheetsOf(after)['a']! as Map)['signedRevision'], isNull);
    expect(after.days, isEmpty);
  });
  test('unsign keeps the emptied entry and stamps no day', () {
    final signed = signOff(RecordData.empty, 'a', 'a1b2c3d', now, track: Track.everyone);
    final after = unsign(signed, 'a', track: Track.everyone);
    expect(sheetsOf(after, 'everyoneSheets').keys, ['a']);
    expect(after.signedOff('a', Track.everyone), isNull);
    expect(after.days, ['2026-03-15']);
  });
  test('a new slug is appended last; an existing one keeps its place and its key order', () {
    final before = withSheets({
      'a': {'reachedEnd': true},
      'b': {'reachedEnd': true},
    });
    expect(sheetsOf(signOff(before, 'c', null, now)).keys, ['a', 'b', 'c']);
    final again = signOff(before, 'a', null, now);
    expect(sheetsOf(again).keys, ['a', 'b']);
    expect((sheetsOf(again)['a']! as Map).keys, [
      'signedOff',
      'signedRevision',
      'reachedEnd',
      'dwellSeconds',
      'checklist',
    ]);
  });
  test('the reducers return deeply unmodifiable records', () {
    final after = signOff(RecordData.empty, 'a', null, now);
    expect(() => sheetsOf(after)['b'] = 1, throwsUnsupportedError);
    expect(() => (after.raw['days']! as List).add('x'), throwsUnsupportedError);
    expect(() => (sheetsOf(after)['a']! as Map)['x'] = 1, throwsUnsupportedError);
    expect(() => after.raw['x'] = 1, throwsUnsupportedError);
    final exported = markExported(RecordData.empty, now);
    expect(() => (exported.raw['meta']! as Map)['x'] = 1, throwsUnsupportedError);
  });
  test('markActivity stamps the day once', () {
    final once = markActivity(RecordData.empty, now);
    expect(once.days, ['2026-03-15']);
    expect(markActivity(once, '2026-03-15T08:00:00.000Z'), same(once));
  });
  test('markExported sets lastExport in place and stamps the day; the same instant again is a no-op', () {
    final after = markExported(RecordData.empty, now);
    expect((after.raw['meta']! as Map).keys, ['lastExport', 'persisted']);
    expect((after.raw['meta']! as Map)['lastExport'], now);
    expect(after.days, ['2026-03-15']);
    expect(markExported(after, now), same(after));
  });
  test('erasedRecord is the empty record itself', () => expect(erasedRecord(withSheets({})), same(RecordData.empty)));
  test('confirmsErase trims with the JS set and ignores case', () {
    for (final typed in ['ERASE', ' erase ', 'Erase\u3000']) {
      expect(confirmsErase(typed), isTrue, reason: typed);
    }
    for (final typed in ['E RASE', 'ERASE\u0085', 'ERASED', '']) {
      expect(confirmsErase(typed), isFalse, reason: typed);
    }
  });
  test("confirmsErase takes the interface language's word, the Turkish i's as one, and ERASE in every language", () {
    for (final typed in ['SİL', 'sil', ' Sil ', 'SIL', 'sıl', 'ERASE']) {
      expect(confirmsErase(typed, localWord: 'SİL'), isTrue, reason: typed);
    }
    for (final typed in ['حذف', ' حذف ', 'erase']) {
      expect(confirmsErase(typed, localWord: 'حذف'), isTrue, reason: typed);
    }
    for (final typed in ['SİLİN', 'S IL', 'sl', '']) {
      expect(confirmsErase(typed, localWord: 'SİL'), isFalse, reason: typed);
    }
    expect(confirmsErase('SİL'), isFalse, reason: 'no local word, ERASE only');
  });
  test('A21: a record written before the tracks, completed For Everyone, keeps everyoneSheets after sheets', () {
    final before = (parseEnvelope(
      '{"schema":1,"savedAt":"2026-03-14T08:00:00.000Z","data":{"sheets":{"alpha/first":'
      '{"signedOff":"2026-03-14T09:26:53.589Z","signedRevision":"a1b2c3d","reachedEnd":false,"dwellSeconds":0,'
      '"checklist":{}}},"days":["2026-03-14"],"prefs":{"charKeys":true,"railFolded":false,"catalogView":null,'
      '"diagramTheme":null,"codePalette":null},"meta":{"lastExport":null,"persisted":null}}}',
    ) as EnvelopeOk).data;
    final after = signOff(before, 'alpha/second', 'a1b2c3d', now, track: Track.everyone);
    expect(
      serialise(after, now, pretty: false),
      '{"schema":1,"savedAt":"2026-03-15T07:10:00.000Z","data":{"sheets":{"alpha/first":{"signedOff":'
      '"2026-03-14T09:26:53.589Z","signedRevision":"a1b2c3d","reachedEnd":false,"dwellSeconds":0,"checklist":{}}},'
      '"everyoneSheets":{"alpha/second":{"signedOff":"2026-03-15T07:10:00.000Z","signedRevision":"a1b2c3d",'
      '"reachedEnd":false,"dwellSeconds":0,"checklist":{}}},"days":["2026-03-14","2026-03-15"],"prefs":{"charKeys":'
      'true,"railFolded":false,"catalogView":null,"diagramTheme":null,"codePalette":null},"meta":{"lastExport":null,'
      '"persisted":null}}}',
    );
  });

  group('setChecklistItem (web events.ts setChecklistItem)', () {
    Map<String, Object?> checklistOf(RecordData data, [String key = 'sheets']) =>
        (sheetsOf(data, key)['a']! as Map)['checklist']! as Map<String, Object?>;

    test('a tick writes true under the index and stamps the day', () {
      final after = setChecklistItem(RecordData.empty, 'a', 3, now, ticked: true);
      expect(checklistOf(after), {'3': true});
      expect(after.ticks('a', Track.engineers), {3});
      expect(after.days, ['2026-03-15']);
    });

    test('taking a tick away deletes its key, and keeps the others as they are', () {
      final before = withSheets({
        'a': {
          'checklist': {'1': true, '3': true, 'x': 'kept'},
        },
      });
      final after = setChecklistItem(before, 'a', 3, now, ticked: false);
      expect(checklistOf(after), {'1': true, 'x': 'kept'});
      expect(after.ticks('a', Track.engineers), {1});
    });

    test('an item already as asked, an index out of range or an unsafe slug is a no-op', () {
      final ticked = setChecklistItem(RecordData.empty, 'a', 0, now, ticked: true);
      expect(setChecklistItem(ticked, 'a', 0, now, ticked: true), same(ticked));
      expect(setChecklistItem(RecordData.empty, 'a', 0, now, ticked: false), same(RecordData.empty));
      expect(setChecklistItem(RecordData.empty, 'a', -1, now, ticked: true), same(RecordData.empty));
      expect(setChecklistItem(RecordData.empty, 'a', 10000, now, ticked: true), same(RecordData.empty));
      expect(setChecklistItem(RecordData.empty, '__proto__', 0, now, ticked: true), same(RecordData.empty));
    });

    test('For Everyone writes everyoneSheets only', () {
      final after = setChecklistItem(RecordData.empty, 'a', 2, now, ticked: true, track: Track.everyone);
      expect(sheetsOf(after), isEmpty);
      expect(checklistOf(after, 'everyoneSheets'), {'2': true});
      expect(after.ticks('a', Track.everyone), {2});
      expect(after.ticks('a', Track.engineers), isEmpty);
    });

    test('ticks reads only a key of one to four digits holding true (web coerceChecklist)', () {
      final data = withSheets({
        'a': {
          'checklist': {'0': true, '1': false, '2': 'true', '12345': true, '-1': true, 'x': true, '9999': true},
        },
        'b': {'checklist': 'none'},
      });
      expect(data.ticks('a', Track.engineers), {0, 9999});
      expect(data.ticks('b', Track.engineers), isEmpty);
      expect(data.ticks('c', Track.engineers), isEmpty);
    });
  });
}
