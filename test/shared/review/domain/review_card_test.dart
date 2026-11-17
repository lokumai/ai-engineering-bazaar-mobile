import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = 100;

  group('keys', () {
    test('a question key names the module and the place, a term key the track too', () {
      expect(questionKey('alpha/first', 2), 'alpha/first#2');
      expect(termKey(Track.everyone, 'alpha/first', 0), 'term:everyone/alpha/first#0');
      expect(isTermKey('alpha/first#2'), isFalse);
      expect(isTermKey('term:everyone/alpha/first#0'), isTrue);
      expect(moduleOfKey('alpha/first#2'), 'alpha/first');
      expect(moduleOfKey('term:everyone/alpha/first#0'), 'alpha/first');
      expect(indexOfKey('term:everyone/alpha/first#3'), 3);
    });
  });

  group('the boxes (plan 13.3)', () {
    test('a right answer moves a card up a box: due 1, 3, 7, then 21 days later, and no higher', () {
      var card = ReviewCard.after(null, right: true, today: today);
      expect((card.box, card.due), (1, today + 1));
      final dues = <int>[];
      var day = card.due;
      for (var i = 0; i < 4; i++) {
        card = ReviewCard.after(card, right: true, today: day);
        dues.add(card.due - day);
        day = card.due;
      }
      expect(dues, [3, 7, 21, 21]);
      expect(card.box, ReviewCard.top);
    });

    test('a wrong answer brings a card back to the first box, due tomorrow, and into Wrong answers', () {
      final high = const ReviewCard(box: 3, due: today);
      final card = ReviewCard.after(high, right: false, today: today);
      expect((card.box, card.due, card.wrong, card.run), (0, today + 1, true, 0));
    });

    test('a right answer before the card is due moves it no higher, as a quiz taken again the same day', () {
      final card = ReviewCard.after(null, right: true, today: today);
      final again = ReviewCard.after(card, right: true, today: today);
      expect((again.box, again.due), (card.box, card.due));
      expect(again.run, 2);
    });

    test('right twice in a row takes a question out of Wrong answers (plan 13.4)', () {
      var card = ReviewCard.after(null, right: false, today: today);
      card = ReviewCard.after(card, right: true, today: today + 1);
      expect(card.wrong, isTrue, reason: 'once is not enough');
      card = ReviewCard.after(card, right: true, today: today + 2);
      expect(card.wrong, isFalse);
    });

    test('a card keeps its last answers only, the oldest first', () {
      ReviewCard? card;
      for (var i = 0; i < ReviewCard.kept + 3; i++) {
        card = ReviewCard.after(card, right: i.isEven, today: today + i);
      }
      expect(card!.answers, hasLength(ReviewCard.kept));
      expect(card.answers.first.day, today + 3);
      expect(card.answers.last, ReviewAnswer(day: today + ReviewCard.kept + 2, right: (ReviewCard.kept + 2).isEven));
    });

    test('a term looked up comes up tomorrow, in the first box', () {
      expect(ReviewCard.lookedUp(today), const ReviewCard(box: 0, due: today + 1));
    });
  });
}
