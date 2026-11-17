import 'package:ai_engineering_bazaar/features/catalog/application/topic_chips.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

ModuleNotes _module(String key, List<String> names) => ModuleNotes(
  moduleKey: key,
  terms: [
    for (final (i, name) in names.indexed)
      GlossaryTerm(moduleKey: key, index: i, name: name, forms: [name], definition: const []),
  ],
);

List<String> _names(List<GlossaryTerm> terms) => [for (final term in terms) term.name];

void main() {
  final modules = [
    _module('alpha/first', ['A1', 'A2']),
    _module('alpha/second', ['B1', 'B2', 'b1']),
    _module('beta/third', ['C1']),
    _module('beta/fourth', ['D1', 'D2', 'D3', 'D4', 'D5']),
  ];

  test("a new reader gets the first module's terms", () {
    final chips = topicChips(
      modules: modules,
      track: Track.engineers,
      record: RecordData.empty,
      places: const {},
      today: 1,
    );
    expect(_names(chips), ['A1', 'A2']);
  });

  test('the module being read first, then the modules completed last, each name once', () {
    final record = signOff(RecordData.empty, 'beta/third', 'abc1234', '2026-11-16T10:00:00.000Z');
    final places = {
      readingPlaceKey(Track.engineers, 'alpha/second'): ReadingPlace(
        heading: 'h',
        offset: 0,
        share: 0.5,
        at: DateTime.utc(2026, 11, 17),
      ),
    };
    final chips = topicChips(modules: modules, track: Track.engineers, record: record, places: places, today: 0);
    expect(_names(chips), ['B1', 'B2', 'C1'], reason: 'b1 is B1 again');
  });

  test('six at most, another six the next day', () {
    final record = [
      'alpha/first',
      'alpha/second',
      'beta/fourth',
    ].fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', '2026-11-16T10:00:00.000Z'));
    final one = topicChips(modules: modules, track: Track.engineers, record: record, places: const {}, today: 3);
    final two = topicChips(modules: modules, track: Track.engineers, record: record, places: const {}, today: 4);
    expect(one, hasLength(topicChipCount));
    expect(_names(one), isNot(_names(two)));
  });
}
