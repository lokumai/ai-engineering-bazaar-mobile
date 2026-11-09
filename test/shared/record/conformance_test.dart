import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web's record conformance fixture (Task 6.1, generated, never edited), replayed the way the web's
/// `tests/unit/record/conformance.test.ts` drives it.
final Map<String, Object?> _fixture =
    jsonDecode(File('test/fixtures/record_conformance/v1.json').readAsStringSync()) as Map<String, Object?>;

List<Map<String, Object?>> _section(String name) => (_fixture[name]! as List).cast<Map<String, Object?>>();

void main() {
  // A fixture refresh that changes a count updates this line in the same commit, after reading what the web added.
  test('the fixture holds the sections and sizes this port was written against', () {
    expect(_fixture.keys, ['constants', 'parse', 'reduce', 'export', 'derive']);
    expect(
      [
        for (final name in ['parse', 'reduce', 'export', 'derive']) _section(name).length,
      ],
      [125, 14, 2, 8],
    );
  });

  group('constants', () {
    final constants = _fixture['constants']! as Map<String, Object?>;
    test(
      'are the seven the web names, in its order',
      () => expect(constants.keys, [
        'SCHEMA_VERSION',
        'SOFT_CAP_BYTES',
        'ISO_TIME',
        'ISO_DAY',
        'INSTANT_DAY',
        'EMPTY_SHEET',
        'EMPTY_RECORD',
      ]),
    );
    test('SCHEMA_VERSION', () => expect(RecordConstants.schemaVersion, constants['SCHEMA_VERSION']));
    test('SOFT_CAP_BYTES', () => expect(RecordConstants.softCapBytes, constants['SOFT_CAP_BYTES']));
    test('ISO_TIME', () => expect(RecordConstants.isoTime, constants['ISO_TIME']));
    test('ISO_DAY', () => expect(RecordConstants.isoDay, constants['ISO_DAY']));
    test('INSTANT_DAY', () => expect(RecordConstants.instantDay, constants['INSTANT_DAY']));
    // jsonEncode keeps insertion order, so these also pin the key order.
    test('EMPTY_SHEET', () => expect(jsonEncode(RecordConstants.emptySheet), jsonEncode(constants['EMPTY_SHEET'])));
    test('EMPTY_RECORD', () => expect(jsonEncode(RecordConstants.emptyRecord), jsonEncode(constants['EMPTY_RECORD'])));
  });

  // conformance.test.ts:154-174; the import chain, so envelopeTextFrom runs first (correction row 3.3.14).
  group('parse', () {
    for (final item in _section('parse')) {
      test(item['name']! as String, () {
        final text = item.containsKey('input')
            ? item['input']! as String
            : decodeRecordBytes(base64Decode(item['inputBase64']! as String));
        final answer = switch (parseEnvelope(envelopeTextFrom(text))) {
          EnvelopeEmpty() => {'kind': 'empty'},
          EnvelopeQuarantine(:final reason) => {'kind': 'quarantine', 'reason': reason.name},
          EnvelopeOk(:final data) => {
            'kind': 'ok',
            'reads': {
              'signed': data.signedMap(Track.engineers),
              'everyoneSigned': data.signedMap(Track.everyone),
              'days': data.days,
            },
          },
        };
        expect(answer, item['expect']); // maps compare unordered (the fixture writes JS key order); days is ordered
      });
    }
    test(
      'outcome counts',
      () => expect(
        [
          for (final kind in ['ok', 'empty', 'quarantine'])
            _section('parse').where((i) => (i['expect']! as Map)['kind'] == kind).length,
        ],
        [111, 4, 10],
      ),
    );
  });
}
