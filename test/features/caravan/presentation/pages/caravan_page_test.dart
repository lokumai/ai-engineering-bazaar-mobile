@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/caravan/application/caravan_cubit.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/sample_trends.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_stage.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_stage.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_strip.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/trend_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The Caravan tab: the web's shadow play made for a phone, on the web's sample trends (plan 9.1).

final _trends = SampleCaravan.trends('en');

Future<GoRouter> _pump(
  WidgetTester tester, {
  CaravanCubit? caravan,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = AppRouterFactory(initialLocation: '/caravan').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, caravan: caravan, platform: platform, locale: locale));
  await tester.pumpAndSettle();
  return router;
}

CaravanCubit _cubit() {
  final cubit = CaravanCubit();
  addTearDown(cubit.close);
  return cubit;
}

String _cardTitle(WidgetTester tester) => tester.widget<TrendCard>(find.byType(TrendCard)).stop.trend.title;

ShadowStagePainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.descendant(of: find.byType(CaravanStage), matching: find.byType(CustomPaint)))
            .painter!
        as ShadowStagePainter;

void main() {
  testWidgets('opens on the first stop: the notice, the stage, the strip and the first trend', (tester) async {
    await _pump(tester);

    expect(find.descendant(of: find.byType(ListView), matching: find.text('Caravan')), findsOneWidget);
    expect(find.text('Content is coming soon. Until then these trends are sample data.'), findsOneWidget);
    expect(find.byType(CaravanStage), findsOneWidget);
    expect(find.byType(CaravanStrip), findsOneWidget);
    expect(find.text('Stop 1 of 22'), findsOneWidget);
    expect(_cardTitle(tester), _trends.first.title);
    expect(find.text('NOV 2022 TO FEB 2023'), findsOneWidget);
    expect(find.text('Sample'), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
  });

  testWidgets('the arrows move between stops, and stop at either end', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);

    expect(tester.widget<IconButton>(find.byKey(const ValueKey('caravan-previous'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('caravan-next')));
    await tester.pumpAndSettle();
    expect(cubit.state, const CaravanResting(1));
    expect(find.text('Stop 2 of 22'), findsOneWidget);

    cubit.select(21, count: 22);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('caravan-next'))).onPressed, isNull);
    expect(_cardTitle(tester), _trends.last.title);
    expect(find.textContaining('TO NOW'), findsOneWidget, reason: 'the last trend is still on the road');
  });

  testWidgets('a swipe on the card turns to the next stop and back', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);
    await tester.ensureVisible(find.byType(TrendCard));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TrendCard), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(cubit.state.selected, 1);
    expect(_cardTitle(tester), _trends[1].title);

    await tester.fling(find.byType(TrendCard), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(cubit.state.selected, 0);
  });

  testWidgets('the hint shows until the caravan first moves', (tester) async {
    await _pump(tester);
    const hint = 'Swipe the card, drag the road or tap a stall to travel.';
    await tester.scrollUntilVisible(find.text(hint), 200);
    expect(find.text(hint), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('caravan-next')), -200);

    await tester.tap(find.byKey(const ValueKey('caravan-next')));
    await tester.pumpAndSettle();
    expect(find.text(hint), findsNothing);
  });

  testWidgets('the tour walks on by itself, and its button stops it', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);

    await tester.tap(find.byKey(const ValueKey('caravan-tour')));
    await tester.pump();
    expect(cubit.state, const CaravanTouring(1));
    expect(find.text('Stop the tour'), findsOneWidget);

    await tester.pump(cubit.dwell);
    expect(cubit.state, const CaravanTouring(2));

    await tester.tap(find.byKey(const ValueKey('caravan-tour')));
    await tester.pumpAndSettle();
    expect(cubit.state, const CaravanResting(2));
    expect(find.text('Tour the road'), findsOneWidget);
  });

  testWidgets('leaving the page ends a tour where the caravan is', (tester) async {
    final cubit = _cubit();
    final router = await _pump(tester, caravan: cubit);
    cubit.tour(count: 22);
    await tester.pump();

    router.go('/');
    await tester.pumpAndSettle();
    expect(cubit.state, const CaravanResting(1));
  });

  testWidgets('the tab opens where the caravan was left', (tester) async {
    final cubit = _cubit()..select(6, count: 22);
    await _pump(tester, caravan: cubit);

    expect(find.text('Stop 7 of 22'), findsOneWidget);
    expect(_cardTitle(tester), _trends[6].title);
    expect(_painter(tester).selected, 6);
  });

  testWidgets('All trends finds a trend by its words and goes there', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);

    await tester.tap(find.byKey(const ValueKey('caravan-all')));
    await tester.pumpAndSettle();
    expect(find.text('22 trends'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('caravan-search')), 'chips');
    await tester.pumpAndSettle();
    expect(find.text('1 trend'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('caravan-trend-gpu_rush')));
    await tester.pumpAndSettle();
    expect(cubit.state.selected, 5);
    expect(_cardTitle(tester), 'The GPU rush');
  });

  testWidgets('All trends filters by year and says when nothing matches', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('caravan-all')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('caravan-year-2022')));
    await tester.pumpAndSettle();
    expect(find.text('2 trends'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('caravan-search')), 'zebra');
    await tester.pumpAndSettle();
    expect(find.text('No trend matches.'), findsOneWidget);
  });

  testWidgets('a drag on the stage pulls the road, and the caravan walks to the nearest stop', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);

    await tester.drag(find.byType(CaravanStage), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(cubit.state.selected, greaterThan(1));
    expect(_painter(tester).selected, cubit.state.selected);
  });

  testWidgets('a tap on the strip goes to the stop nearest the spot', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);

    final strip = tester.getRect(find.byType(CaravanStrip));
    await tester.tapAt(Offset(strip.right - 4, strip.center.dy));
    await tester.pumpAndSettle();
    expect(cubit.state.selected, 21);
  });

  testWidgets('the strip is a slider over the stops for a screen reader', (tester) async {
    final cubit = _cubit();
    final handle = tester.ensureSemantics();
    await _pump(tester, caravan: cubit);

    final strip = tester.getSemantics(find.byType(CaravanStrip));
    expect(strip.label, 'Where the caravan is');
    expect(strip.value, startsWith(_trends.first.title));
    expect(strip.increasedValue, _trends[1].title);

    tester.semantics.performAction(find.semantics.byLabel('Where the caravan is'), SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(cubit.state.selected, 1);
    handle.dispose();
  });

  testWidgets('the stage is a picture named for the chosen trend', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('The caravan at ${_trends.first.title}'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the puppets rest once the caravan has stood a while, so nothing is drawn while reading', (tester) async {
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);
    cubit.next(count: 22);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.hasRunningAnimations, isTrue, reason: 'the caravan walks');

    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.hasRunningAnimations, isFalse);
    expect(_painter(tester).journey.moving, isFalse);
  });

  testWidgets('under reduced motion the caravan is at its stop at once and nothing moves', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final cubit = _cubit();
    await _pump(tester, caravan: cubit);

    cubit.next(count: 22);
    await tester.pump();
    await tester.pump();
    // The card's switch takes no time, and ends with the next frame.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_painter(tester).journey.moving, isFalse);
  });

  testWidgets('in Persian the road runs right to left, and the trends are in Persian', (tester) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(_painter(tester).mirrored, isTrue);
    expect(_cardTitle(tester), SampleCaravan.trends('fa').first.title);
  });

  testWidgets('in Turkish the trends and the period are in Turkish', (tester) async {
    await _pump(tester, locale: const Locale('tr'));

    expect(_cardTitle(tester), 'Sohbet botu anı');
    expect(find.text('KAS 2022 İLE ŞUB 2023 ARASI'), findsOneWidget);
    expect(_painter(tester).mirrored, isFalse);
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
