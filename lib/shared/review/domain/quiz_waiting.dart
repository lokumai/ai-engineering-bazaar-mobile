/// Which quiz a reader has not taken yet (plan 13.17), and each question's latest answer, which Practice's quizzes by
/// level and Home both read.
library;

import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';

/// Each question's latest answer of the module [moduleKey]'s quiz in [history], null for one never answered; null when
/// none is answered, or the history holds no length for the quiz.
List<bool?>? latestAnswers(ReviewHistory history, String moduleKey) {
  final length = history.lengths[moduleKey];
  if (length == null) return null;
  final answers = [
    for (var i = 0; i < length; i++) history.cards[questionKey(moduleKey, i)]?.answers.lastOrNull?.right,
  ];
  return answers.every((answer) => answer == null) ? null : answers;
}

/// The first of [completed], in its order (the course's), whose quiz has questions ([quizLength]), was never finished
/// on this device ([finished]), and has not had every question answered in Practice; null when none waits.
String? quizWaiting(
  List<String> completed, {
  required int Function(String moduleKey) quizLength,
  required bool Function(String moduleKey) finished,
  required ReviewHistory history,
}) {
  for (final key in completed) {
    final length = quizLength(key);
    if (length == 0 || finished(key)) continue;
    final answers = latestAnswers(history, key);
    if (answers != null && answers.length >= length && answers.every((answer) => answer != null)) continue;
    return key;
  }
  return null;
}
