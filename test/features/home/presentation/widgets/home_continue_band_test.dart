@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_continue_band.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_assistant.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The module left half read, in a band over the navigation (plan 10.4, the owner's testers, 2026-11-16: Continue
/// reading, the likeliest tap, sat at the top of the screen, out of the thumb's reach).
final _band = find.byKey(const ValueKey('home-continue-band'));

Future<GoRouter> _pump(WidgetTester tester, {String at = '/', bool halfRead = true, RecordData? record}) async {
  final places = ReadingPlacesBloc(
    store: MemoryReadingPlaceStore({
      if (halfRead) 'engineers:beta/fourth': ReadingPlace(offset: 400, share: 0.37, at: DateTime.utc(2026, 11, 11)),
    }),
  )..add(const ReadingPlacesStarted());
  addTearDown(places.close);
  final router = AppRouterFactory(initialLocation: at).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, places: places, record: readyRecordBloc(record)));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('lies right over the navigation, says what is read and how far, and goes on with it', (tester) async {
    final router = await _pump(tester);

    expect(_band, findsOneWidget);
    expect(find.descendant(of: _band, matching: find.text('Fourth Module')), findsOneWidget);
    expect(find.descendant(of: _band, matching: find.text('37 % read')), findsOneWidget);
    expect(
      tester.getBottomLeft(_band).dy,
      moreOrLessEquals(tester.getTopLeft(find.byType(NavigationBar)).dy, epsilon: 1),
      reason: 'under the thumb, on the navigation',
    );

    await tester.tap(_band);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/courses/beta/fourth');
    expect(_band, findsNothing, reason: 'not over the module itself');
  });

  for (final at in ['/sheets', '/quiz']) {
    testWidgets('lies over the navigation on $at too', (tester) async {
      await _pump(tester, at: at);
      expect(_band, findsOneWidget);
    });
  }

  for (final at in ['/caravan', '/settings', '/sheets/alpha']) {
    testWidgets('is not on $at', (tester) async {
      await _pump(tester, at: at);
      expect(_band, findsNothing);
    });
  }

  // The owner, 2026-11-16: with no module half read, it offers the next one, so Home's card could go.
  testWidgets('with no module half read, it offers the next one, with its minutes', (tester) async {
    final router = await _pump(tester, halfRead: false);

    expect(find.descendant(of: _band, matching: find.text('Up next')), findsOneWidget);
    expect(find.descendant(of: _band, matching: find.text('First Module')), findsOneWidget);
    expect(find.descendant(of: _band, matching: find.text('20 min')), findsOneWidget);
    await tester.tap(_band);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/courses/alpha/first');
  });

  testWidgets('takes no room with every module completed', (tester) async {
    await _pump(
      tester,
      halfRead: false,
      record: ['alpha/first', 'alpha/second', 'beta/fourth', 'gamma/sixth'].fold<RecordData>(
        RecordData.empty,
        (record, key) => signOff(record, key, 'abc1234', '2026-11-09T10:00:00.000Z'),
      ),
    );
    expect(_band, findsNothing);
    expect(tester.getSize(find.byType(HomeContinueBand)).height, 0);
  });

  testWidgets('grows with the text size rather than overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_band).height, greaterThan(HomeContinueBand.height));
  });

  testWidgets('the round button of the Apprentice stands above it', (tester) async {
    await _pump(tester);

    expect(find.byType(PocketAssistantButton), findsOneWidget);
    expect(tester.getBottomLeft(find.byType(PocketAssistantButton)).dy, lessThanOrEqualTo(tester.getTopLeft(_band).dy));
  });

  testWidgets('is gone while the keyboard is up, so it does not ride up over a search', (tester) async {
    await _pump(tester, at: '/sheets');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(_band, findsNothing);
  });

  testWidgets('a screen reader hears it as one button', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(
      tester.getSemantics(_band),
      isSemantics(isButton: true, label: 'Continue reading: Fourth Module, 37 % read', hasTapAction: true),
    );
    await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
    handle.dispose();
  });
}
