import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/catalog_page.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/bazaar_app_harness.dart';
import '../support/content_fixture.dart';

void main() {
  group('App', () {
    testWidgets('mounts the router once content and record are ready', (tester) async {
      await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CatalogPage), findsNothing);

      await pumpUntilFound(tester, find.byType(CatalogPage));
      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('follows the system theme with the light and dark app themes', (tester) async {
      await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(app.theme!.brightness, Brightness.light);
      expect(app.darkTheme!.brightness, Brightness.dark);
      expect(app.theme!.extension<BazaarColors>(), BazaarColors.light);
      expect(app.darkTheme!.extension<BazaarColors>(), BazaarColors.dark);
    });

    testWidgets('names the app with app_title', (tester) async {
      await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));
      await tester.pump();

      expect(tester.widget<Title>(find.byType(Title)).title, 'AI Engineering Bazaar');
    });

    testWidgets('provides the AppConfig of its dependencies', (tester) async {
      await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));
      await pumpUntilFound(tester, find.byType(CatalogPage));

      expect(tester.element(find.byType(CatalogPage)).read<AppConfig>().environment, Environment.test);
    });
  });
}
