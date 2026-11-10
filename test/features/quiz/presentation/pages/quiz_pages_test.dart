@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/quiz_list_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
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
}) async {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, track: track, repository: repository));
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

void main() {
  setUpAll(registerAllFallbackValues);

  testWidgets('the Quiz tab lists every quiz by level, under the Quiz destination', (tester) async {
    await _pump(tester);

    expect(find.text('Quizzes'), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
    for (final key in ['alpha/first', 'alpha/second', 'beta/fourth', 'gamma/sixth']) {
      expect(find.byKey(QuizListPage.rowKey(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(QuizListPage.rowKey('alpha/third')), findsNothing, reason: 'planned, no quiz');
    expect(find.bySemanticsLabel('01 First Module'), findsOneWidget);
    expect(find.textContaining('come with the'), findsNothing);
  });

  testWidgets('a For Everyone reader is told where the questions come from', (tester) async {
    final track = TrackCubit()..select(Track.everyone);
    addTearDown(track.close);
    await _pump(tester, track: track);

    expect(find.text('The questions come with the For Engineers modules.'), findsOneWidget);
    expect(find.byKey(QuizListPage.rowKey('alpha/first')), findsOneWidget);
  });

  testWidgets('a row opens the quiz full screen, titled with the module, and Done comes back', (tester) async {
    final router = await _pump(tester, repository: _withQuiz());

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
  });

  testWidgets('a quiz that cannot be read says so, and closes', (tester) async {
    final repository = MockContentRepository();
    when(() => repository.readModuleDoc(any())).thenThrow(const ContentMissingException('gone'));
    final router = await _pump(tester, repository: repository);

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
    final last = find.byKey(QuizListPage.rowKey('gamma/sixth'));
    await tester.scrollUntilVisible(
      last,
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
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
