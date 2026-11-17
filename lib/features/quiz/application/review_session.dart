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

/// A term looked up: the term, then its definition when asked, then whether it was known.
final class TermItem extends ReviewItem {
  const TermItem({required super.key, required super.moduleTitle, required this.term});

  final GlossaryTerm term;

  @override
  List<Object?> get props => [key, moduleTitle, term];
}

/// The cards [keys] name, from [notes], each titled by [titleOf] its module; a key whose question or term the notes no
/// longer hold is left out. [random] shuffles each question's options.
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
    return term == null ? null : TermItem(key: key, moduleTitle: titleOf(module.moduleKey), term: term);
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

/// A Practice session over [items], one card at a time (plan 13.3, 13.4): a question takes one answer, final, as in a
/// module's quiz; a term shows its definition when asked, then is marked known or not yet. Each card's answer goes to
/// [onAnswered] once, as it is given.
///
/// A `Cubit` because every call is atomic and the event stream adds nothing.
final class ReviewSessionCubit extends Cubit<ReviewSessionState> {
  /// Throws an [ArgumentError] when [items] is empty.
  ReviewSessionCubit(List<ReviewItem> items, {required this.onAnswered})
    : items = List.unmodifiable(items.isEmpty ? throw ArgumentError.value(items, 'items', 'No cards') : items),
      super(ReviewAt(index: 0, results: List.unmodifiable(List<bool?>.filled(items.length, null))));

  final List<ReviewItem> items;

  final void Function(ReviewItem item, bool right) onAnswered;

  /// Answers the current question with [option]; ignored on a term, once answered, or when the session is over.
  void pick(int option) {
    if (state case final ReviewAt at when at.pick == null && at.results[at.index] == null) {
      if (items[at.index] case final QuestionItem question) {
        RangeError.checkValueInInterval(option, 0, question.item.options.length - 1, 'option');
        _answer(at, question.item.answer == option, pick: option);
      }
    }
  }

  /// Shows the current term's definition.
  void reveal() {
    if (state case final ReviewAt at when items[at.index] is TermItem && !at.revealed) {
      emit(ReviewAt(index: at.index, results: at.results, revealed: true));
    }
  }

  /// Marks the current term, once its definition is shown, as known or not yet.
  void judge({required bool knew}) {
    if (state case final ReviewAt at when items[at.index] is TermItem && at.revealed && at.results[at.index] == null) {
      _answer(at, knew, revealed: true);
    }
  }

  /// Shows the next card once the current one is answered, or the results after the last.
  void next() {
    if (state case final ReviewAt at when at.results[at.index] != null) {
      emit(
        at.index == items.length - 1
            ? ReviewFinished(results: at.results)
            : ReviewAt(index: at.index + 1, results: at.results),
      );
    }
  }

  void _answer(ReviewAt at, bool right, {int? pick, bool revealed = false}) {
    final results = List<bool?>.of(at.results)..[at.index] = right;
    emit(ReviewAt(index: at.index, results: List.unmodifiable(results), pick: pick, revealed: revealed));
    onAnswered(items[at.index], right);
  }
}

sealed class ReviewSessionState extends Equatable {
  const ReviewSessionState();
}

/// Card [index] shown: [results] holds each card's answer once given; [pick] is the option picked on a question, and
/// [revealed] whether a term's definition is shown.
final class ReviewAt extends ReviewSessionState {
  const ReviewAt({required this.index, required this.results, this.pick, this.revealed = false});

  final int index;
  final List<bool?> results;
  final int? pick;
  final bool revealed;

  bool get answered => results[index] != null;

  @override
  List<Object?> get props => [index, results, pick, revealed];
}

/// Every card answered.
final class ReviewFinished extends ReviewSessionState {
  const ReviewFinished({required this.results});

  final List<bool?> results;

  int get right => results.where((result) => result ?? false).length;

  @override
  List<Object?> get props => [results];
}
