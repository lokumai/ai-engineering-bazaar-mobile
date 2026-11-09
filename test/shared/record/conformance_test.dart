import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web's record conformance fixture (Task 6.1, generated, never edited), replayed the way the web's
/// `tests/unit/record/conformance.test.ts` drives it.
final Map<String, Object?> _fixture =
    jsonDecode(File('test/fixtures/record_conformance/v1.json').readAsStringSync()) as Map<String, Object?>;

List<Map<String, Object?>> _section(String name) => (_fixture[name]! as List).cast<Map<String, Object?>>();

/// A [BundleIndex] carrying a derive case's synthetic index (`conformance.test.ts:430-434`): each level's `{slug,
/// total}` and each module's `{key, level, number}` with a track entry per track whose `drawn` is the case's; every
/// field the curriculum mapping does not read is a fixed placeholder.
BundleIndex _indexOf(Map<String, Object?> index) {
  ModuleTrack moduleTrack(Object? entry) => ModuleTrack(
    title: 'Title',
    drawn: (entry! as Map)['drawn']! as bool,
    summary: null,
    hasQuiz: false,
    revision: null,
    docs: const {},
    webPath: 'courses/placeholder/',
  );
  return BundleIndex(
    contentVersion: 'a' * 64,
    publishedAt: '2026-01-02T03:04:05.000Z',
    publishedAtInstant: DateTime.utc(2026, 1, 2, 3, 4, 5),
    tracks: const [
      TrackInfo(track: Track.engineers, label: 'For Engineers'),
      TrackInfo(track: Track.everyone, label: 'For Everyone'),
    ],
    diagramFont: DiagramFont(family: 'Vazirmatn', sha256: 'b' * 64),
    diagramThemes: const DiagramThemes(
      light: DiagramTheme(theme: 'default', backgroundArgb: 0xFFFFFFFF),
      dark: DiagramTheme(theme: 'dark', backgroundArgb: 0xFF000000),
    ),
    levels: [
      for (final level in (index['levels']! as List).cast<Map<String, Object?>>())
        LevelEntry(
          slug: level['slug']! as String,
          title: 'Title',
          status: LevelStatus.ready,
          blurb: 'Blurb',
          total: level['total']! as int,
          readme: null,
        ),
    ],
    modules: [
      for (final module in (index['modules']! as List).cast<Map<String, Object?>>())
        ModuleEntry(
          key: module['key']! as String,
          level: module['level']! as String,
          number: module['number']! as int,
          minutes: 10,
          prerequisites: const [],
          tracks: {for (final track in Track.values) track: moduleTrack((module['tracks']! as Map)[track.id])},
        ),
    ],
    moved: const Moved(levels: {}, modules: {}),
    files: const {},
    images: const {},
  );
}

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

  // conformance.test.ts:303-328; the no-op steps are the ones whose result is the same instance.
  group('reduce', () {
    for (final item in _section('reduce')) {
      test(item['name']! as String, () {
        var data = normaliseRecord(item['before']! as Map<String, Object?>);
        final steps = (item['steps']! as List).cast<Map<String, Object?>>();
        final unchanged = <int>[];
        for (final (index, step) in steps.indexed) {
          final track = step['track'] == null ? Track.engineers : Track.fromId(step['track']! as String)!;
          final now = step['now']! as String;
          final next = switch (step['op']) {
            'signOff' => signOff(data, step['slug']! as String, step['revision'] as String?, now, track: track),
            'unsign' => unsign(data, step['slug']! as String, track: track), // now is only the savedAt
            'markActivity' => markActivity(data, now),
            'markExported' => markExported(data, now),
            'erase' => erasedRecord(data),
            final op => throw StateError('unknown op $op'),
          };
          if (identical(next, data)) unchanged.add(index);
          data = next;
        }
        final expected = item['expect']! as Map<String, Object?>;
        expect(serialise(data, steps.last['now']! as String, pretty: false), expected['bytes']);
        expect(unchanged, expected['unchanged']);
      });
    }
  });

  // conformance.test.ts:421-426; the export path stamps the day, then writes the two-space form.
  group('export', () {
    for (final item in _section('export')) {
      test(item['name']! as String, () {
        final at = item['at']! as String;
        final result = parseEnvelope(envelopeTextFrom(item['input']! as String));
        expect(result, isA<EnvelopeOk>());
        final data = markActivity((result as EnvelopeOk).data, at);
        final expected = item['expect']! as Map<String, Object?>;
        expect(serialise(data, at, pretty: true), expected['bytes']);
        expect(exportFilename(at), expected['filename']);
      });
    }
  });
  // conformance.test.ts:464-497; every selector answers for each track through trackView.
  group('derive', () {
    for (final item in _section('derive')) {
      test(item['name']! as String, () {
        final record = normaliseRecord(item['record']! as Map<String, Object?>);
        final expected = item['expect']! as Map<String, Object?>;
        for (final track in Track.values) {
          final curriculum = curriculumFor(_indexOf(item['index']! as Map<String, Object?>), track);
          final view = trackView(record, track);
          final want = (expected['tracks']! as Map)[track.id] as Map<String, Object?>;
          expect({for (final fact in curriculum.modules) fact.slug: isSigned(fact, view)}, want['isSigned']);
          final progress = categoryProgress(view, curriculum);
          // Insertion order, as the web.
          expect(progress.keys.toList(), (want['categoryProgress']! as Map).keys.toList());
          expect({
            for (final e in progress.entries) e.key: {'approved': e.value.approved, 'total': e.value.total},
          }, want['categoryProgress']);
          expect(nextUnsigned(view, curriculum), want['nextUnsigned']);
          final count = signedCount(view, curriculum);
          expect({'signed': count.signed, 'toGo': count.toGo, 'of': count.of}, want['signedCount']);
        }
        expect(carriesNothing(record), expected['carriesNothing']);
        expect({'sheets': tally(record).sheets}, expected['tally']);
      });
    }
  });
}
