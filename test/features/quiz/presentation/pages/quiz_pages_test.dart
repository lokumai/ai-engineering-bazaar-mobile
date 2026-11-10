@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/quiz_list_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';
import '../../../../support/fold.dart';

/// The Quiz tab and a module's quiz full screen (plan 1AC).

const _items = [
  QuizItem(question: 'Q1', options: ['One', 'Two', 'Three', 'Four'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two', 'Three', 'Four'], answer: 1, explain: 'E2'),
];

Future<GoRouter> _pump(
  WidgetTester tester, {
  String location = '/quiz',
  TrackCubit? track,
  MockContentRepository? repository,
  QuizScoresBloc? scores,
}) async {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, track: track, repository: repository, scores: scores));
  await tester.pumpAndSettle();
  return router;
}

MockContentRepository _withQuiz() {
  final repository = MockContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((_) async => testDoc(quiz: _items));
  return repository;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const _titles = {'alpha': 'Alpha Level', 'beta': 'Beta Level', 'gamma': 'Gamma Level'};

/// Opens the levels [slugs] on the Quiz tab, unless open already.
Future<void> _openLevels(WidgetTester tester, List<String> slugs) async {
  for (final slug in slugs) {
    await openFold(tester, find.bySemanticsLabel(RegExp('^${_titles[slug]},')));
  }
}

void main() {
  setUpAll(registerAllFallbackValues);

  testWidgets('the Quiz tab lists every quiz by level, under the Quiz destination', (tester) async {
    await _pump(tester);

    expect(find.text('Quizzes'), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsOneWidget, reason: 'alpha/first is next to read');
    expect(find.byKey(QuizListPage.rowKey('beta/fourth')), findsNothing, reason: 'the other levels start closed');
    expect(find.bySemanticsLabel(RegExp(r'^Alpha Level, 2 quizzes$')), findsOneWidget);
    await _openLevels(tester, ['alpha', 'beta', 'gamma']);
    for (final key in ['alpha/first', 'alpha/second', 'beta/fourth', 'gamma/sixth']) {
      expect(find.byKey(QuizListPage.rowKey(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(QuizListPage.rowKey('alpha/third')), findsNothing, reason: 'planned, no quiz');
    expect(find.bySemanticsLabel('01 First Module'), findsOneWidget);
    expect(find.textContaining('come with the'), findsNothing);
  });

  testWidgets('what the reader opens or closes stays while the app runs; a new launch opens the next level', (
    tester,
  ) async {
    final router = await _pump(tester);
    await _tap(tester, find.bySemanticsLabel(RegExp('^Alpha Level,')));
    await _openLevels(tester, ['beta']);
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsNothing);

    router.go('/settings');
    await tester.pumpAndSettle();
    router.go('/quiz');
    await tester.pumpAndSettle();
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsNothing, reason: 'alpha stays closed');
    expect(find.byKey(QuizListPage.rowKey('beta/fourth')), findsOneWidget, reason: 'beta stays open');

    await tester.pumpWidget(const SizedBox());
    await _pump(tester);
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsOneWidget, reason: 'a new launch');
    expect(find.byKey(QuizListPage.rowKey('beta/fourth')), findsNothing);
  });

  testWidgets('a quiz finished on this device shows its last and best score, and its level how many (plan 1W)', (
    tester,
  ) async {
    final scores = QuizScoresBloc(
      store: MemoryQuizScoreStore(const {'alpha/first': QuizScore(last: 1, best: 2, total: 2, previous: 2)}),
    )..add(const QuizScoresStarted());
    addTearDown(scores.close);
    await _pump(tester, scores: scores);

    expect(find.text('Last 1 of 2 · best 2 of 2'), findsOneWidget);
    expect(find.bySemanticsLabel('01 First Module, Last 1 of 2 · best 2 of 2'), findsOneWidget);
    expect(find.bySemanticsLabel('02 Second Module'), findsOneWidget, reason: 'never finished: no score');
    expect(find.bySemanticsLabel(RegExp(r'^Alpha Level, 2 quizzes · 1 taken$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Beta Level, 1 quiz$')), findsOneWidget);
  });

  testWidgets('a For Everyone reader is told where the questions come from', (tester) async {
    final track = TrackCubit()..select(Track.everyone);
    addTearDown(track.close);
    await _pump(tester, track: track);

    expect(find.text('The questions come with the For Engineers modules.'), findsOneWidget);
    await _openLevels(tester, ['alpha']);
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsOneWidget);
  });

  testWidgets('a row opens the quiz full screen, titled with the module, and Done comes back', (tester) async {
    final router = await _pump(tester, repository: _withQuiz());
    await _openLevels(tester, ['alpha']);

    await _tap(tester, find.byKey(QuizListPage.rowKey('alpha/first')));
    expect(router.state.uri.path, '/quiz/alpha/first');
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('First Module'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing, reason: 'full screen, outside the shell');
    expect(find.text('Q1'), findsOneWidget);

    await _tap(tester, find.text('One'));
    await _tap(tester, find.text('Next'));
    await _tap(tester, find.text('Two'));
    await _tap(tester, find.text('See results'));
    await _tap(tester, find.text('Done'));
    expect(router.state.uri.path, '/quiz');
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsOneWidget, reason: 'the level stays open');

    await _tap(tester, find.bySemanticsLabel(RegExp('^Alpha Level,')));
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsNothing, reason: 'a second tap closes it');
  });

  testWidgets('a quiz that cannot be read says so, and closes', (tester) async {
    final repository = MockContentRepository();
    when(() => repository.readModuleDoc(any())).thenThrow(const ContentMissingException('gone'));
    final router = await _pump(tester, repository: repository);
    await _openLevels(tester, ['beta']);

    await _tap(tester, find.byKey(QuizListPage.rowKey('beta/fourth')));
    expect(find.text('This quiz could not be opened. Close it and try again later.'), findsOneWidget);
    await _tap(tester, find.byType(CloseButton));
    expect(router.state.uri.path, '/quiz');
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = AppRouterFactory(initialLocation: '/quiz').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final gamma = find.byKey(QuizListPage.levelKey('gamma'));
    await tester.scrollUntilVisible(gamma, 200, scrollable: list);
    await _tap(tester, gamma);
    final last = find.byKey(QuizListPage.rowKey('gamma/sixth'));
    await tester.scrollUntilVisible(last, 200, scrollable: list);
    await tester.pump();
    expectHittable(tester, last);
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    final router = AppRouterFactory(initialLocation: '/quiz').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(platform: defaultTargetPlatform, router: router));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
