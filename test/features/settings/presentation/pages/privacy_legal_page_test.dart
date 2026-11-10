@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/settings/domain/site_owner.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/privacy_legal_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool crashReports = false,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final router = AppRouterFactory(initialLocation: '/settings', crashReports: crashReports).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, platform: platform));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Privacy and legal'), 200);
  await tester.tap(find.text('Privacy and legal'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Settings opens the privacy and legal notes, with the Settings tab still selected', (tester) async {
    await _pump(tester);

    expect(find.byType(PrivacyLegalPage), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 3);
    expect(find.byType(BackButton), findsOneWidget, reason: 'a page pushed over Settings');
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.textContaining('collects no personal data'), findsOneWidget);
    expect(find.textContaining('saved on this device only'), findsOneWidget);
    expect(find.textContaining('hosted on GitHub Pages'), findsOneWidget);
  });

  testWidgets('the owner is named as the registry has it', (tester) async {
    await _pump(tester);

    for (final fact in [SiteOwner.tradeName, SiteOwner.mersis, SiteOwner.address, SiteOwner.phone]) {
      expect(find.text(fact, skipOffstage: false), findsOneWidget, reason: fact);
    }
    expect(find.text(SiteOwner.email, skipOffstage: false), findsWidgets);
    expect(find.text('Third-party marks and images', skipOffstage: false), findsOneWidget);
  });

  for (final crashReports in [false, true]) {
    testWidgets(
      'crash reports are ${crashReports ? '' : 'not '}mentioned when the build ${crashReports ? 'sends' : 'sends no'} them',
      (tester) async {
        await _pump(tester, crashReports: crashReports);

        expect(find.textContaining('crash report', skipOffstage: false), crashReports ? findsOneWidget : findsNothing);
      },
    );
  }

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pump(tester, crashReports: true, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
