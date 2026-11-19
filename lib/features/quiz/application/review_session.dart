import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/section_finder.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// One card of a Practice session (plan 13.3, 13.4): a quiz question or a term looked up.
sealed class ReviewItem extends Equatable {
  const ReviewItem({required this.key, required this.moduleTitle});

  /// The card's key in Practice's history.
  final String key;

  /// The title of the module it comes from.
  final String moduleTitle;

  String get moduleKey => moduleOfKey(key);
}

/// A quiz question, its options in the order shown: shuffled in Practice only (plan 13.6), so [item]'s `answer` is the
/// right option's place as shown.
final class QuestionItem extends ReviewItem {
  const QuestionItem({
    required super.key,
    required super.moduleTitle,
    required this.item,
    required this.length,
    this.section,
  });

  final QuizItem item;

  /// How many questions its module's quiz has.
  final int length;

  /// The section of its module that teaches it, which a wrong answer links to (plan 13.5); null when unsure.
  final FoundSection? section;

  @override
  List<Object?> get props => [key, moduleTitle, item, length, section];
}

/// A term asked as a question (plan 13.16): its definition, and which of [options], term names, it defines; graded as a
/// question is.
final class TermItem extends ReviewItem {
  const TermItem({
    required super.key,
    required super.moduleTitle,
    required this.term,
    required this.options,
    required this.answer,
    this.termsHeading,
  });

  final GlossaryTerm term;

  /// The term names to choose from, in the order shown: [term]'s and others.
  final List<String> options;

  /// [term]'s place in [options].
  final int answer;

  /// The heading of its module's Key Terms, which the verdict links to; null when the notes name none.
  final String? termsHeading;

  @override
  List<Object?> get props => [key, moduleTitle, term, options, answer, termsHeading];
}

/// How many options a term card offers at most (plan 13.16).
const termOptions = 4;

/// The options of a term card for [term] from [notes] (plan 13.16): its own name and up to three others, the others
/// picked by [random] from its module's Key Terms first, then its level's, then the rest of the track's, no name twice in
/// any case; then all shuffled. Null when no other term can stand beside it.
({List<String> options, int answer})? termChoices(GlossaryTerm term, StudyNotesReady notes, Random random) {
  String fold(String name) => name.trim().toLowerCase();
  final level = term.moduleKey.split('/').first;
  final names = <String>{fold(term.name)};
  final others = <String>[];
  for (final tier in [
    (GlossaryTerm other) => other.moduleKey == term.moduleKey,
    (GlossaryTerm other) => other.moduleKey != term.moduleKey && other.moduleKey.split('/').first == level,
    (GlossaryTerm other) => other.moduleKey.split('/').first != level,
  ]) {
    if (others.length >= termOptions - 1) break;
    final found = [
      for (final other in notes.terms)
        if (tier(other)) other.name,
    ]..shuffle(random);
    for (final name in found) {
      if (others.length >= termOptions - 1) break;
      if (names.add(fold(name))) others.add(name);
    }
  }
  if (others.isEmpty) return null;
  final options = [term.name, ...others]..shuffle(random);
  return (options: options, answer: options.indexOf(term.name));
}

/// The cards [keys] name, from [notes], each titled by [titleOf] its module; a key whose question or term the notes no
/// longer hold, or a term with no other to set beside it, is left out. [random] shuffles each card's options.
List<ReviewItem> reviewItems(
  List<String> keys,
  StudyNotesReady notes, {
  required String Function(String moduleKey) titleOf,
  required Random random,
}) => [for (final key in keys) ?_itemOf(key, notes, titleOf, random)];

ReviewItem? _itemOf(String key, StudyNotesReady notes, String Function(String) titleOf, Random random) {
  final module = notes.of(moduleOfKey(key));
  final index = indexOfKey(key);
  if (module == null) return null;
  if (isTermKey(key)) {
    final term = module.terms.elementAtOrNull(index);
    if (term == null) return null;
    final choices = termChoices(term, notes, random);
    if (choices == null) return null;
    return TermItem(
      key: key,
      moduleTitle: titleOf(module.moduleKey),
      term: term,
      options: choices.options,
      answer: choices.answer,
      termsHeading: module.termsHeading,
    );
  }
  final item = module.quiz.elementAtOrNull(index);
  if (item == null) return null;
  return QuestionItem(
    key: key,
    moduleTitle: titleOf(module.moduleKey),
    item: shuffled(item, random),
    length: module.quiz.length,
    section: sectionFor(item, module),
  );
}

/// [item] with its options in an order [random] picks, and its answer moved with them (plan 13.6). The web's
/// explanations name no option by its letter, so the explanation still reads right.
QuizItem shuffled(QuizItem item, Random random) {
  final order = List<int>.generate(item.options.length, (i) => i)..shuffle(random);
  return QuizItem(
    question: item.question,
    options: [for (final i in order) item.options[i]],
    answer: order.indexOf(item.answer),
    explain: item.explain,
  );
}

/// The next card of an endless review (the owner, 2026-11-18): one of [keys] at [random], repeats and all, but not
/// [last] again while another can be drawn; null when the notes hold none of them.
ReviewItem? drawItem(
  List<String> keys,
  StudyNotesReady notes, {
  required String Function(String moduleKey) titleOf,
  required Random random,
  String? last,
}) {
  final left = [...keys]..shuffle(random);
  if (left.length > 1 && left.first == last) left.add(left.removeAt(0));
  for (final key in left) {
    if (_itemOf(key, notes, titleOf, random) case final item?) return item;
  }
  return null;
}

/// A Practice session over [items], one card at a time (plan 13.3, 13.4): a question takes one answer, final, as in a
/// module's quiz, and a term is asked as one (plan 13.16). Each card's answer goes to [onAnswered] once, as it is given.
///
/// With [draw] it is endless (the owner, 2026-11-18): Next after the last card draws another, and [finish] ends it with
/// the cards answered.
///
/// A `Cubit` because every call is atomic and the event stream adds nothing.
final class ReviewSessionCubit extends Cubit<ReviewSessionState> {
  /// Throws an [ArgumentError] when [items] is empty.
  ReviewSessionCubit(List<ReviewItem> items, {required this.onAnswered, this.draw})
    : _items = items.isEmpty ? throw ArgumentError.value(items, 'items', 'No cards') : [...items],
      super(ReviewAt(index: 0, results: List.unmodifiable(List<bool?>.filled(items.length, null))));

  final List<ReviewItem> _items;

  /// The cards so far: all of them, or in an endless session those drawn.
  List<ReviewItem> get items => List.unmodifiable(_items);

  final void Function(ReviewItem item, bool right) onAnswered;

  /// The next card of an endless session after the one given; null for a session of fixed cards.
  final ReviewItem? Function(ReviewItem last)? draw;

  /// Whether Next after the last card draws another.
  bool get endless => draw != null;

  /// Answers the current card, a question or a term, with [option]; ignored once answered, or when the session is over.
  void pick(int option) {
    if (state case final ReviewAt at when at.pick == null && at.results[at.index] == null) {
      final (count, answer) = switch (_items[at.index]) {
        QuestionItem(:final item) => (item.options.length, item.answer),
        TermItem(:final options, :final answer) => (options.length, answer),
      };
      RangeError.checkValueInInterval(option, 0, count - 1, 'option');
      _answer(at, answer == option, pick: option);
    }
  }

  /// Shows the next card once the current one is answered: in an endless session one drawn after the last, else the
  /// results after the last.
  void next() {
    if (state case final ReviewAt at when at.results[at.index] != null) {
      if (at.index < _items.length - 1) return emit(ReviewAt(index: at.index + 1, results: at.results));
      final drawn = draw?.call(_items[at.index]);
      if (drawn == null) return emit(ReviewFinished(results: at.results));
      _items.add(drawn);
      emit(ReviewAt(index: at.index + 1, results: List.unmodifiable([...at.results, null])));
    }
  }

  /// Ends an endless session at once, with the cards answered; the card shown unanswered is left out.
  void finish() {
    if (state case final ReviewAt at) {
      final answered = at.answered ? at.index + 1 : at.index;
      _items.length = answered;
      emit(ReviewFinished(results: List.unmodifiable(at.results.take(answered))));
    }
  }

  void _answer(ReviewAt at, bool right, {required int pick}) {
    final results = List<bool?>.of(at.results)..[at.index] = right;
    emit(ReviewAt(index: at.index, results: List.unmodifiable(results), pick: pick));
    onAnswered(_items[at.index], right);
  }
}

sealed class ReviewSessionState extends Equatable {
  const ReviewSessionState();
}

/// Card [index] shown: [results] holds each card's answer once given; [pick] is the option picked on it.
final class ReviewAt extends ReviewSessionState {
  const ReviewAt({required this.index, required this.results, this.pick});

  final int index;
  final List<bool?> results;
  final int? pick;

  bool get answered => results[index] != null;

  @override
  List<Object?> get props => [index, results, pick];
}

/// Every card answered.
final class ReviewFinished extends ReviewSessionState {
  const ReviewFinished({required this.results});

  final List<bool?> results;

  int get right => results.where((result) => result ?? false).length;

  @override
  List<Object?> get props => [results];
}
