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
import '../../../../support/content_fixture.dart';
import '../../../../support/url_launcher_stub.dart';

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
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 4);
    expect(find.byType(BackButton), findsOneWidget, reason: 'a page pushed over Settings');
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.textContaining('none of it is linked to you'), findsOneWidget);
    expect(find.textContaining("and in the device's own backup when it is on"), findsOneWidget);
    expect(find.textContaining('hosted on GitHub Pages'), findsOneWidget);
  });

  testWidgets("the privacy note ends on a link to the site's note, which covers the app too (web D138)", (
    tester,
  ) async {
    final calls = stubOpeningUrlLauncher(canLaunch: true);
    await _pump(tester);

    final link = find.text('The privacy note on the website');
    await tester.scrollUntilVisible(link, 200);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(calls.launchedUrls, ['${testContentBaseUrl}legend/#privacy']);
  });

  // Walk-through 2026-11-24: the phone, the email and the licence opened only on a tap on their text, though the row's
  // node spans the page.
  for (final (name, text, url) in [
    ('phone', SiteOwner.phone, 'tel:${SiteOwner.phone.replaceAll(' ', '')}'),
    ('licence', 'MIT licence', null),
  ]) {
    testWidgets('a tap beside the $name\'s text opens it', (tester) async {
      final calls = stubOpeningUrlLauncher(canLaunch: true);
      await _pump(tester);

      final target = find.text(text).last;
      await tester.scrollUntilVisible(target, 200);
      final page = tester.getRect(find.byType(PrivacyLegalPage));
      await tester.tapAt(Offset(page.right - 40, tester.getCenter(target).dy));
      await tester.pumpAndSettle();

      expect(calls.launchedUrls, hasLength(1));
      if (url != null) expect(calls.launchedUrls.single, url);
    });
  }

  testWidgets('the owner is named as the registry has it', (tester) async {
    await _pump(tester);

    for (final fact in [SiteOwner.tradeName, SiteOwner.mersis, SiteOwner.address, SiteOwner.phone]) {
      expect(find.text(fact, skipOffstage: false), findsOneWidget, reason: fact);
    }
    expect(find.text(SiteOwner.email, skipOffstage: false), findsWidgets);
    expect(find.text('Third-party marks and images', skipOffstage: false), findsOneWidget);
  });

  // Review 6, finding 6: in Persian the right-to-left line showed the phone number's groups in the opposite order.
  testWidgets("the owner's details are laid out left to right in every language", (tester) async {
    await _pump(tester);

    for (final fact in [SiteOwner.tradeName, SiteOwner.mersis, SiteOwner.address, SiteOwner.phone]) {
      expect(tester.widget<Text>(find.text(fact, skipOffstage: false)).textDirection, TextDirection.ltr, reason: fact);
    }
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

  // Plan 16.1: Feedback opens the web's form in the browser; the note says the app sends nothing to it, in every build.
  for (final crashReports in [false, true]) {
    testWidgets('the note says Feedback is a Google form the app sends nothing to, crash reports $crashReports', (
      tester,
    ) async {
      await _pump(tester, crashReports: crashReports);

      expect(
        find.text(
          'Feedback in Settings opens an anonymous Google form in your browser, and the app sends nothing to it.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('each platform reads only its own scanner line, naming no other platform (App Store 2.3.10)', (
    tester,
  ) async {
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    await _pump(tester, platform: defaultTargetPlatform);

    const own = "nothing leaves the device";
    const google = "Google's code scanner";
    expect(find.textContaining(own, skipOffstage: false), iOS ? findsOneWidget : findsNothing);
    expect(find.textContaining(google, skipOffstage: false), iOS ? findsNothing : findsOneWidget);
    for (final name in ['Android', 'iPhone', 'iOS']) {
      expect(find.textContaining(name, skipOffstage: false), findsNothing, reason: name);
    }
  }, variant: bazaarPlatforms);

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pump(tester, crashReports: true, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
