import 'package:ai_engineering_bazaar/features/quiz/application/section_finder.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

ModuleNotes _notes(Map<String, String> sections) => ModuleNotes(
  moduleKey: 'alpha/first',
  sections: [
    for (final MapEntry(:key, :value) in sections.entries) NoteSection(id: key, title: 'Title of $key', text: value),
  ],
);

QuizItem _q(String question, String answer) =>
    QuizItem(question: question, options: [answer, 'Something else'], answer: 0, explain: 'E');

void main() {
  final notes = _notes({
    'lamps': 'A lantern holds a flame behind glass. The lantern is carried by hand at night.',
    'oil': 'The wick draws paraffin up from the reservoir, and the flame burns the paraffin.',
    'care': 'Trim the wick and clean the glass, so the light stays bright and steady.',
  });

  test('finds the section whose rare words the question and its answer share, and marks the rarest', () {
    final found = sectionFor(_q('What does the wick draw up from the reservoir?', 'Paraffin'), notes);
    expect(found?.heading, 'oil');
    expect(found?.title, 'Title of oil');
    expect(found?.words, containsAll(['paraffin', 'reservoir']));
    expect(found!.words.length, lessThanOrEqualTo(3));
  });

  test('offers no section when two weigh alike, or none weighs enough', () {
    expect(
      sectionFor(_q('What is the glass for?', 'The wick'), notes),
      isNull,
      reason: 'glass and wick are in two each',
    );
    expect(sectionFor(_q('Why?', 'Because'), notes), isNull);
  });

  test('a module of one section offers none', () {
    expect(sectionFor(_q('Paraffin reservoir wick?', 'Paraffin'), _notes({'one': 'paraffin reservoir wick'})), isNull);
  });

  test('a short word or a number is not marked', () {
    final found = sectionFor(_q('How many wicks draw paraffin from the 1850 reservoir?', 'Two'), notes);
    expect(found?.heading, 'oil');
    expect(found!.words.where((word) => word.length < 4 || int.tryParse(word) != null), isEmpty);
  });
}
