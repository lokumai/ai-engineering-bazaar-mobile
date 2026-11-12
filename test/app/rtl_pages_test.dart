@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/bazaar_app_harness.dart';

/// The main pages in Persian, right to left: each is drawn with no overflow or other error, its text runs right to left,
/// and the navigation starts on the right, Home first.
void main() {
  for (final (name, location) in [
    ('Home', '/'),
    ('the catalog', '/sheets'),
    ("a level's page", '/sheets/alpha'),
    ('Quiz', '/quiz'),
    ('Settings', '/settings'),
    ("a module's page", '/courses/alpha/first'),
  ]) {
    testWidgets('$name in Persian is drawn right to left', (tester) async {
      final router = AppRouterFactory(initialLocation: location).create();
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router, locale: const Locale('fa')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, location);
      final shell = find.byType(BazaarShell);
      expect(Directionality.of(tester.element(shell)), TextDirection.rtl);
      final nav = find.byType(NavigationBar);
      final destinations = find.descendant(of: nav, matching: find.byType(NavigationDestination));
      expect(destinations, findsNWidgets(5));
      expect(
        tester.getCenter(destinations.first).dx,
        greaterThan(tester.getCenter(destinations.last).dx),
        reason: 'Home, the first, on the right; Settings, the last, on the left',
      );
    });
  }
}
