import 'package:ai_engineering_bazaar/features/home/application/daily_card.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/catalog_fixture_index.dart';
import '../../../support/content_builders.dart';

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

HeadingBlock _h(String id, String text, {int depth = 2}) => HeadingBlock(
  depth: depth,
  id: id,
  mark: null,
  inlines: [TextInline(text: text)],
);

void main() {
  group('dayNumber', () {
    test('turns at local midnight, not before', () {
      expect(dayNumber(DateTime(2026, 11, 16, 23, 59)), dayNumber(DateTime(2026, 11, 16)));
      expect(dayNumber(DateTime(2026, 11, 17)), dayNumber(DateTime(2026, 11, 16)) + 1);
    });
  });

  // A UTC clock east of UTC once read the UTC date as the local one: the next midnight fell in the past, the card's
  // timer fired at once and armed itself again, and the app froze (CI at UTC+14, 2026-11-17).
  group('untilLocalMidnight', () {
    test('a UTC moment waits for the next local midnight, never less than none', () {
      final halfPastMidnight = DateTime(2026, 11, 9, 0, 30);
      const wait = Duration(hours: 23, minutes: 30, seconds: 1);
      expect(untilLocalMidnight(halfPastMidnight), wait);
      expect(untilLocalMidnight(halfPastMidnight.toUtc()), wait);
    });
  });

  group('dayNumber of a UTC moment', () {
    test('is the local day', () {
      final halfPastMidnight = DateTime(2026, 11, 9, 0, 30);
      expect(dayNumber(halfPastMidnight.toUtc()), dayNumber(halfPastMidnight));
    });
  });

  group('dailyChoice', () {
    final index = catalogFixtureIndex();
    RecordData completed(List<String> keys) =>
        keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', '2026-11-09T10:00:00.000Z'));
    List<String> week(RecordData record, {String language = 'en'}) => [
      for (var day = 0; day < 7; day++)
        ?dailyChoice(index, Track.engineers, record, language: language, day: day)?.moduleKey,
    ];

    test('a new reader is shown the first three modules written in the track, a day each, round and round', () {
      expect(week(RecordData.empty), [
        'alpha/first',
        'alpha/second',
        'beta/fourth',
        'alpha/first',
        'alpha/second',
        'beta/fourth',
        'alpha/first',
      ], reason: 'alpha/third is not written For Engineers');
    });

    test('the modules completed come back, before the next three not completed', () {
      expect(week(completed(['alpha/second'])).take(4), ['alpha/second', 'alpha/first', 'beta/fourth', 'gamma/sixth']);
    });

    test('each time round, the card goes on to the module\'s next section', () {
      final turns = [
        for (final day in [0, 3, 6]) dailyChoice(index, Track.engineers, RecordData.empty, language: 'en', day: day),
      ];
      expect(
        [for (final choice in turns) (choice!.moduleKey, choice.turn)],
        [('alpha/first', 0), ('alpha/first', 1), ('alpha/first', 2)],
      );
      expect(turns.first!.docPath, 'api/v1/modules/alpha/first/en.json');
    });

    // The owner, 2026-11-16: finishing the day's module turned the card to another module.
    test('a module completed on the day itself leaves the day on the card it opened on', () {
      final day = dayNumber(DateTime(2026, 11, 16));
      final morning = dailyChoice(index, Track.engineers, RecordData.empty, language: 'en', day: day)!;
      final evening = signOff(
        RecordData.empty,
        morning.moduleKey,
        'abc1234',
        DateTime(2026, 11, 16, 15).toUtc().toIso8601String(),
      );
      expect(dailyChoice(index, Track.engineers, evening, language: 'en', day: day), morning);
      expect(
        dailyChoice(index, Track.engineers, evening, language: 'en', day: day + 1),
        isNot(dailyChoice(index, Track.engineers, RecordData.empty, language: 'en', day: day + 1)),
        reason: 'the next day it counts as completed',
      );
    });

    test('no card in a language the course is not written in', () {
      expect(dailyChoice(index, Track.engineers, RecordData.empty, language: 'tr', day: 0), isNull);
    });
  });

  group('dailyCardOf', () {
    final doc = testDoc(
      title: 'Tool Belts',
      body: [
        _p('An opening.'),
        _h('why', 'Why tools'),
        _p('Models call tools. They read what comes back. Then they answer.'),
        _h('deep', 'A deeper heading', depth: 3),
        _p('More prose.'),
        _h('empty', 'Only a picture'),
        _h('how', 'How a call runs'),
        _p('The model names a tool.'),
        _h('summary', 'Summary'),
        _p('A recap.'),
      ],
    );

    test('a turn each, it goes through the sections that teach, leaving out a recap and one with no prose', () {
      expect([for (var turn = 0; turn < 3; turn++) dailyCardOf(doc, turn: turn)!.sectionId], ['why', 'how', 'why']);
    });

    test('it quotes the section\'s first sentences under its heading, with the module\'s title', () {
      final card = dailyCardOf(doc, turn: 0)!;
      expect(card.heading, 'Why tools');
      expect(card.module, 'Tool Belts');
      expect(card.moduleKey, 'alpha/first');
      expect(card.lead, 'Models call tools. They read what comes back. Then they answer. A deeper heading More prose.');
    });

    test('a module with no section to show gives its opening, opened at its top', () {
      final card = dailyCardOf(testDoc(title: 'Short', body: [_p('Just this.')]), turn: 4)!;
      expect((card.heading, card.sectionId, card.lead), ('Short', null, 'Just this.'));
    });

    test('a module not written yet gives no card', () {
      expect(dailyCardOf(testDoc(), turn: 0), isNull);
    });
  });

  group('leadOf', () {
    test('takes whole sentences up to the length', () {
      expect(leadOf('One two. Three four. Five six.', length: 20), 'One two. Three four.');
    });

    test('always takes the first sentence, and cuts one far too long at a word', () {
      final long = List.filled(60, 'word').join(' ');
      final lead = leadOf(long, length: 40);
      expect(lead.endsWith('…'), isTrue);
      expect(lead.length, lessThanOrEqualTo(41));
      expect(lead.contains('wor…'), isFalse, reason: 'it is cut between words');
    });
  });
}
