/// Where in its module a quiz question is taught (plan 13.5): the section whose words the question and its right answer
/// share most, weighed by how few other sections hold them. The web's quiz files name no section, so the app finds it by
/// the words, and offers no link when it is not sure.
library;

import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// A section of a module found for a question: its heading and the words the find bar marks there.
final class FoundSection extends Equatable {
  const FoundSection({required this.heading, required this.title, required this.words});

  /// The heading's id, to open the module at it.
  final String heading;

  /// The heading's words.
  final String title;

  /// The question's words the section holds that few other sections do, the rarest first and the longest of those
  /// alike: what the find bar marks.
  final List<String> words;

  @override
  List<Object?> get props => [heading, title, words];
}

/// How much more the best section must weigh than the next for the link to be offered.
const _lead = 1.5;

/// The least weight a section must have: about two words that few sections hold.
const _least = 2.0;

/// The most words the find bar marks.
const _marked = 3;

/// The section of the module [notes] are of where [item] is taught, or null when no section clearly is. Only the
/// sections that teach the module count (`ModuleNotes.sections`): the Key Terms, the Summary and the References restate
/// it.
FoundSection? sectionFor(QuizItem item, ModuleNotes notes) {
  final lang = notes.lang;
  final sections = notes.sections;
  if (sections.length < 2) return null;
  final asked = {
    for (final word in tokenize('${item.question} ${item.options[item.answer]}'))
      if (normalise(word, lang) case final term when term.length >= 3) term,
  };
  if (asked.isEmpty) return null;
  final words = [for (final section in sections) _wordsOf(section.text, lang)];
  bool holds(Set<String> held, String term) =>
      held.contains(term) || (term.length >= 4 && held.any((word) => word.startsWith(term)));
  final rarity = {
    for (final term in asked)
      term: math.log((sections.length + 1) / (words.where((held) => holds(held, term)).length + 0.5)),
  };
  final weights = [
    for (final held in words)
      [
        for (final term in asked)
          if (holds(held, term) && rarity[term]! > 0) term,
      ],
  ];
  double weightOf(List<String> terms) => terms.fold(0, (sum, term) => sum + rarity[term]!);
  final order = List<int>.generate(sections.length, (i) => i)
    ..sort((a, b) => weightOf(weights[b]).compareTo(weightOf(weights[a])));
  final best = weightOf(weights[order[0]]);
  final next = weightOf(weights[order[1]]);
  if (best < _least || best < next * _lead) return null;
  final section = sections[order[0]];
  // The find bar marks the rarest words; a short word or a number marks too much of the text to help.
  final marked = [
    for (final term in weights[order[0]])
      if (term.length >= 4 && int.tryParse(term) == null) term,
  ]..sort((a, b) => rarity[a] != rarity[b] ? rarity[b]!.compareTo(rarity[a]!) : b.length.compareTo(a.length));
  return FoundSection(heading: section.id, title: section.title, words: marked.take(_marked).toList());
}

/// The normalised words of [text].
Set<String> _wordsOf(String text, String lang) => {
  for (final word in tokenize(text))
    if (normalise(word, lang) case final term when term.length >= 2) term,
};
