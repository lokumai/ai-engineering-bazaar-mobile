import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 17, 9);
  final today = dayNumber(now);

  Future<T> at<T>(Future<T> Function() body) => withClock(Clock.fixed(now), body);

  test('reads the history kept, and keeps each answer and term looked up on the day it was given', () async {
    await at(() async {
      final store = MemoryReviewStore(
        ReviewHistory.empty.answered('alpha/first#0', right: false, today: today - 1, length: 2),
      );
      final bloc = ReviewBloc(store: store)..add(const ReviewStarted());
      bloc
        ..add(const ReviewAnswered(key: 'alpha/first#0', right: true, length: 2, inReview: true))
        ..add(const ReviewTermLookedUp('term:engineers/alpha/first#0'));
      await pumpEventQueue();
      final history = bloc.state.history;
      expect(history.cards['alpha/first#0']!.answers.map((a) => (a.day, a.right)), [(today - 1, false), (today, true)]);
      expect(history.cards['term:engineers/alpha/first#0'], ReviewCard.lookedUp(today));
      expect(history.doneOn(today), 1);
      expect(await store.load(), history, reason: 'saved');
      await bloc.close();
    });
  });

  test("a quiz seen with another length drops its module's questions", () async {
    await at(() async {
      final store = MemoryReviewStore(
        ReviewHistory.empty.answered('alpha/first#0', right: false, today: today, length: 2),
      );
      final bloc = ReviewBloc(store: store)
        ..add(const ReviewStarted())
        ..add(const ReviewQuizLengthSeen(moduleKey: 'alpha/first', length: 3));
      await pumpEventQueue();
      expect(bloc.state.history.cards, isEmpty);
      await bloc.close();
    });
  });

  test("Settings' reset erases the history and its undo brings it back under what came since", () async {
    await at(() async {
      final kept = ReviewHistory.empty.answered('alpha/first#0', right: false, today: today, length: 2);
      final store = MemoryReviewStore(kept);
      final bloc = ReviewBloc(store: store)
        ..add(const ReviewStarted())
        ..add(const ReviewErased());
      await pumpEventQueue();
      expect(bloc.state.history, ReviewHistory.empty);
      expect(await store.load(), ReviewHistory.empty);

      bloc
        ..add(const ReviewErased(again: true))
        ..add(const ReviewAnswered(key: 'alpha/first#1', right: true, length: 2))
        ..add(const ReviewEraseUndone());
      await pumpEventQueue();
      expect(bloc.state.history.cards.keys, unorderedEquals(['alpha/first#0', 'alpha/first#1']));
      await bloc.close();
    });
  });
}
