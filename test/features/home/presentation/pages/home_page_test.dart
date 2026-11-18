@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/pages/home_page.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_daily_card.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, Key, ListView, Locale, Text, ValueKey;
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../mocks/mock_classes.dart';
import '../../../../support/catalog_fixture_index.dart';
import '../../../../support/content_builders.dart';

const _now = '2026-11-09T10:00:00.000Z';

RecordData _completed(List<String> keys) =>
    keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', _now));

Future<GoRouter> _pumpHome(
  WidgetTester tester, {
  RecordData? record,
  BundleIndex? index,
  TrackCubit? track,
  ReadingPlacesBloc? places,
  MockContentRepository? repository,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
  LanguageCubit? language,
  ReviewBloc? review,
  QuizScoresBloc? scores,
}) async {
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      content: readyContentBloc(index),
      record: readyRecordBloc(record),
      track: track,
      places: places,
      repository: repository,
      platform: platform,
      locale: locale,
      language: language,
      review: review,
      scores: scores,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _path(GoRouter router) => router.state.uri.path;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The band over the navigation with the module to read now (plan 10.4).
final _band = find.byKey(const ValueKey('home-continue-band'));

Finder _inBand(String text) => find.descendant(of: _band, matching: find.text(text));

void main() {
  testWidgets('the band says Up next in Turkish too', (tester) async {
    await _pumpHome(tester, locale: const Locale('tr'));

    expect(_inBand('Sıradaki'), findsOneWidget);
  });

  // Plan 10.4 (the owner, 2026-11-16): the module to read now is in the band under the thumb, and Home's card is gone.
  testWidgets('Home is the first page: the modules later on, the next module in the band, no offline note', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(_inBand('Up next'), findsOneWidget);
    expect(_inBand('First Module'), findsOneWidget);
    expect(_inBand('20 min'), findsOneWidget);
    expect(find.text('First Module'), findsOneWidget, reason: 'in the band only, with no card at the head');
    expect(find.text('UP NEXT'), findsNothing);
    expect(find.text('Later on'), findsOneWidget);
    expect(find.text('Second Module'), findsOneWidget);
    expect(find.text('Fourth Module', skipOffstage: false), findsOneWidget);
    expect(find.text('Levels'), findsNothing, reason: 'plan 1P: the levels live on the catalog');
    expect(find.byType(CompletionDial), findsNothing);
    expect(
      find.textContaining('on this device', skipOffstage: false),
      findsNothing,
      reason: 'plan 12.6: the note is in Settings',
    );
    expect(find.text('Quizzes to practise', skipOffstage: false), findsNothing, reason: 'nothing completed yet');
  });

  testWidgets('module titles are in the chosen language, the English one where there is none (web D139)', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      language: LanguageCubit(initial: 'tr'),
      index: catalogFixtureIndex(
        titles: {
          'alpha/first': {'en': 'First Module', 'tr': 'Birinci Modül'},
        },
      ),
    );

    expect(find.text('Birinci Modül'), findsOneWidget);
    expect(find.text('First Module'), findsNothing);
    expect(find.text('Second Module', skipOffstage: false), findsOneWidget);
  });

  testWidgets("the modules after it give their minutes and words, as the catalog's rows do (web D128)", (tester) async {
    await _pumpHome(
      tester,
      index: catalogFixtureIndex(
        words: {
          'alpha/second': {'en': 3670},
        },
      ),
    );

    expect(find.text('Alpha Level · 25 min · 3,670 words'), findsOneWidget);
    final fourth = tester.widget<Text>(find.textContaining('Beta Level · ', skipOffstage: false)).data!;
    expect(fourth, isNot(contains('words')), reason: 'the minutes alone where the content has no word count');
    expect(fourth, contains('40'));
  });

  testWidgets('the band opens the next module', (tester) async {
    final router = await _pumpHome(tester, record: _completed(['alpha/first']));

    expect(_inBand('Second Module'), findsOneWidget);
    await _tap(tester, _band);

    expect(_path(router), '/courses/alpha/second');
  });

  testWidgets('a module left half read: the band goes on with it, says how far, and opens it (plan 1BA)', (
    tester,
  ) async {
    final places = ReadingPlacesBloc(
      store: MemoryReadingPlaceStore({
        'engineers:beta/fourth': ReadingPlace(offset: 400, share: 0.37, at: DateTime.utc(2026, 11, 11)),
      }),
    )..add(const ReadingPlacesStarted());
    addTearDown(places.close);
    final router = await _pumpHome(tester, places: places);

    expect(_inBand('Continue reading'), findsOneWidget);
    expect(_inBand('Up next'), findsNothing);
    expect(_inBand('37 % read'), findsOneWidget);
    expect(_inBand('Fourth Module'), findsOneWidget);
    expect(find.text('First Module'), findsOneWidget, reason: 'the next module is first later on');
    await _tap(tester, _band);

    expect(_path(router), '/courses/beta/fourth');
  });

  testWidgets('a module after the next one opens in the track, and the catalog is one tap away', (tester) async {
    final router = await _pumpHome(tester, record: _completed(['alpha/first']));

    await _tap(tester, find.text('Fourth Module'));
    expect(_path(router), '/courses/beta/fourth');

    router.pop();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('See the whole catalog'));
    expect(_path(router), '/sheets');
  });

  testWidgets('every written module completed: a line says so and Progress is one tap away', (tester) async {
    final router = await _pumpHome(
      tester,
      record: _completed(['alpha/first', 'alpha/second', 'beta/fourth', 'gamma/sixth']),
    );

    expect(find.text('Every written module is complete.'), findsOneWidget);
    expect(_band, findsNothing);
    await _tap(tester, find.text('See the whole catalog').first);

    expect(_path(router), '/sheets');
  });

  testWidgets('Home follows the current track', (tester) async {
    final track = TrackCubit();
    addTearDown(track.close);
    final router = await _pumpHome(tester, record: _completed(['alpha/first']), track: track);

    track.select(Track.everyone);
    await tester.pumpAndSettle();

    expect(_path(router), '/');
    expect(track.state, Track.everyone);
    expect(find.text('Second Module'), findsNothing);
    expect(_inBand('First Story'), findsOneWidget, reason: 'alpha/first is completed For Engineers only');
    await _tap(tester, _band);
    expect(_path(router), '/everyone/courses/alpha/first');
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    expectHittable(tester, _band);
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await _pumpHome(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  testWidgets("Practice under its heading: Today's review, the glossary and a quiz waiting (plan 13.2, 13.17)", (
    tester,
  ) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _termsDoc());
    final router = await _pumpHome(tester, record: _completed(['alpha/first', 'beta/fourth']), repository: repository);

    final row = find.byKey(const Key('home-review'), skipOffstage: false);
    final glossary = find.byKey(const Key('home-glossary'), skipOffstage: false);
    final waiting = find.byKey(const Key('home-quiz-waiting'), skipOffstage: false);
    expect(
      find.descendant(of: row, matching: find.textContaining('cards, about')),
      findsOneWidget,
      reason: "the day's cards",
    );
    final heading = find.descendant(of: find.byType(ListView), matching: find.text('Practice'), skipOffstage: false);
    expect(heading, findsOneWidget, reason: "Practice's own heading, not the tab's name");
    final tops = [
      for (final finder in [find.byType(HomeDailyCard, skipOffstage: false), heading, row, glossary, waiting])
        tester.getTopLeft(finder).dy,
      tester.getTopLeft(find.text('Later on', skipOffstage: false)).dy,
    ];
    expect(tops, [...tops]..sort(), reason: "the day's card, Practice's heading, its three, then Later on");
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.school_rounded)),
      findsOneWidget,
      reason: "the tab's cap",
    );
    expect(find.byKey(const Key('practice-wrong'), skipOffstage: false), findsNothing, reason: "Practice's own");
    expect(find.byKey(const Key('practice-brief'), skipOffstage: false), findsNothing, reason: "Practice's own");

    expect(find.descendant(of: glossary, matching: find.text('2 terms')), findsOneWidget);
    expect(
      find.descendant(of: glossary, matching: find.text('Wick')),
      findsOneWidget,
      reason: 'the terms of the last module completed',
    );
    expect(
      find.descendant(of: waiting, matching: find.textContaining('First Module', findRichText: true)),
      findsOneWidget,
      reason: "the first completed module in the course's order",
    );
    expect(find.byKey(const Key('home-quiz-waiting'), skipOffstage: false), findsOneWidget, reason: 'one row');

    await _tap(tester, row);
    expect(_path(router), '/practice/review');
    router.go('/');
    await tester.pumpAndSettle();
    await _tap(tester, glossary);
    expect(_path(router), '/practice/glossary');
    router.go('/');
    await tester.pumpAndSettle();
    await _tap(tester, waiting);
    expect(_path(router), '/quiz/alpha/first');
  });

  testWidgets('the quiz waiting is the next one once a quiz is finished, and none once all are', (tester) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _termsDoc());
    final scores = QuizScoresBloc(
      store: MemoryQuizScoreStore({'alpha/first': const QuizScore(last: 2, best: 2, total: 2)}),
    )..add(const QuizScoresStarted());
    addTearDown(scores.close);
    await _pumpHome(tester, record: _completed(['alpha/first', 'beta/fourth']), repository: repository, scores: scores);
    final waiting = find.byKey(const Key('home-quiz-waiting'), skipOffstage: false);
    expect(
      find.descendant(of: waiting, matching: find.textContaining('Fourth Module', findRichText: true)),
      findsOneWidget,
    );

    scores.add(const QuizScoreRecorded(key: 'beta/fourth', right: 1, total: 2));
    await tester.pumpAndSettle();
    expect(waiting, findsNothing);
  });

  testWidgets("once the day's cards are done, Today's review stays and says so (plan 13.17)", (tester) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _termsDoc());
    final review = ReviewBloc(store: MemoryReviewStore())..add(const ReviewStarted());
    addTearDown(review.close);
    final router = await _pumpHome(tester, record: _completed(['alpha/first']), repository: repository, review: review);
    for (final key in [
      'alpha/first#0',
      'alpha/first#1',
      'term:engineers/alpha/first#0',
      'term:engineers/alpha/first#1',
    ]) {
      review.add(ReviewAnswered(key: key, right: true, length: key.startsWith('term') ? null : 2, inReview: true));
    }
    await tester.pumpAndSettle();
    expect(review.state.history.doneOn(dayNumber(DateTime.now())), 4);

    expect(find.byKey(const Key('home-review'), skipOffstage: false), findsNothing);
    final rest = find.byKey(const Key('home-review-rest'), skipOffstage: false);
    expect(find.descendant(of: rest, matching: find.text('That is all for today')), findsOneWidget);
    await _tap(tester, rest);
    expect(_path(router), '/', reason: 'nothing to start');
  });

  testWidgets('no Practice before a module is completed', (tester) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _termsDoc());
    await _pumpHome(tester, repository: repository);
    expect(find.byKey(const Key('home-review'), skipOffstage: false), findsNothing);
    expect(find.byKey(const Key('home-glossary'), skipOffstage: false), findsNothing);
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('Practice'), skipOffstage: false),
      findsNothing,
      reason: 'no heading',
    );
  });
}

/// A module whose Key Terms are Wick and Glass, with a quiz of two questions.
ModuleDoc _termsDoc() {
  ListItem term(String name, String definition) => ListItem(
    checked: null,
    taskIndex: null,
    blocks: [
      ParagraphBlock(
        inlines: [
          StrongInline(inlines: [TextInline(text: name)]),
          TextInline(text: ': $definition'),
        ],
        lead: false,
      ),
    ],
  );
  return testDoc(
    body: [
      const HeadingBlock(
        depth: 2,
        id: 'words',
        mark: null,
        inlines: [TextInline(text: 'Words')],
      ),
      ListBlock(ordered: false, start: null, items: [term('Wick', 'what burns.'), term('Glass', 'keeps wind out.')]),
    ],
    quiz: _quiz,
  );
}

const _quiz = [
  QuizItem(question: 'Q1', options: ['One', 'Two'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two'], answer: 1, explain: 'E2'),
];
