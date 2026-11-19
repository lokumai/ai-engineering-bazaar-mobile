import 'package:ai_engineering_bazaar/shared/review/domain/quiz_waiting.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewCard _answered(bool right) => ReviewCard(box: 1, due: 10, answers: [ReviewAnswer(day: 9, right: right)]);

void main() {
  group('latestAnswers', () {
    test("each question's latest answer, null for one never answered; null for a quiz with none", () {
      final history = ReviewHistory(
        cards: {'alpha/first#0': _answered(true), 'alpha/first#2': _answered(false)},
        lengths: const {'alpha/first': 3, 'alpha/second': 2},
      );
      expect(latestAnswers(history, 'alpha/first'), [true, null, false]);
      expect(latestAnswers(history, 'alpha/second'), isNull);
      expect(latestAnswers(history, 'beta/third'), isNull, reason: 'no length kept');
    });
  });

  group('quizWaiting (plan 13.17)', () {
    const completed = ['alpha/first', 'alpha/second', 'beta/third'];
    int length(String key) => key == 'alpha/second' ? 0 : 2;

    test("the first completed module, in the course's order, whose quiz was not taken", () {
      expect(
        quizWaiting(completed, quizLength: length, finished: (_) => false, history: ReviewHistory.empty),
        'alpha/first',
      );
    });

    test('a quiz finished, or with no question, is passed over', () {
      expect(
        quizWaiting(
          completed,
          quizLength: length,
          finished: (key) => key == 'alpha/first',
          history: ReviewHistory.empty,
        ),
        'beta/third',
        reason: 'alpha/second has no quiz',
      );
    });

    test('every question answered in Practice counts as taken; some answered does not', () {
      final some = ReviewHistory(cards: {'alpha/first#0': _answered(true)}, lengths: const {'alpha/first': 2});
      expect(quizWaiting(completed, quizLength: length, finished: (_) => false, history: some), 'alpha/first');
      final all = ReviewHistory(
        cards: {'alpha/first#0': _answered(true), 'alpha/first#1': _answered(false)},
        lengths: const {'alpha/first': 2},
      );
      expect(quizWaiting(completed, quizLength: length, finished: (_) => false, history: all), 'beta/third');
    });

    test('none waits when every quiz is taken, or nothing is completed', () {
      expect(quizWaiting(completed, quizLength: length, finished: (_) => true, history: ReviewHistory.empty), isNull);
      expect(quizWaiting(const [], quizLength: length, finished: (_) => false, history: ReviewHistory.empty), isNull);
    });
  });
}
