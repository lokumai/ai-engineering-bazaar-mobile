import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';

/// Practice's history on this device (plan 13.1): every card answered or looked up, with how many cards Today's review
/// took on its day. Like the quiz scores, it is the app's own data: never in the record, which stays the web's byte
/// for byte, and never in the backup file. Settings' reset erases it.
final class ReviewHistory extends Equatable {
  const ReviewHistory({this.cards = const {}, this.lengths = const {}, this.day = 0, this.done = 0});

  static const empty = ReviewHistory();

  /// Every card kept, by its question or term key.
  final Map<String, ReviewCard> cards;

  /// How many questions each module's quiz had when its questions were answered, by module key: a quiz whose length
  /// changed with a content update is another quiz, and its questions start afresh.
  final Map<String, int> lengths;

  /// The day [done] counts.
  final int day;

  /// How many cards Today's review took on [day].
  final int done;

  /// How many cards Today's review took on [today].
  int doneOn(int today) => day == today ? done : 0;

  bool get isEmpty => cards.isEmpty && done == 0;

  /// The history after [key] was answered on [today], [right] or not; [length] is its module quiz's length for a
  /// question, and [inReview] counts the card in Today's review.
  ReviewHistory answered(String key, {required bool right, required int today, int? length, bool inReview = false}) {
    var history = length == null || isTermKey(key) ? this : seenLength(moduleOfKey(key), length);
    final cards = {...history.cards, key: ReviewCard.after(history.cards[key], right: right, today: today)};
    return ReviewHistory(
      cards: cards,
      lengths: history.lengths,
      day: inReview ? today : history.day,
      done: inReview ? history.doneOn(today) + 1 : history.done,
    );
  }

  /// The history after the term [key] was looked up on [today]: a term not kept yet comes up tomorrow (plan 13.3); one
  /// kept already stays as it is.
  ReviewHistory lookedUp(String key, int today) {
    if (cards.containsKey(key)) return this;
    return ReviewHistory(cards: {...cards, key: ReviewCard.lookedUp(today)}, lengths: lengths, day: day, done: done);
  }

  /// The history once the quiz of [moduleKey] is seen with [length] questions: the questions kept for a quiz of
  /// another length are dropped.
  ReviewHistory seenLength(String moduleKey, int length) {
    final kept = lengths[moduleKey];
    if (kept == length) return this;
    return ReviewHistory(
      cards: kept == null
          ? cards
          : {
              for (final MapEntry(:key, :value) in cards.entries)
                if (isTermKey(key) || moduleOfKey(key) != moduleKey) key: value,
            },
      lengths: {...lengths, moduleKey: length},
      day: day,
      done: done,
    );
  }

  /// This history from before a reset, with [now], the history since, on top: each card answered since as it is now,
  /// and the count of the later day.
  ReviewHistory under(ReviewHistory now) {
    final cards = {...this.cards};
    final lengths = {...this.lengths};
    for (final MapEntry(key: module, value: length) in now.lengths.entries) {
      if (lengths[module] != length) cards.removeWhere((key, _) => !isTermKey(key) && moduleOfKey(key) == module);
      lengths[module] = length;
    }
    cards.addAll(now.cards);
    final later = now.day >= day;
    return ReviewHistory(cards: cards, lengths: lengths, day: later ? now.day : day, done: later ? now.done : done);
  }

  @override
  List<Object?> get props => [cards, lengths, day, done];
}

/// The version of the file's shape; a file of another version reads as empty.
const reviewHistorySchema = 1;

/// The history as the file keeps it, one line: `{"schema":1,"day":20409,"done":2,"lengths":{"alpha/first":5},`
/// `"cards":{"alpha/first#0":{"box":1,"due":20410,"run":1,"wrong":false,"answers":[[20409,1]]}}}`.
String encodeReviewHistory(ReviewHistory history) => jsonEncode({
  'schema': reviewHistorySchema,
  'day': history.day,
  'done': history.done,
  'lengths': history.lengths,
  'cards': {
    for (final MapEntry(:key, value: card) in history.cards.entries)
      key: {
        'box': card.box,
        'due': card.due,
        'run': card.run,
        'wrong': card.wrong,
        'answers': [
          for (final answer in card.answers) [answer.day, answer.right ? 1 : 0],
        ],
      },
  },
});

/// The history in [text]; anything that does not read as the file's shape reads as empty, and a card that does not is
/// left out. The history is a convenience: losing it costs a few cards asked again, never progress.
ReviewHistory decodeReviewHistory(String text) {
  try {
    if (jsonDecode(text)
        case {
          'schema': reviewHistorySchema,
          'day': final int day,
          'done': final int done,
          'lengths': final Map<String, Object?> lengths,
          'cards': final Map<String, Object?> cards,
        }
        when done >= 0) {
      return ReviewHistory(
        day: day,
        done: done,
        lengths: {
          for (final MapEntry(:key, :value) in lengths.entries)
            // A quiz's length past any a module has is a damaged file (review 6, finding 15).
            if (value is int && value > 0 && value <= maxQuizLength) key: value,
        },
        cards: {for (final MapEntry(:key, :value) in cards.entries) key: ?_cardFrom(key, value)},
      );
    }
  } on FormatException {
    // Falls through to empty.
  }
  return ReviewHistory.empty;
}

ReviewCard? _cardFrom(String key, Object? json) {
  if (!key.contains('#') || int.tryParse(key.substring(key.lastIndexOf('#') + 1)) == null) return null;
  if (json
      case {
        'box': final int box,
        'due': final int due,
        'run': final int run,
        'wrong': final bool wrong,
        'answers': final List<Object?> answers,
      }
      when box >= 0 && box <= ReviewCard.top && run >= 0) {
    return ReviewCard(
      box: box,
      due: due,
      run: run,
      wrong: wrong,
      answers: List.unmodifiable([
        for (final answer in answers.skip(answers.length > ReviewCard.kept ? answers.length - ReviewCard.kept : 0))
          if (answer case [final int day, final int right] when right == 0 || right == 1)
            ReviewAnswer(day: day, right: right == 1),
      ]),
    );
  }
  return null;
}
