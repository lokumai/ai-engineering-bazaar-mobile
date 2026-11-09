import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_router.dart';
import 'package:flutter_bloc_advance/app/router/home_placeholder_page.dart';
import 'package:flutter_bloc_advance/app/router/not_found_page.dart';
import 'package:flutter_bloc_advance/app/shell/app_shell.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
  router.go(location);
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('AppRouterFactory', () {
    test('starts on /', () {
      final router = const AppRouterFactory().create();
      addTearDown(router.dispose);

      expect(router.routeInformationProvider.value.uri.path, '/');
    });

    testWidgets('/ shows the home page inside the shell', (tester) async {
      await pumpAt(tester, '/');

      expect(find.byType(HomePlaceholderPage), findsOneWidget);
      expect(find.ancestor(of: find.byType(HomePlaceholderPage), matching: find.byType(AppShell)), findsOneWidget);
    });

    testWidgets('/settings shows the settings page inside the shell', (tester) async {
      await pumpAt(tester, '/settings');

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.ancestor(of: find.byType(SettingsScreen), matching: find.byType(AppShell)), findsOneWidget);
    });

    testWidgets('an unknown path shows the not-found page outside the shell', (tester) async {
      await pumpAt(tester, '/no-such-page');

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('the not-found page goes home', (tester) async {
      final router = await pumpAt(tester, '/no-such-page');

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/');
      expect(find.byType(HomePlaceholderPage), findsOneWidget);
    });
  });
}
