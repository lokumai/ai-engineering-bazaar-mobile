@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_level_row.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/bazaar_app_harness.dart';

/// Back follows the pages the reader opened (plan 1M): opening a page pushes it, a level chip on a level page takes
/// that page's place, and only the bottom navigation starts the history again.
void main() {
  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = AppRouterFactory(initialLocation: location).create();
    final track = TrackCubit();
    addTearDown(router.dispose);
    addTearDown(track.close);
    await tester.pumpWidget(bazaarTestApp(router: router, track: track));
    await tester.pumpAndSettle();
    return router;
  }

  String path(GoRouter router) => router.state.uri.path;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

  Future<void> back(WidgetTester tester) => tap(tester, find.byType(BackButton));

  testWidgets('a level chip on the catalog root pushes the level, so back returns to the root', (tester) async {
    final router = await pumpAt(tester, '/sheets');

    await tap(tester, chip('Beta Level'));
    expect(path(router), '/sheets/beta');

    await back(tester);
    expect(path(router), '/sheets');
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('a level chip on a level page takes its place, so back skips the levels tried', (tester) async {
    final router = await pumpAt(tester, '/');
    await tap(tester, find.descendant(of: find.byType(HomeLevelRow), matching: find.text('Alpha Level')));
    expect(path(router), '/sheets/alpha');

    await tap(tester, chip('Beta Level'));
    await tap(tester, chip('Gamma Level'));
    expect(path(router), '/sheets/gamma');

    await back(tester);
    expect(path(router), '/', reason: 'back to Home, where the level was opened');
  });

  testWidgets('All on a level page opened from the root returns to that root', (tester) async {
    final router = await pumpAt(tester, '/sheets');
    await tap(tester, chip('Alpha Level'));
    await tap(tester, chip('Beta Level'));

    await tap(tester, chip('All'));
    expect(path(router), '/sheets');
    expect(find.byType(BackButton), findsNothing, reason: 'the root itself, not a second copy over it');
  });

  testWidgets('All on a level page opened from Home puts the root in its place', (tester) async {
    final router = await pumpAt(tester, '/');
    await tap(tester, find.descendant(of: find.byType(HomeLevelRow), matching: find.text('Alpha Level')));

    await tap(tester, chip('All'));
    expect(path(router), '/sheets');

    await back(tester);
    expect(path(router), '/');
  });

  testWidgets('a module opened from a level page returns to it, and the level page to Home', (tester) async {
    final router = await pumpAt(tester, '/');
    await tap(tester, find.descendant(of: find.byType(HomeLevelRow), matching: find.text('Alpha Level')));
    await tap(tester, find.text('First Module').first);
    expect(path(router), '/courses/alpha/first');

    await back(tester);
    expect(path(router), '/sheets/alpha');
    await back(tester);
    expect(path(router), '/');
  });
}
