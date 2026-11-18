/// Each question's latest answer of a quiz (plan 13.17), which Practice's quizzes by level read.
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
