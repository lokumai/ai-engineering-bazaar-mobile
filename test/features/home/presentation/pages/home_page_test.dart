@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/pages/home_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

const _now = '2026-11-09T10:00:00.000Z';

RecordData _completed(List<String> keys) =>
    keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', _now));

Future<GoRouter> _pumpHome(
  WidgetTester tester, {
  RecordData? record,
  BundleIndex? index,
  TrackCubit? track,
  QuizScoresBloc? scores,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      content: readyContentBloc(index),
      record: readyRecordBloc(record),
      track: track,
      scores: scores,
      platform: platform,
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

void main() {
  testWidgets('Home is the first page: the track, the next module, the ones after it and the offline note', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('First Module'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
    expect(find.text('After that'), findsOneWidget);
    expect(find.text('Second Module'), findsOneWidget);
    expect(find.text('Fourth Module', skipOffstage: false), findsOneWidget);
    expect(find.text('Levels'), findsNothing, reason: 'plan 1P: the levels live on the catalog');
    expect(find.byType(CompletionDial), findsNothing);
    expect(find.text('The course is on this device', skipOffstage: false), findsOneWidget);
    expect(find.text('Practise again', skipOffstage: false), findsNothing, reason: 'nothing completed yet');
  });

  testWidgets('the continue card opens the next module', (tester) async {
    final router = await _pumpHome(tester, record: _completed(['alpha/first']));

    expect(find.text('Second Module'), findsOneWidget);
    await _tap(tester, find.text('Open the module'));

    expect(_path(router), '/courses/alpha/second');
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
    expect(find.text('Open the module'), findsNothing);
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
    expect(find.text('First Story'), findsOneWidget, reason: 'alpha/first is completed For Engineers only');
    await _tap(tester, find.text('Open the module'));
    expect(_path(router), '/everyone/courses/alpha/first');
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Open the module'));
    await tester.pump();
    expectHittable(tester, find.text('Open the module'));
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await _pumpHome(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  testWidgets('practice offers the quizzes of the modules completed last, and opens one full screen (plan 1AD)', (
    tester,
  ) async {
    final router = await _pumpHome(tester, record: _completed(['alpha/first', 'beta/fourth']));

    final practice = find.byKey(const ValueKey('home-practice-alpha/first'), skipOffstage: false);
    expect(find.text('Practise again', skipOffstage: false), findsOneWidget);
    expect(practice, findsOneWidget);
    expect(find.byKey(const ValueKey('home-practice-beta/fourth'), skipOffstage: false), findsOneWidget);

    await _tap(tester, practice);
    expect(_path(router), '/quiz/alpha/first');
  });

  testWidgets('a practised quiz shows its last score as segments, with no words, the one not taken first (plan 1W)', (
    tester,
  ) async {
    final scores = QuizScoresBloc(
      store: MemoryQuizScoreStore(const {'alpha/first': QuizScore(last: 1, best: 2, total: 2, previous: 2)}),
    )..add(const QuizScoresStarted());
    addTearDown(scores.close);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpHome(tester, record: _completed(['alpha/first', 'beta/fourth']), scores: scores);

    final first = find.byKey(const ValueKey('home-practice-alpha/first'), skipOffstage: false);
    final fourth = find.byKey(const ValueKey('home-practice-beta/fourth'), skipOffstage: false);
    expect(tester.getTopLeft(fourth).dy, lessThan(tester.getTopLeft(first).dy), reason: 'not taken comes first');
    final meter = tester.widget<SegmentMeter>(
      find.descendant(of: first, matching: find.byType(SegmentMeter), skipOffstage: false),
    );
    expect((meter.done, meter.total), (1, 2));
    expect(meter.restColor, BazaarColors.light.fault, reason: 'the wrong answers in red');
    expect(find.descendant(of: fourth, matching: find.byType(SegmentMeter), skipOffstage: false), findsNothing);
    expect(find.textContaining('Last 1 of 2', skipOffstage: false), findsNothing);
  });
}
