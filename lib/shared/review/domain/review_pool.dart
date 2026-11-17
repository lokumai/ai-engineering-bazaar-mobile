import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// The cards Practice can offer in a track (plan 13.3, 13.4), from the modules' notes and the record.
final class ReviewPool extends Equatable {
  const ReviewPool({
    required this.completed,
    required this.questions,
    required this.terms,
    required this.everyQuestion,
  });

  /// The modules completed in the track, in the course's order.
  final List<String> completed;

  /// The question keys of [completed], in the course's order: those Today's review takes.
  final List<String> questions;

  /// The term keys of every module in the track.
  final List<String> terms;

  /// The question keys of every module in the track: those Wrong answers can hold.
  final List<String> everyQuestion;

  /// Today's review on [today] from [history].
  List<String> today(ReviewHistory history, int today) =>
      todaysReview(history, questions: questions, terms: terms, today: today);

  /// Wrong answers from [history].
  List<String> wrong(ReviewHistory history) => wrongAnswers(history, questions: everyQuestion);

  @override
  List<Object?> get props => [completed, questions, terms, everyQuestion];
}

/// The pool of [track] from the notes of its [modules], in the course's order, and the [record].
ReviewPool reviewPool({required Track track, required RecordData record, required List<ModuleNotes> modules}) {
  final view = trackView(record, track);
  final completed = [
    for (final notes in modules)
      if (view.signedOff(notes.moduleKey, Track.engineers) != null) notes.moduleKey,
  ];
  List<String> questionsOf(ModuleNotes notes) => [
    for (var i = 0; i < notes.quiz.length; i++) questionKey(notes.moduleKey, i),
  ];
  final byKey = {for (final notes in modules) notes.moduleKey: notes};
  return ReviewPool(
    completed: completed,
    questions: [for (final key in completed) ...questionsOf(byKey[key]!)],
    terms: [
      for (final notes in modules)
        for (final term in notes.terms) termKey(track, notes.moduleKey, term.index),
    ],
    everyQuestion: [for (final notes in modules) ...questionsOf(notes)],
  );
}
