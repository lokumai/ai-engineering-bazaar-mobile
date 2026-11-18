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
    test('questions and terms in turn, a question first: the wrong ones, those due, then new ones (plan 13.3)', () {
      final history = with_({
        'alpha/first#0': const ReviewCard(box: 2, due: today - 1),
        'alpha/first#1': const ReviewCard(box: 0, due: today, wrong: true),
        'alpha/first#2': const ReviewCard(box: 3, due: today + 4),
        'alpha/first#3': const ReviewCard(box: 1, due: today - 3),
        term: const ReviewCard(box: 0, due: today),
      });
      const fresh = 'term:engineers/alpha/first#1';
      expect(todaysReview(history, questions: questions, terms: [term, fresh], newTerms: [term, fresh], today: today), [
        'alpha/first#1',
        term,
        'alpha/first#3',
        fresh,
        'alpha/first#0',
      ], reason: 'three questions and two terms; a term due before a new one, and a term seen not new again');
    });

    test('when one kind runs out, the other fills its place', () {
      expect(todaysReview(with_(const {}), questions: questions, terms: [term], newTerms: [term], today: today), [
        'alpha/first#0',
        term,
        'alpha/first#1',
        'alpha/first#2',
        'alpha/first#3',
      ]);
      expect(
        todaysReview(
          with_(const {}),
          questions: const [],
          terms: const [],
          newTerms: [for (var i = 0; i < 6; i++) 'term:engineers/alpha/first#$i'],
          today: today,
        ),
        hasLength(reviewDaily),
        reason: 'a module with Key Terms and no quiz still has a review',
      );
    });

    test('at most five a day: what Today\'s review took today counts', () {
      final history = with_(const {}, day: today, done: 3);
      expect(
        todaysReview(history, questions: questions, terms: const [], newTerms: const [], today: today),
        hasLength(2),
      );
      expect(
        todaysReview(
          with_(const {}, day: today, done: 5),
          questions: questions,
          terms: const [],
          newTerms: const [],
          today: today,
        ),
        isEmpty,
      );
      expect(
        todaysReview(
          with_(const {}, day: today - 1, done: 5),
          questions: questions,
          terms: const [],
          newTerms: const [],
          today: today,
        ),
        hasLength(reviewDaily),
        reason: "yesterday's count is not today's",
      );
    });

    test('nothing due and nothing new: nothing to review', () {
      final history = with_({for (final key in questions) key: const ReviewCard(box: 1, due: today + 1)});
      expect(todaysReview(history, questions: questions, terms: const [], newTerms: const [], today: today), isEmpty);
    });

    test('a card kept for a question or a term no longer offered is left out', () {
      final history = with_({
        'gone/module#0': const ReviewCard(box: 0, due: today, wrong: true),
        'term:engineers/gone/module#0': const ReviewCard(box: 0, due: today),
      });
      expect(todaysReview(history, questions: const [], terms: const [], newTerms: const [], today: today), isEmpty);
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
