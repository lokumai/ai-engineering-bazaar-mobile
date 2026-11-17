/// Which cards Practice offers (plan 13.3, 13.4): Today's review and Wrong answers, from the history and the cards the
/// course holds.
library;

import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';

/// The most cards Today's review takes in a day (plan 13.3).
const reviewDaily = 5;

/// About how many minutes [cards] cards take, half a minute each, at least one.
int reviewMinutes(int cards) => cards <= 0 ? 0 : (cards + 1) ~/ 2;

/// The cards Today's review offers on [today], at most what is left of [reviewDaily] that day, in order (plan 13.3):
/// the questions answered wrong that are due, then the other questions due, then the terms looked up that are due,
/// then the questions never answered (the owner, 2026-11-17: a reader who read but never took a quiz has a review too).
///
/// [questions] are the question keys of the completed modules, in the order new ones are asked; [terms] the term keys
/// of the reader's track that the course still holds. A card kept for a question or a term no longer offered is left
/// out. Cards due on the same day keep the order of [questions] and [terms].
List<String> todaysReview(
  ReviewHistory history, {
  required List<String> questions,
  required List<String> terms,
  required int today,
}) {
  final left = reviewDaily - history.doneOn(today);
  if (left <= 0) return const [];
  final cards = history.cards;
  List<String> due(Iterable<String> keys, bool Function(ReviewCard card) which) {
    final found = [
      for (final (position, key) in keys.indexed)
        if (cards[key] case final card? when card.dueOn(today) && which(card))
          (position: position, key: key, due: card.due),
    ];
    found.sort((a, b) => a.due != b.due ? a.due.compareTo(b.due) : a.position.compareTo(b.position));
    return [for (final entry in found) entry.key];
  }

  return [
    ...due(questions, (card) => card.wrong),
    ...due(questions, (card) => !card.wrong),
    ...due(terms, (_) => true),
    for (final key in questions)
      if (!cards.containsKey(key)) key,
  ].take(left).toList();
}

/// The questions of [questions] in Wrong answers (plan 13.4), in that order: answered wrong, and not right
/// [ReviewCard.rightToLeave] times in a row since.
List<String> wrongAnswers(ReviewHistory history, {required List<String> questions}) => [
  for (final key in questions)
    if (history.cards[key]?.wrong ?? false) key,
];
