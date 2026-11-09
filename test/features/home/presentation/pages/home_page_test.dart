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
import 'package:ai_engineering_bazaar/shared/track/track_switch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';

const _now = '2026-11-09T10:00:00.000Z';

RecordData _completed(List<String> keys) =>
    keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', _now));

/// The fixture index with the level [slug] still being written.
BundleIndex _withDraft(String slug) {
  final index = catalogFixtureIndex();
  return BundleIndex(
    contentVersion: index.contentVersion,
    publishedAt: index.publishedAt,
    publishedAtInstant: index.publishedAtInstant,
    tracks: index.tracks,
    diagramFont: index.diagramFont,
    diagramThemes: index.diagramThemes,
    levels: [
      for (final level in index.levels)
        level.slug == slug
            ? LevelEntry(
                slug: level.slug,
                title: level.title,
                status: LevelStatus.draft,
                blurb: level.blurb,
                total: level.total,
                readme: level.readme,
              )
            : level,
    ],
    modules: index.modules,
    moved: index.moved,
    files: index.files,
    images: index.images,
  );
}

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
  testWidgets('Home is the first page: the switch, the next module, the levels and the offline note', (tester) async {
    await _pumpHome(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(TrackSwitch), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('First Module'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    for (final title in ['Alpha Level', 'Beta Level', 'Gamma Level']) {
      expect(find.text(title, skipOffstage: false), findsWidgets);
    }
    expect(find.text('The course is on this device', skipOffstage: false), findsOneWidget);
  });

  testWidgets('the continue card opens the next module', (tester) async {
    final router = await _pumpHome(tester, record: _completed(['alpha/first']));

    expect(find.text('Second Module'), findsOneWidget);
    await _tap(tester, find.text('Open the module'));

    expect(_path(router), '/courses/alpha/second');
  });

  testWidgets('a level row shows its completion and opens the level page of the track', (tester) async {
    final router = await _pumpHome(tester, record: _completed(['alpha/first', 'alpha/second']));

    expect(
      find.byWidgetPredicate((widget) => widget is CompletionDial && widget.semanticLabel == '2/3 completed'),
      findsOneWidget,
    );
    // The continue card names the next module's level too; the row comes after it.
    await _tap(tester, find.text('Beta Level').last);

    expect(_path(router), '/sheets/beta');
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

  testWidgets('the switch shows the other track on Home without leaving it', (tester) async {
    final track = TrackCubit();
    addTearDown(track.close);
    final router = await _pumpHome(tester, record: _completed(['alpha/first']), track: track);

    await _tap(tester, find.byKey(TrackSwitch.segmentKey(Track.everyone)));

    expect(_path(router), '/');
    expect(track.state, Track.everyone);
    expect(find.text('Second Module'), findsNothing);
    expect(find.text('First Story'), findsOneWidget, reason: 'alpha/first is completed For Engineers only');
    await _tap(tester, find.text('Open the module'));
    expect(_path(router), '/everyone/courses/alpha/first');
  });

  testWidgets('a level still being written says Planned', (tester) async {
    await _pumpHome(tester, index: _withDraft('beta'));

    // The list builds lazily, so the row is scrolled to first.
    await tester.scrollUntilVisible(find.text('Planned'), 200);
    expect(find.text('Planned'), findsOneWidget);
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    expectHittable(tester, find.byKey(TrackSwitch.segmentKey(Track.engineers)));
    expectHittable(tester, find.byKey(TrackSwitch.segmentKey(Track.everyone)));
    await tester.ensureVisible(find.text('Open the module'));
    await tester.pump();
    expectHittable(tester, find.text('Open the module'));
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await _pumpHome(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
