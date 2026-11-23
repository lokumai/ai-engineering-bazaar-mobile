import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

/// The vector the website's tests read too (`test/fixtures/transfer/vector-1.json`): a record, its compact text, and a
/// payload made by another DEFLATE (Python's zlib).
final _vector = jsonDecode(File('test/fixtures/transfer/vector-1.json').readAsStringSync()) as Map<String, Object?>;

RecordData _record(Map<String, Object?> data) => normaliseRecord(data);

TransferProgress _decoded(String text) => decodeTransfer(text)!;

void main() {
  group('encodeTransfer', () {
    test('writes the vector record as the vector compact text, byte for byte', () {
      expect(encodeTransfer(_record(_vector['recordData']! as Map<String, Object?>)), _vector['compactJson']);
    });

    test('carries a non-canonical instant as it is, and an empty record as empty maps', () {
      final record = _record({
        'sheets': {
          'a/b': {'signedOff': '2026-11-02', 'signedRevision': 'NOT-A-HASH'},
        },
      });
      expect(encodeTransfer(record), '{"v":1,"e":{"a/b":["2026-11-02","",[]]},"y":{},"d":[]}');
      expect(encodeTransfer(RecordData.empty), '{"v":1,"e":{},"y":{},"d":[]}');
    });

    // PROTOCOL.md: base36 only for a canonical instant at or after 1970; an earlier one has negative milliseconds,
    // whose base36 holds a '-', so it travels as its own text and reads back the same.
    test('reads the last instant of the year 9999, the last the record takes (plan 19.7)', () {
      final read = _decoded('{"v":1,"e":{"a/b":["2htner8qnz","",[]]},"y":{},"d":[]}');
      expect(read.engineers['a/b']!.signedOff, '9999-12-31T23:59:59.999Z');
    });

    test('carries an instant before 1970 as its own text, and reads it back', () {
      final record = _record({
        'sheets': {
          'a/b': {'signedOff': '1969-12-31T23:59:59.000Z', 'signedRevision': 'abcd'},
        },
      });
      final text = encodeTransfer(record);
      expect(text, '{"v":1,"e":{"a/b":["1969-12-31T23:59:59.000Z","abcd",[]]},"y":{},"d":[]}');
      expect(_decoded(text).engineers['a/b']!.signedOff, '1969-12-31T23:59:59.000Z');
    });
  });

  group('decodeTransfer', () {
    test('reads the vector: completions with their instants and revisions, ticks, days', () {
      final progress = _decoded(_vector['compactJson']! as String);
      expect(
        progress.engineers['alpha/first'],
        const TransferSheet(signedOff: '2026-11-02T09:15:30.123Z', signedRevision: 'a1b2c3d', ticks: [0, 2]),
      );
      expect(
        progress.engineers['alpha/second'],
        const TransferSheet(signedOff: null, signedRevision: null, ticks: [1]),
      );
      expect(progress.engineers, isNot(contains('beta/third')));
      expect(progress.everyone['alpha/first']!.signedRevision, '0f0e0d0');
      expect(progress.days, ['2026-11-01', '2026-11-02']);
      expect(progress.completed(Track.engineers), 1);
      expect(progress.completed(Track.everyone), 1);
      expect(progress.ticked(Track.engineers), 3);
      expect(progress.ticked(Track.everyone), 0);
    });

    test('encode then decode keeps the progress', () {
      final record = _record(_vector['recordData']! as Map<String, Object?>);
      final progress = _decoded(encodeTransfer(record));
      expect(mergeTransfer(RecordData.empty, progress).signedMap(Track.engineers), record.signedMap(Track.engineers));
      expect(mergeTransfer(RecordData.empty, progress).ticks('alpha/first', Track.engineers), {0, 2});
    });

    // PROTOCOL.md's leniency, as the website reads a link: unknown keys are passed over, a revision with no
    // completion is dropped, and ticks and days out of order or repeated are sorted once each.
    test('reads leniently what the website reads leniently', () {
      final progress = _decoded(
        '{"v":1,"x":true,"e":{"a/b":["","abcd",[3,1,3]]},"y":{},"d":["2026-11-02","2026-11-01","2026-11-02"]}',
      );
      expect(progress.engineers['a/b'], const TransferSheet(signedOff: null, signedRevision: null, ticks: [1, 3]));
      expect(progress.days, ['2026-11-01', '2026-11-02']);
    });

    test('an entry with neither a completion nor a tick adds nothing', () {
      final progress = _decoded('{"v":1,"e":{"a/b":["","",[]]},"y":{},"d":[]}');
      expect(identical(mergeTransfer(RecordData.empty, progress), RecordData.empty), isTrue);
      // Review 8, finding 16: the page offered Add for such a link, then said Nothing new.
      expect(progress.isEmpty, isTrue);
      expect(_decoded('{"v":1,"e":{},"y":{"a/b":["","",[2]]},"d":[]}').isEmpty, isFalse, reason: 'a tick');
      expect(_decoded('{"v":1,"e":{},"y":{},"d":["2026-11-01"]}').isEmpty, isFalse, reason: 'a day');
    });

    test('refuses the whole text when any part fails', () {
      const refused = [
        'not json',
        '[]',
        '{"v":2,"e":{},"y":{},"d":[]}',
        '{"v":1,"e":{},"y":{}}',
        '{"v":1,"e":{"__proto__":["","",[1]]},"y":{},"d":[]}',
        '{"v":1,"e":{"a/b":["","",[1],4]},"y":{},"d":[]}',
        '{"v":1,"e":{"a/b":["2026-13-40T00:00:00.000Z","",[]]},"y":{},"d":[]}',
        '{"v":1,"e":{"a/b":["ZZZ","",[]]},"y":{},"d":[]}',
        '{"v":1,"e":{"a/b":["mvz1mz0r","XYZ",[]]},"y":{},"d":[]}',
        '{"v":1,"e":{"a/b":["","",[10000]]},"y":{},"d":[]}',
        // Review 7, finding 14: a tick below 0 was refused by no test.
        '{"v":1,"e":{"a/b":["","",[-1]]},"y":{},"d":[]}',
        '{"v":1,"e":{"a/b":["","",["1"]]},"y":{},"d":[]}',
        '{"v":1,"e":{},"y":{},"d":["2026-02-30"]}',
        // An instant past the year 9999 (plan 19.7): the record's grammar would refuse its text.
        '{"v":1,"e":{"a/b":["2htner8qo0","",[]]},"y":{},"d":[]}',
      ];
      for (final text in refused) {
        expect(decodeTransfer(text), isNull, reason: text);
      }
      expect(decodeTransfer('{"v":1,"e":{},"y":{},"d":[]}${' ' * transferMaxText}'), isNull);
      // Review 7, finding 14: counted in bytes, as the packer counts; 'ş' is two.
      String withNote(int letters) => '{"v":1,"e":{},"y":{},"d":[],"note":"${'ş' * letters}"}';
      expect(
        decodeTransfer(withNote(transferMaxText ~/ 4)),
        isNotNull,
        reason: 'a key it does not know is passed over',
      );
      expect(withNote(transferMaxText ~/ 2).length, lessThan(transferMaxText));
      expect(decodeTransfer(withNote(transferMaxText ~/ 2)), isNull);
    });
  });

  group('mergeTransfer', () {
    // Review 7, finding 14: a hand-edited record's "03" sent tick 3, and its own link merged back added "3".
    test('a record merged with its own link is unchanged, a non-canonical tick key included', () {
      final record = _record({
        'sheets': {
          'a/b': {
            'checklist': {'03': true, '1': true},
          },
        },
      });
      expect(identical(mergeTransfer(record, _decoded(encodeTransfer(record))), record), isTrue);
    });

    final local = _record({
      'sheets': {
        'a/done': {
          'signedOff': '2026-10-01T00:00:00.000Z',
          'signedRevision': 'aaaa',
          'reachedEnd': true,
          'dwellSeconds': 300,
          'checklist': {'0': true},
        },
        'a/open': {'dwellSeconds': 20},
      },
      'days': ['2026-10-01'],
      'prefs': {'charKeys': false},
      'meta': {'lastExport': '2026-10-02T00:00:00.000Z'},
    });

    TransferProgress incoming(Map<String, TransferSheet> engineers, {List<String> days = const []}) =>
        TransferProgress(engineers: engineers, everyone: const {}, days: days);

    test('adds a module that is not here, with no dwell and no end reached', () {
      final merged = mergeTransfer(
        local,
        incoming({
          'b/new': const TransferSheet(signedOff: '2026-11-01T00:00:00.000Z', signedRevision: 'bbbb', ticks: [3]),
        }),
      );
      final sheet = (merged.raw['sheets']! as Map)['b/new'] as Map;
      expect(sheet, {
        'signedOff': '2026-11-01T00:00:00.000Z',
        'signedRevision': 'bbbb',
        'reachedEnd': false,
        'dwellSeconds': 0,
        'checklist': {'3': true},
      });
    });

    test('keeps a completion that is here with its own instant and revision, and unions the ticks', () {
      final merged = mergeTransfer(
        local,
        incoming({
          'a/done': const TransferSheet(signedOff: '2026-11-05T00:00:00.000Z', signedRevision: 'cccc', ticks: [1]),
        }),
      );
      final sheet = (merged.raw['sheets']! as Map)['a/done'] as Map;
      expect(sheet['signedOff'], '2026-10-01T00:00:00.000Z');
      expect(sheet['signedRevision'], 'aaaa');
      expect(sheet['dwellSeconds'], 300);
      expect(sheet['reachedEnd'], true);
      expect(sheet['checklist'], {'0': true, '1': true});
    });

    test('fills a completion that is not here and keeps its dwell', () {
      final merged = mergeTransfer(
        local,
        incoming({
          'a/open': const TransferSheet(signedOff: '2026-11-05T00:00:00.000Z', signedRevision: 'cccc', ticks: []),
        }),
      );
      final sheet = (merged.raw['sheets']! as Map)['a/open'] as Map;
      expect(sheet['signedOff'], '2026-11-05T00:00:00.000Z');
      expect(sheet['signedRevision'], 'cccc');
      expect(sheet['dwellSeconds'], 20);
    });

    test('unions the days and leaves prefs and meta alone', () {
      final merged = mergeTransfer(local, incoming(const {}, days: ['2026-09-30', '2026-10-01']));
      expect(merged.days, ['2026-09-30', '2026-10-01']);
      expect(merged.raw['prefs'], local.raw['prefs']);
      expect(merged.raw['meta'], local.raw['meta']);
    });

    test('returns the record itself when nothing is new', () {
      final unchanged = mergeTransfer(
        local,
        incoming(
          {
            'a/done': const TransferSheet(signedOff: '2026-11-05T00:00:00.000Z', signedRevision: 'cccc', ticks: [0]),
            'z/empty': const TransferSheet(signedOff: null, signedRevision: null, ticks: []),
          },
          days: ['2026-10-01'],
        ),
      );
      expect(unchanged, same(local));
    });

    test('a merged record reads back the same through the normaliser', () {
      final merged = mergeTransfer(local, _decoded(_vector['compactJson']! as String));
      expect(normaliseRecord(jsonDecode(jsonEncode(merged.raw)) as Map<String, Object?>), merged);
    });
  });
}
