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
    expect(find.text('Levels'), findsNothing, reason: 'plan 1P: the levels live on the catalog and progress');
    expect(find.byType(CompletionDial), findsNothing);
    expect(find.text('The course is on this device', skipOffstage: false), findsOneWidget);
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

    expect(find.text('Every written module of this track is complete.'), findsOneWidget);
    expect(find.text('Open the module'), findsNothing);
    await _tap(tester, find.text('See the progress'));

    expect(_path(router), '/profile');
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
}
