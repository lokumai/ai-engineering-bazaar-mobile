import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = 100;
  final questions = [for (var i = 0; i < 8; i++) 'alpha/first#$i'];
  const term = 'term:engineers/alpha/first#0';

  ReviewHistory with_(Map<String, ReviewCard> cards, {int day = 0, int done = 0}) =>
      ReviewHistory(cards: cards, day: day, done: done);

  group('todaysReview (plan 13.3)', () {
    test('the wrong ones first, then those due, then terms looked up, then the questions never answered', () {
      final history = with_({
        'alpha/first#0': const ReviewCard(box: 2, due: today - 1),
        'alpha/first#1': const ReviewCard(box: 0, due: today, wrong: true),
        'alpha/first#2': const ReviewCard(box: 3, due: today + 4),
        'alpha/first#3': const ReviewCard(box: 1, due: today - 3),
        term: const ReviewCard(box: 0, due: today),
      });
      expect(todaysReview(history, questions: questions, terms: [term], today: today), [
        'alpha/first#1',
        'alpha/first#3',
        'alpha/first#0',
        term,
        'alpha/first#4',
      ]);
    });

    test('at most five a day: what Today\'s review took today counts', () {
      final history = with_(const {}, day: today, done: 3);
      expect(todaysReview(history, questions: questions, terms: const [], today: today), hasLength(2));
      expect(
        todaysReview(
          with_(const {}, day: today, done: 5),
          questions: questions,
          terms: const [],
          today: today,
        ),
        isEmpty,
      );
      expect(
        todaysReview(
          with_(const {}, day: today - 1, done: 5),
          questions: questions,
          terms: const [],
          today: today,
        ),
        hasLength(reviewDaily),
        reason: "yesterday's count is not today's",
      );
    });

    test('nothing due and nothing new: nothing to review', () {
      final history = with_({for (final key in questions) key: const ReviewCard(box: 1, due: today + 1)});
      expect(todaysReview(history, questions: questions, terms: const [], today: today), isEmpty);
    });

    test('a card kept for a question or a term no longer offered is left out', () {
      final history = with_({
        'gone/module#0': const ReviewCard(box: 0, due: today, wrong: true),
        'term:engineers/gone/module#0': const ReviewCard(box: 0, due: today),
      });
      expect(todaysReview(history, questions: const [], terms: const [], today: today), isEmpty);
    });
  });

  group('wrongAnswers (plan 13.4)', () {
    test('the questions answered wrong, in the order given', () {
      final history = with_({
        'alpha/first#5': const ReviewCard(box: 0, due: today, wrong: true),
        'alpha/first#2': const ReviewCard(box: 0, due: today, wrong: true),
        'alpha/first#3': const ReviewCard(box: 1, due: today),
      });
      expect(wrongAnswers(history, questions: questions), ['alpha/first#2', 'alpha/first#5']);
    });
  });

  test('reviewMinutes: half a minute a card, at least one', () {
    expect(
      [
        for (final n in [0, 1, 2, 5]) reviewMinutes(n),
      ],
      [0, 1, 1, 3],
    );
  });
}
