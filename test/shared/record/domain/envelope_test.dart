import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null, empty and JS whitespace are empty', () {
    for (final raw in [null, '', ' \n\t ', '\uFEFF\u3000']) {
      expect(parseEnvelope(raw), isA<EnvelopeEmpty>(), reason: '$raw');
    }
  });

  test(
    'U+0085 is not JS whitespace, so it is malformed',
    () => expect(parseEnvelope('\u0085'), const EnvelopeQuarantine(reason: QuarantineReason.malformed, raw: '\u0085')),
  );

  test('the schema rule', () {
    expect((parseEnvelope('{"schema":1.0,"data":{}}') as EnvelopeOk).schema, 1);
    expect(
      parseEnvelope('{"schema":2}'),
      const EnvelopeQuarantine(reason: QuarantineReason.newer, raw: '{"schema":2}'),
    );
    for (final schema in ['1e400', '-0.0', '0', '1.5', '"1"', 'null']) {
      expect(
        (parseEnvelope('{"schema":$schema,"data":{}}') as EnvelopeQuarantine).reason,
        QuarantineReason.malformed,
        reason: schema,
      );
    }
  });

  test(
    'a top-level array is malformed for the launch read',
    () => expect((parseEnvelope('[{"schema":1,"data":{}}]') as EnvelopeQuarantine).reason, QuarantineReason.malformed),
  );

  test('envelopeTextFrom', () {
    expect(envelopeTextFrom('\uFEFF {"a":1} \n'), '{"a":1}');
    expect(envelopeTextFrom('\u0085{}'), isNull);
    expect(envelopeTextFrom('[{}]'), isNull);
    expect(envelopeTextFrom('<!doctype html>'), isNull);
  });

  test('broken JSON, a missing schema and data that is not an object are malformed, keeping the raw text', () {
    for (final raw in ['{', '{"data":{}}', '{"schema":1}', '{"schema":1,"data":[]}', '{"schema":1,"data":"x"}']) {
      expect(
        parseEnvelope(raw),
        EnvelopeQuarantine(reason: QuarantineReason.malformed, raw: raw),
        reason: raw,
      );
    }
  });

  test('an ok envelope carries the normalised data', () {
    final result = parseEnvelope(
      '{"schema":1,"data":{"sheets":{"e":{"signedOff":"2026-03-14T09:26:53.589Z"}},"days":["2026-03-14"]}}',
    );
    expect(result, isA<EnvelopeOk>());
    final ok = result as EnvelopeOk;
    expect(ok.schema, 1);
    expect(ok.data.raw.keys, ['sheets', 'everyoneSheets', 'days', 'prefs', 'meta']);
    expect(ok.data.signedMap(Track.engineers), {'e': '2026-03-14T09:26:53.589Z'});
    expect(ok.data.days, ['2026-03-14']);
  });

  // Review 7 finding 13, review 8 finding 1: a backup nested deeper than the stack ended the restore without a word,
  // and catching the overflow held on one machine and not on another; the depth is counted.
  group('a record nested past the depth limit is malformed', () {
    String nested(int lists) => '{"schema":1,"data":{"x":${'[' * lists}${']' * lists}}}';

    test('the data map and lists to the limit are a record', () {
      expect(parseEnvelope(nested(maxRecordDepth - 1)), isA<EnvelopeOk>());
    });

    for (final lists in [maxRecordDepth, 8000, 10000]) {
      test('$lists lists deep is malformed', () {
        expect(
          parseEnvelope(nested(lists)),
          isA<EnvelopeQuarantine>().having((quarantine) => quarantine.reason, 'reason', QuarantineReason.malformed),
        );
      });
    }
  });
}
