@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_level_row.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/bazaar_app_harness.dart';

/// Back follows the pages the reader opened (plan 1M): opening a page pushes it, and only the bottom navigation starts
/// the history again.
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

  Future<void> back(WidgetTester tester) => tap(tester, find.byType(BackButton));

  testWidgets('a module opened from Home returns to Home', (tester) async {
    final router = await pumpAt(tester, '/');
    await tap(tester, find.text('Open the module'));
    expect(path(router), '/courses/alpha/first');

    await back(tester);
    expect(path(router), '/');
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('a module opened from the catalog returns to the catalog, its level still open', (tester) async {
    final router = await pumpAt(tester, '/sheets');
    await tap(tester, find.bySemanticsLabel(RegExp('^Beta Level,')));
    await tap(tester, find.text('Fourth Module'));
    expect(path(router), '/courses/beta/fourth');

    await back(tester);
    expect(path(router), '/sheets');
    expect(find.text('Fourth Module'), findsOneWidget);
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
