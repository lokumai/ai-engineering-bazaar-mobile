import 'package:ai_engineering_bazaar/features/settings/navigation/settings_routes.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_page.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/bazaar_app_harness.dart';

void main() {
  test('settings feature exposes expected route', () {
    final routes = SettingsFeatureRoutes.routes(openDevConsole: null);

    expect(routes, hasLength(1));
    expect(routes.single.path, ApplicationRoutesConstants.settings);
    expect(routes.single.name, 'settings');
  });

  for (final withCallback in [false, true]) {
    testWidgets('the route passes ${withCallback ? 'the' : 'no'} dev console callback to the page', (tester) async {
      void open(BuildContext context) {}
      final callback = withCallback ? open : null;
      final router = GoRouter(
        initialLocation: ApplicationRoutesConstants.settings,
        routes: SettingsFeatureRoutes.routes(openDevConsole: callback),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router));
      await tester.pumpAndSettle();

      expect(tester.widget<SettingsPage>(find.byType(SettingsPage)).openDevConsole, callback);
      expect(tester.widget<SettingsScreen>(find.byType(SettingsScreen)).openDevConsole, callback);
    });
  }
}
