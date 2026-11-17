@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

/// Practice's head and its sessions (plan 13.2 to 13.4, 13.6).

const _items = [
  QuizItem(question: 'Q1', options: ['One', 'Two', 'Three', 'Four'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two', 'Three', 'Four'], answer: 1, explain: 'E2'),
];

RecordData _completed(List<String> keys) =>
    keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', '2026-11-09T10:00:00.000Z'));

Future<(GoRouter, ReviewBloc)> _pump(
  WidgetTester tester, {
  RecordData? record,
  String at = '/practice',
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((_) async => testDoc(quiz: _items));
  final review = ReviewBloc(store: MemoryReviewStore())..add(const ReviewStarted());
  addTearDown(review.close);
  final router = AppRouterFactory(initialLocation: at).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      record: readyRecordBloc(record),
      repository: repository,
      review: review,
      platform: platform,
    ),
  );
  await tester.pumpAndSettle();
  return (router, review);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final _today = find.byKey(const Key('practice-today'));

void main() {
  testWidgets("Today's review offers the completed modules' questions, and a session asks them once each", (
    tester,
  ) async {
    final (router, review) = await _pump(tester, record: _completed(['alpha/first']));

    expect(find.descendant(of: _today, matching: find.text('2 cards, about 1 min')), findsOneWidget);
    expect(find.descendant(of: _today, matching: find.text('From First Module')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('practice-today-start')));
    expect(router.state.uri.path, '/practice/review');
    expect(find.byType(NavigationBar), findsNothing, reason: 'full screen, outside the shell');
    expect(find.text('Card 1 of 2'), findsOneWidget);

    // The options are shuffled; each has its own words, so the right one is found by them.
    await _tap(tester, find.text('One'));
    expect(find.text('Correct.'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('review-next')));
    expect(find.text('Card 2 of 2'), findsOneWidget);
    await _tap(tester, find.text('Three'));
    expect(find.textContaining('Not this one.'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('review-next')));
    expect(find.text('1 of 2 right'), findsOneWidget);

    final history = review.state.history;
    final today = dayNumber(DateTime.now());
    expect(history.doneOn(today), 2, reason: "both count toward the day's five");
    expect(history.cards['alpha/first#0']!.wrong, isFalse);
    expect(history.cards['alpha/first#1']!.wrong, isTrue);

    await _tap(tester, find.byKey(const Key('review-back')));
    expect(router.state.uri.path, '/practice');
    expect(find.descendant(of: _today, matching: find.text('That is all for today')), findsOneWidget);
    expect(find.descendant(of: _today, matching: find.byKey(const Key('practice-today-wrong'))), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('practice-wrong')), matching: find.text('1 question')),
      findsOneWidget,
    );
  });

  testWidgets('Wrong answers lists the questions answered wrong by level, and Answer them all asks them (plan 13.4)', (
    tester,
  ) async {
    final (router, review) = await _pump(tester);
    review
      ..add(const ReviewAnswered(key: 'beta/fourth#1', right: false, length: 2))
      ..add(const ReviewAnswered(key: 'alpha/first#0', right: false, length: 2))
      ..add(const ReviewAnswered(key: 'alpha/first#1', right: true, length: 2));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('practice-wrong')));
    expect(router.state.uri.path, '/practice/wrong');
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'a page of the tab');
    expect(find.text('Alpha Level'), findsOneWidget);
    expect(find.text('Beta Level'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('wrong-alpha/first#0'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('wrong-beta/fourth#1'))).dy),
      reason: "in the course's order",
    );
    expect(find.byKey(const ValueKey('wrong-alpha/first#1')), findsNothing, reason: 'answered right');

    await _tap(tester, find.byKey(const ValueKey('wrong-answer-all')));
    expect(router.state.uri.path, '/practice/wrong/all');
    expect(find.text('Card 1 of 2'), findsOneWidget);
    await _tap(tester, find.text('One'));
    await _tap(tester, find.byKey(const Key('review-next')));
    await _tap(tester, find.text('Two'));
    await _tap(tester, find.byKey(const Key('review-next')));
    expect(find.text('2 of 2 right'), findsOneWidget);
    expect(review.state.history.cards['alpha/first#0']!.wrong, isTrue, reason: 'right once is not enough');
    expect(review.state.history.doneOn(dayNumber(DateTime.now())), 0, reason: "not Today's review");

    await _tap(tester, find.byKey(const Key('review-back')));
    await _tap(tester, find.byKey(const ValueKey('wrong-answer-all')));
    await _tap(tester, find.text('One'));
    await _tap(tester, find.byKey(const Key('review-next')));
    await _tap(tester, find.text('Two'));
    await _tap(tester, find.byKey(const Key('review-next')));
    await _tap(tester, find.byKey(const Key('review-back')));
    expect(find.text('No wrong answers now.'), findsOneWidget, reason: 'right twice in a row, and they leave');
  });

  testWidgets('with no module completed, there is nothing to review today', (tester) async {
    await _pump(tester);
    expect(find.descendant(of: _today, matching: find.text('Nothing to review today')), findsOneWidget);
    expect(find.byKey(const Key('practice-today-start')), findsNothing);
    expect(find.byKey(const Key('practice-today-wrong')), findsNothing, reason: 'no wrong answer either');
  });

  testWidgets('the head and a session meet the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, record: _completed(['alpha/first']), platform: defaultTargetPlatform);
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    await _tap(tester, find.byKey(const Key('practice-today-start')));
    await _tap(tester, find.text('One'));
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
