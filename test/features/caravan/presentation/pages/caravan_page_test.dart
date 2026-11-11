@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The Caravan tab, under maintenance until the bundle carries the web's timeline (plan 3.1).

Future<GoRouter> _pump(
  WidgetTester tester, {
  TrackCubit? track,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final router = AppRouterFactory(initialLocation: '/caravan').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, track: track, platform: platform));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('says the Caravan is under maintenance, under the Caravan destination', (tester) async {
    await _pump(tester);

    expect(find.descendant(of: find.byType(ListView), matching: find.text('Caravan')), findsOneWidget);
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(
      find.text('The Caravan, a timeline of what was trending in AI engineering, is still being built.'),
      findsOneWidget,
    );
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
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
