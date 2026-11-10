import 'package:ai_engineering_bazaar/features/settings/navigation/settings_routes.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/privacy_legal_page.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_page.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/bazaar_app_harness.dart';

void main() {
  test('settings feature exposes the settings route and its privacy and legal page', () {
    final routes = SettingsFeatureRoutes.routes(openDevConsole: null, crashReports: false);

    expect(
      [for (final route in routes) (route.name, route.path)],
      [('settings', ApplicationRoutesConstants.settings), ('privacyLegal', ApplicationRoutesConstants.privacyLegal)],
    );
  });

  for (final crashReports in [false, true]) {
    testWidgets('the privacy page is told the build ${crashReports ? 'sends' : 'sends no'} crash reports', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: ApplicationRoutesConstants.privacyLegal,
        routes: SettingsFeatureRoutes.routes(openDevConsole: null, crashReports: crashReports),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router));
      await tester.pumpAndSettle();

      expect(tester.widget<PrivacyLegalPage>(find.byType(PrivacyLegalPage)).crashReports, crashReports);
    });
  }

  for (final withCallback in [false, true]) {
    testWidgets('the route passes ${withCallback ? 'the' : 'no'} dev console callback to the page', (tester) async {
      void open(BuildContext context) {}
      final callback = withCallback ? open : null;
      final router = GoRouter(
        initialLocation: ApplicationRoutesConstants.settings,
        routes: SettingsFeatureRoutes.routes(openDevConsole: callback, crashReports: false),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router));
      await tester.pumpAndSettle();

      expect(tester.widget<SettingsPage>(find.byType(SettingsPage)).openDevConsole, callback);
      expect(tester.widget<SettingsScreen>(find.byType(SettingsScreen)).openDevConsole, callback);
    });
  }
}
