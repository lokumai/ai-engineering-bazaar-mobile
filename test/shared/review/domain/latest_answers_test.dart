import 'package:ai_engineering_bazaar/shared/review/domain/latest_answers.dart';
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
}
