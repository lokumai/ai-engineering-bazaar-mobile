@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_scene.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The Caravan tab, coming soon until the bundle carries the web's timeline (plan 3.1).

Future<GoRouter> _pump(
  WidgetTester tester, {
  TrackCubit? track,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
  bool settle = true,
}) async {
  final router = AppRouterFactory(initialLocation: '/caravan').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, track: track, platform: platform, locale: locale));
  if (settle) await tester.pumpAndSettle();
  return router;
}

CaravanScenePainter _scene(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.descendant(of: find.byType(CaravanScene), matching: find.byType(CustomPaint)))
            .painter!
        as CaravanScenePainter;

void main() {
  testWidgets('says the Caravan is coming soon, under the Caravan destination', (tester) async {
    await _pump(tester);

    expect(find.descendant(of: find.byType(ListView), matching: find.text('Caravan')), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.bySemanticsLabel('The Caravan is on its way'), findsOneWidget);
    expect(
      find.text(
        'A timeline of what was trending in AI engineering, season by season. Until it arrives, the catalog is open.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
  });

  testWidgets('the caravan walks in once and stops', (tester) async {
    await _pump(tester, settle: false);
    await tester.pump();
    expect(_scene(tester).progress.value, lessThan(0.1));

    await tester.pump(CaravanScene.walk ~/ 2);
    expect(_scene(tester).progress.value, inExclusiveRange(0.1, 1));

    await tester.pumpAndSettle();
    expect(_scene(tester).progress.value, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('under reduced motion the caravan stands in place at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, settle: false);
    await tester.pump();

    expect(_scene(tester).progress.value, 1);
  });

  testWidgets('the scene is decoration, hidden from assistive technology', (tester) async {
    await _pump(tester);

    expect(find.descendant(of: find.byType(CaravanScene), matching: find.byType(ExcludeSemantics)), findsOneWidget);
  });

  testWidgets('in Persian the caravan walks right to left, and the page is in Persian', (tester) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(_scene(tester).mirrored, isTrue);
    expect(find.text('به\u200cزودی'), findsOneWidget);
  });

  testWidgets('in English the caravan walks left to right', (tester) async {
    await _pump(tester);

    expect(_scene(tester).mirrored, isFalse);
  });

  testWidgets('the catalog button opens the catalog of the current track', (tester) async {
    final track = TrackCubit()..select(Track.everyone);
    addTearDown(track.close);
    final router = await _pump(tester, track: track);

    await tester.tap(find.widgetWithText(FilledButton, 'Catalog'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/everyone/sheets');
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
