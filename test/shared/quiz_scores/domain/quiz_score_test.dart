import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizScore.after', () {
    test('the first attempt is the last and the best, with nothing before', () {
      expect(QuizScore.after(null, 3, 5), const QuizScore(last: 3, best: 3, total: 5));
    });

    test('a later attempt keeps the best and the one before', () {
      final second = QuizScore.after(const QuizScore(last: 4, best: 4, total: 5), 2, 5);
      expect(second, const QuizScore(last: 2, best: 4, total: 5, previous: 4));
      expect(QuizScore.after(second, 5, 5), const QuizScore(last: 5, best: 5, total: 5, previous: 2));
    });

    test('a quiz whose length changed starts afresh', () {
      expect(
        QuizScore.after(const QuizScore(last: 4, best: 5, total: 5, previous: 3), 2, 6),
        const QuizScore(last: 2, best: 2, total: 6),
      );
    });

    test('perfect once the best attempt answered every question right, even after a worse one', () {
      expect(const QuizScore(last: 2, best: 5, total: 5, previous: 5).perfect, isTrue);
      expect(const QuizScore(last: 4, best: 4, total: 5).perfect, isFalse);
    });

    test('the last share', () {
      expect(const QuizScore(last: 3, best: 4, total: 4).lastShare, 0.75);
    });
  });

  group('the file', () {
    test('reads back what it wrote', () {
      const scores = {
        'alpha/first': QuizScore(last: 2, best: 3, total: 3, previous: 3),
        'beta/fourth': QuizScore(last: 1, best: 1, total: 2),
      };
      final text = encodeQuizScores(scores);
      expect(text, contains('"schema":1'));
      expect(text, isNot(contains('"previous":null')), reason: 'a first attempt writes no previous');
      expect(decodeQuizScores(text), scores);
    });

    test('a file that is not the shape reads as no score', () {
      for (final text in ['', 'not json', '[]', '{"schema":2,"scores":{}}', '{"schema":1}']) {
        expect(decodeQuizScores(text), isEmpty, reason: text);
      }
    });

    test('a score that does not hold together is left out, the rest kept', () {
      const text =
          '{"schema":1,"scores":{'
          '"a/one":{"last":2,"best":3,"total":3},'
          '"a/two":{"last":4,"best":4,"total":3},'
          '"a/three":{"last":2,"best":1,"total":3},'
          '"a/four":{"last":"2","best":3,"total":3},'
          '"a/five":{"last":1,"best":1,"total":1,"previous":9}}}';
      expect(decodeQuizScores(text), {
        'a/one': const QuizScore(last: 2, best: 3, total: 3),
        'a/five': const QuizScore(last: 1, best: 1, total: 1),
      });
    });
  });
}
