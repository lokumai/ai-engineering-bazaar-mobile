@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/guide/presentation/pages/guide_page.dart';
import 'package:ai_engineering_bazaar/features/tour/application/tour_cubit.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/accessibility.dart';
import '../../support/bazaar_app_harness.dart';

Future<void> _pump(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android}) async {
  final router = AppRouterFactory(initialLocation: '/settings').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, platform: platform));
  await tester.pumpAndSettle();
  final row = find.text('How the bazaar works');
  await tester.scrollUntilVisible(row, 200);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Settings opens how the bazaar works, Welcome\'s guide before the story (plan 3.5)', (tester) async {
    await _pump(tester);

    expect(find.byType(GuidePage), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 4);
    expect(find.byType(BackButton), findsOneWidget);
    for (final title in ['Level by level', 'Short modules', 'Mark what you finish', 'On this device, offline']) {
      expect(find.text(title, skipOffstage: false), findsOneWidget, reason: title);
    }
    expect(find.textContaining('The catalog shows what you have read', skipOffstage: false), findsOneWidget);
  });

  testWidgets('it takes the Apprentice\'s tour again, from Home (plan 11.3)', (tester) async {
    final tour = TourCubit(store: MemoryTourStore(const TourRecord(guiding: true, seen: {'home', 'settings'})));
    await tour.load();
    final router = AppRouterFactory(initialLocation: '/settings/guide').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, tour: tour));
    await tester.pumpAndSettle();

    final replay = find.byKey(const ValueKey('guide-replay-tour'));
    expect(find.text('Take the tour again'), findsOneWidget);
    await tester.tap(replay);
    await tester.pump();

    expect(router.state.uri.path, '/');
    expect(tour.state, const TourRecord(guiding: true), reason: 'every page is shown again');
    await tester.pump(const Duration(seconds: 2));
  });

  for (final language in ['en', 'tr', 'fa']) {
    testWidgets('Take the tour again is in sight without a scroll on a small phone, in $language', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = AppRouterFactory(initialLocation: '/settings/guide').create();
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router, locale: Locale(language)));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byKey(const ValueKey('guide-replay-tour')));
      final nav = tester.getRect(find.byType(NavigationBar));
      expect(button.top, greaterThanOrEqualTo(0));
      expect(button.bottom, lessThanOrEqualTo(nav.top));
    });
  }

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
