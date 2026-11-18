@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/practice_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';
import '../../../../support/content_builders.dart';
import '../../../../support/fold.dart';

/// The Quiz tab and a module's quiz full screen (plan 1AC).

const _items = [
  QuizItem(question: 'Q1', options: ['One', 'Two', 'Three', 'Four'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two', 'Three', 'Four'], answer: 1, explain: 'E2'),
];

Future<GoRouter> _pump(
  WidgetTester tester, {
  String location = '/practice',
  TrackCubit? track,
  MockContentRepository? repository,
  QuizScoresBloc? scores,
  LanguageCubit? language,
  BundleIndex? index,
  ReviewBloc? review,
}) async {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      track: track,
      repository: repository,
      scores: scores,
      language: language,
      content: index == null ? null : readyContentBloc(index),
      review: review,
    ),
  );
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

/// The quiz row [moduleKey]'s segments in order, each 'right', 'wrong' or 'none'.
List<String> _segments(WidgetTester tester, String moduleKey) => [
  for (final element
      in find
          .descendant(
            of: find.byKey(PracticePage.rowKey(moduleKey)),
            matching: find.byWidgetPredicate((widget) => '${widget.key}'.contains("'answer-")),
          )
          .evaluate())
    RegExp(r"answer-\d+-(\w+)'").firstMatch('${element.widget.key}')!.group(1)!,
];

const _titles = {'alpha': 'Alpha Level', 'beta': 'Beta Level', 'gamma': 'Gamma Level'};

/// Opens the levels [slugs] on Practice, unless open already; they stand under Today's review, so the page scrolls to
/// each first.
Future<void> _openLevels(WidgetTester tester, List<String> slugs) async {
  for (final slug in slugs) {
    final button = find.bySemanticsLabel(RegExp('^${_titles[slug]},'));
    await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
    await openFold(tester, button);
  }
}

/// Scrolls Practice until [target] is drawn: the levels sit below its head, off a test screen.
Future<void> _scrollTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);

void main() {
  setUpAll(registerAllFallbackValues);

  testWidgets('Practice lists every quiz by level, under the Practice destination', (tester) async {
    await _pump(tester);

    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('Practice')),
      findsOneWidget,
      reason: 'its name',
    );
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 3);
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsOneWidget, reason: 'alpha/first is next to read');
    expect(find.byKey(PracticePage.rowKey('beta/fourth')), findsNothing, reason: 'the other levels start closed');
    expect(find.bySemanticsLabel(RegExp(r'^Alpha Level, 2 quizzes, 0 of 2 taken$')), findsOneWidget);
    await _openLevels(tester, ['alpha', 'beta', 'gamma']);
    for (final key in ['alpha/first', 'alpha/second', 'beta/fourth', 'gamma/sixth']) {
      expect(find.byKey(PracticePage.rowKey(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(PracticePage.rowKey('alpha/third')), findsNothing, reason: 'planned, no quiz');
    expect(find.bySemanticsLabel('First Module'), findsOneWidget);
    expect(find.textContaining('come with the'), findsNothing);
    final level = find.byKey(PracticePage.levelKey('alpha'));
    expect(
      find.ancestor(of: level, matching: find.byType(BazaarCard)),
      findsNothing,
      reason: "a row on the page's ground, not a card (the owner, 2026-11-18)",
    );
    expect(find.descendant(of: level, matching: find.byType(BazaarCard)), findsNothing);
    expect(find.textContaining(RegExp(r'^0\d'), findRichText: true), findsNothing, reason: 'no numbers');
  });

  testWidgets("a quiz's row is titled in the chosen language (web D139)", (tester) async {
    await _pump(
      tester,
      language: LanguageCubit(initial: 'tr'),
      index: catalogFixtureIndex(
        titles: {
          'alpha/first': {'en': 'First Module', 'tr': 'Birinci Modül'},
        },
      ),
    );
    expect(find.bySemanticsLabel('Birinci Modül'), findsOneWidget);
    expect(find.bySemanticsLabel('Second Module'), findsOneWidget);
  });

  testWidgets('what the reader opens or closes stays while the app runs; a new launch opens the next level', (
    tester,
  ) async {
    final router = await _pump(tester);
    await _tap(tester, find.bySemanticsLabel(RegExp('^Alpha Level,')));
    await _openLevels(tester, ['beta']);
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsNothing);

    router.go('/settings');
    await tester.pumpAndSettle();
    router.go('/practice');
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.bySemanticsLabel(RegExp('^Beta Level,')));
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsNothing, reason: 'alpha stays closed');
    await _scrollTo(tester, find.byKey(PracticePage.rowKey('beta/fourth')));
    expect(find.byKey(PracticePage.rowKey('beta/fourth')), findsOneWidget, reason: 'beta stays open');

    await tester.pumpWidget(const SizedBox());
    await _pump(tester);
    await _scrollTo(tester, find.byKey(PracticePage.rowKey('alpha/first')));
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsOneWidget, reason: 'a new launch');
    await _scrollTo(tester, find.bySemanticsLabel(RegExp('^Gamma Level,')));
    expect(find.byKey(PracticePage.rowKey('beta/fourth')), findsNothing);
  });

  testWidgets(
    'a quiz finished on this device shows its last score as segments, and its level how many in the catalog dial',
    (tester) async {
      final scores = QuizScoresBloc(
        store: MemoryQuizScoreStore(const {'alpha/first': QuizScore(last: 1, best: 2, total: 2, previous: 2)}),
      )..add(const QuizScoresStarted());
      addTearDown(scores.close);
      await _pump(tester, scores: scores);

      expect(_segments(tester, 'alpha/first'), ['right', 'wrong'], reason: 'the last score, one segment per question');
      expect(_segments(tester, 'alpha/second'), isEmpty);
      expect(find.text('1/2'), findsNWidgets(2), reason: 'the level dial, 1 of 2 taken, and the quiz, 1 of 2 right');
      expect(find.bySemanticsLabel('First Module, 1 of 2 right at the last answer'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(PracticePage.rowKey('alpha/first')), matching: find.byIcon(Icons.check_circle)),
        findsNothing,
        reason: 'the last attempt had a wrong answer, though the best was all right',
      );
      expect(
        find.descendant(of: find.byKey(PracticePage.rowKey('alpha/second')), matching: find.byType(Text)),
        findsOneWidget,
        reason: 'no mark before the title, and no word at its end (the owner, 2026-11-18): only its title',
      );
      expect(
        find.descendant(
          of: find.byKey(PracticePage.rowKey('alpha/second')),
          matching: find.byKey(const Key('quiz-status-new')),
        ),
        findsOneWidget,
        reason: 'never taken: an empty ring at its end',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('quiz-status-count'))).data,
        '1/2',
        reason: 'taken: the right ones out of all at its end',
      );
      expect(find.bySemanticsLabel('Second Module'), findsOneWidget, reason: 'never finished: no score');
      expect(find.bySemanticsLabel(RegExp(r'^Alpha Level, 2 quizzes, 1 of 2 taken$')), findsOneWidget);
      final beta = find.bySemanticsLabel(RegExp(r'^Beta Level, 1 quiz, 0 of 1 taken$'));
      await tester.scrollUntilVisible(beta, 200, scrollable: find.byType(Scrollable).first);
      expect(beta, findsOneWidget);
    },
  );

  testWidgets("the quizzes' segments follow each question's latest answer, Practice's too (the owner, 2026-11-18)", (
    tester,
  ) async {
    final scores = QuizScoresBloc(
      store: MemoryQuizScoreStore(const {'alpha/first': QuizScore(last: 2, best: 2, total: 2, previous: 2)}),
    )..add(const QuizScoresStarted());
    addTearDown(scores.close);
    final review = ReviewBloc(store: MemoryReviewStore())..add(const ReviewStarted());
    addTearDown(review.close);
    await _pump(tester, scores: scores, review: review);
    expect(_segments(tester, 'alpha/first'), ['right', 'right']);

    review.add(const ReviewAnswered(key: 'alpha/first#1', right: false, length: 2, inReview: true));
    await tester.pumpAndSettle();
    expect(_segments(tester, 'alpha/first'), ['wrong', 'none'], reason: 'a wrong answer in a review shows at once');
    expect(
      find.descendant(of: find.byKey(PracticePage.rowKey('alpha/first')), matching: find.byIcon(Icons.check_circle)),
      findsNothing,
    );
    expect(find.bySemanticsLabel('First Module, 0 of 2 right at the last answer'), findsOneWidget);

    review
      ..add(const ReviewAnswered(key: 'alpha/first#0', right: true, length: 2, inReview: true))
      ..add(const ReviewAnswered(key: 'alpha/first#1', right: true, length: 2, inReview: true));
    await tester.pumpAndSettle();
    expect(_segments(tester, 'alpha/first'), ['right', 'right']);
    expect(
      find.descendant(of: find.byKey(PracticePage.rowKey('alpha/first')), matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
      reason: 'every latest answer right: the catalog check',
    );
    expect(find.text('1/2'), findsOneWidget);

    review.add(const ReviewAnswered(key: 'alpha/second#0', right: false, length: 2, inReview: true));
    await tester.pumpAndSettle();
    expect(_segments(tester, 'alpha/second'), ['wrong', 'none']);

    // The second question answered right in a review fills from the start, not its own place (the owner, 2026-11-18).
    review.add(const ReviewAnswered(key: 'alpha/second#1', right: true, length: 2, inReview: true));
    await tester.pumpAndSettle();
    expect(_segments(tester, 'alpha/second'), ['right', 'wrong']);
    expect(find.text('2/2'), findsOneWidget, reason: 'a quiz answered in Practice counts as taken in the level dial');
  });

  testWidgets('a For Everyone reader sees the quizzes of the modules written For Everyone, under their titles there', (
    tester,
  ) async {
    final track = TrackCubit()..select(Track.everyone);
    addTearDown(track.close);
    await _pump(tester, track: track);

    await _openLevels(tester, ['alpha']);
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(PracticePage.rowKey('alpha/first')), matching: find.text('First Story')),
      findsOneWidget,
    );
    expect(find.byKey(PracticePage.rowKey('alpha/second')), findsNothing, reason: 'not written For Everyone');
  });

  testWidgets('a row opens the quiz full screen, titled with the module, and Done comes back', (tester) async {
    final router = await _pump(tester, repository: _withQuiz());
    await _openLevels(tester, ['alpha']);

    await _tap(tester, find.byKey(PracticePage.rowKey('alpha/first')));
    expect(router.state.uri.path, '/quiz/alpha/first');
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('First Module'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing, reason: 'full screen, outside the shell');
    expect(find.byType(AppBar), findsNothing, reason: 'no navy bar: the app bar on the page ground');
    expect(find.descendant(of: find.byType(BazaarBar), matching: find.byType(CloseButton)), findsOneWidget);
    expect(find.byType(LatticeBand), findsNothing, reason: 'no band under the bar (the owner, 2026-11-18)');
    expect(find.text('Q1'), findsOneWidget);

    await _tap(tester, find.text('One'));
    await _tap(tester, find.text('Next'));
    await _tap(tester, find.text('Two'));
    await _tap(tester, find.text('See results'));
    await _tap(tester, find.text('Done'));
    expect(router.state.uri.path, '/practice');
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsOneWidget, reason: 'the level stays open');

    await _tap(tester, find.bySemanticsLabel(RegExp('^Alpha Level,')));
    expect(find.byKey(PracticePage.rowKey('alpha/first')), findsNothing, reason: 'a second tap closes it');
  });

  testWidgets('a quiz that cannot be read says so, and closes', (tester) async {
    final repository = MockContentRepository();
    when(() => repository.readModuleDoc(any())).thenThrow(const ContentMissingException('gone'));
    final router = await _pump(tester, repository: repository);
    await _openLevels(tester, ['beta']);

    await _tap(tester, find.byKey(PracticePage.rowKey('beta/fourth')));
    expect(find.text('This quiz could not be opened. Close it and try again later.'), findsOneWidget);
    await _tap(tester, find.byType(CloseButton));
    expect(router.state.uri.path, '/practice');
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = AppRouterFactory(initialLocation: '/practice').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final gamma = find.byKey(PracticePage.levelKey('gamma'));
    await tester.scrollUntilVisible(gamma, 200, scrollable: list);
    await _tap(tester, gamma);
    final last = find.byKey(PracticePage.rowKey('gamma/sixth'));
    await tester.scrollUntilVisible(last, 200, scrollable: list);
    await tester.pump();
    expectHittable(tester, last);
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    final router = AppRouterFactory(initialLocation: '/practice').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(platform: defaultTargetPlatform, router: router));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
