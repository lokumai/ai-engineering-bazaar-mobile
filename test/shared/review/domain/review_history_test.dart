import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = 100;

  group('answered', () {
    test('keeps the card and the quiz length, and counts a review answer on its day only', () {
      var history = ReviewHistory.empty.answered('alpha/first#0', right: true, today: today, length: 3);
      expect(history.cards['alpha/first#0']!.box, 1);
      expect(history.lengths, {'alpha/first': 3});
      expect(history.doneOn(today), 0, reason: "a module's quiz is not Today's review");

      history = history.answered('alpha/first#1', right: false, today: today, inReview: true);
      history = history.answered('alpha/first#2', right: true, today: today, inReview: true);
      expect(history.doneOn(today), 2);
      expect(history.doneOn(today + 1), 0, reason: 'a new day starts afresh');

      history = history.answered('alpha/first#0', right: true, today: today + 1, inReview: true);
      expect((history.day, history.done), (today + 1, 1));
    });
  });

  group('lookedUp', () {
    test('keeps a term not kept yet, and leaves one kept as it is', () {
      const key = 'term:engineers/alpha/first#0';
      final history = ReviewHistory.empty.lookedUp(key, today);
      expect(history.cards[key], ReviewCard.lookedUp(today));
      final answered = history.answered(key, right: true, today: today + 1);
      expect(answered.lookedUp(key, today + 1), answered);
    });
  });

  group('seenLength', () {
    test("drops a module's questions when its quiz has another length, and keeps the rest", () {
      final history = ReviewHistory.empty
          .answered('alpha/first#0', right: true, today: today, length: 3)
          .answered('alpha/second#0', right: true, today: today, length: 2)
          .lookedUp('term:engineers/alpha/first#0', today);
      expect(history.seenLength('alpha/first', 3), history);
      final changed = history.seenLength('alpha/first', 4);
      expect(changed.cards.keys, unorderedEquals(['alpha/second#0', 'term:engineers/alpha/first#0']));
      expect(changed.lengths, {'alpha/first': 4, 'alpha/second': 2});
    });
  });

  group('under', () {
    test("a reset's undo puts what was answered since on top of what it erased", () {
      final before = ReviewHistory.empty
          .answered('alpha/first#0', right: false, today: today, length: 3)
          .answered('alpha/first#1', right: true, today: today, length: 3, inReview: true);
      final since = ReviewHistory.empty.answered('alpha/first#0', right: true, today: today + 1, length: 3);
      final merged = before.under(since);
      expect(merged.cards['alpha/first#0'], since.cards['alpha/first#0']);
      expect(merged.cards['alpha/first#1'], before.cards['alpha/first#1']);
      expect((merged.day, merged.done), (today, 1), reason: 'nothing reviewed since: the count stays');
    });

    test("a quiz whose length changed since keeps only the new length's answers", () {
      final before = ReviewHistory.empty.answered('alpha/first#2', right: true, today: today, length: 3);
      final since = ReviewHistory.empty.answered('alpha/first#0', right: true, today: today, length: 4);
      final merged = before.under(since);
      expect(merged.cards.keys, ['alpha/first#0']);
      expect(merged.lengths, {'alpha/first': 4});
    });
  });

  group('the file', () {
    test('reads back what it wrote', () {
      final history = ReviewHistory.empty
          .answered('alpha/first#0', right: false, today: today, length: 3)
          .answered('alpha/first#0', right: true, today: today + 1, length: 3, inReview: true)
          .lookedUp('term:everyone/alpha/first#2', today);
      expect(decodeReviewHistory(encodeReviewHistory(history)), history);
    });

    test('anything not of its shape reads as empty, and a card not of its shape is left out', () {
      expect(decodeReviewHistory('not json'), ReviewHistory.empty);
      // Review 6, finding 15: a damaged length past any quiz's is left out.
      expect(
        decodeReviewHistory('{"schema":1,"day":1,"done":0,"lengths":{"a/b":1000000000,"a/c":4},"cards":{}}').lengths,
        {'a/c': 4},
      );
      expect(decodeReviewHistory('{"schema":2,"day":1,"done":0,"lengths":{},"cards":{}}'), ReviewHistory.empty);
      final read = decodeReviewHistory(
        '{"schema":1,"day":1,"done":0,"lengths":{"alpha/first":3,"alpha/bad":0},"cards":{'
        '"alpha/first#0":{"box":1,"due":2,"run":1,"wrong":false,"answers":[[1,1],[1,7]]},'
        '"alpha/first#1":{"box":9,"due":2,"run":0,"wrong":false,"answers":[]},'
        '"no-place":{"box":1,"due":2,"run":0,"wrong":false,"answers":[]}}}',
      );
      expect(read.cards.keys, ['alpha/first#0']);
      expect(read.cards['alpha/first#0']!.answers, const [ReviewAnswer(day: 1, right: true)]);
      expect(read.lengths, {'alpha/first': 3});
    });
  });
}
