@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/guide/presentation/pages/guide_page.dart';
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
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 3);
    expect(find.byType(BackButton), findsOneWidget);
    for (final title in ['Level by level', 'Short modules', 'Mark what you finish', 'On this device, offline']) {
      expect(find.text(title, skipOffstage: false), findsOneWidget, reason: title);
    }
    expect(find.textContaining('The catalog shows what you have read', skipOffstage: false), findsOneWidget);
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
