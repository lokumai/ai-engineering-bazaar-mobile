@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The record with `alpha/first` completed For Engineers.
RecordBloc _firstCompleted() =>
    readyRecordBloc(signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-09T10:00:00.000Z'));

GoRouter _router([String location = '/sheets']) {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  return router;
}

Future<GoRouter> _pumpCatalog(WidgetTester tester, [String location = '/sheets']) async {
  final router = _router(location);
  await tester.pumpWidget(bazaarTestApp(router: router, record: _firstCompleted()));
  await tester.pumpAndSettle();
  return router;
}

/// The path of the page on top, a pushed one included.
String _path(GoRouter router) => router.state.uri.path;

Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

Finder get _levelAll => _chip('All');

bool _selected(WidgetTester tester, Finder chip) => tester.widget<ChoiceChip>(chip).selected;

Finder _inOverview(String text) => find.descendant(of: find.byType(CatalogOverview), matching: find.text(text));

/// The tap target of the overview row titled [title].
Finder _row(String title) => find.ancestor(of: _inOverview(title), matching: find.byType(InkWell)).first;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, both filter rows and the count', (tester) async {
    await _pumpCatalog(tester);

    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('Catalog')),
      findsOneWidget,
      reason: 'the header, outside the NavigationBar',
    );
    expect(find.text('Level:'), findsOneWidget);
    expect(_chip('All'), findsOneWidget);
    for (final label in ['Alpha Level', 'Beta Level', 'Gamma Level']) {
      expect(_chip(label), findsOneWidget, reason: label);
    }
    expect(_selected(tester, _levelAll), isTrue);
    // Plan 1N: no Status chips and no count; each row says whether it is planned.
    expect(find.text('Status:'), findsNothing);
    for (final label in ['Ready', 'Planned', 'Completed', 'Not completed']) {
      expect(_chip(label), findsNothing, reason: label);
    }
    expect(find.textContaining('Showing'), findsNothing);
  });

  testWidgets('the overview has one section per level with its written bar', (tester) async {
    await _pumpCatalog(tester);

    expect(find.bySemanticsLabel('2 of 3 written'), findsOneWidget);
    expect(find.bySemanticsLabel('1 of 2 written'), findsOneWidget);
    expect(find.bySemanticsLabel('1 of 1 written'), findsOneWidget);
    expect(find.descendant(of: _row('First Module'), matching: find.text('01')), findsOneWidget);
    expect(_inOverview('Planned'), findsNWidgets(2));
    for (final title in ['Third Module', 'Fifth Module']) {
      expect(
        find.descendant(of: _row(title), matching: find.text('Planned')),
        findsOneWidget,
        reason: title,
      );
    }
    for (final title in ['First Module', 'Second Module', 'Fourth Module', 'Sixth Module']) {
      expect(
        find.descendant(of: _row(title), matching: find.text('Planned')),
        findsNothing,
        reason: title,
      );
    }
  });

  testWidgets('the For Everyone catalog', (tester) async {
    await _pumpCatalog(tester, '/everyone/sheets');

    expect(_inOverview('First Module'), findsOneWidget);
    expect(find.text('First Story'), findsNothing);
    expect(find.bySemanticsLabel('1 of 3 written'), findsOneWidget);
    expect(find.bySemanticsLabel('1 of 2 written'), findsOneWidget);
    expect(find.bySemanticsLabel('1 of 1 written'), findsOneWidget);
  });

  group('links', () {
    testWidgets('a module title opens the module of the track', (tester) async {
      var router = await _pumpCatalog(tester);
      await _tap(tester, _inOverview('First Module'));
      expect(_path(router), '/courses/alpha/first');

      router = await _pumpCatalog(tester, '/everyone/sheets');
      await _tap(tester, _inOverview('First Module'));
      expect(_path(router), '/everyone/courses/alpha/first');
    });

    testWidgets('a section title opens the level page', (tester) async {
      final router = await _pumpCatalog(tester);
      await _tap(tester, _inOverview('Beta Level'));
      expect(_path(router), '/sheets/beta');
    });

    testWidgets('a level chip opens the level page', (tester) async {
      final router = await _pumpCatalog(tester);
      await _tap(tester, _chip('Beta Level'));
      expect(_path(router), '/sheets/beta');
    });
  });

  testWidgets('text scale 2.0', (tester) async {
    await pumpAtTextScale(tester, bazaarTestApp(router: _router(), record: _firstCompleted()), scale: 2.0);

    expect(tester.takeException(), isNull);
    for (final chip in [_levelAll, _chip('Gamma Level')]) {
      await tester.ensureVisible(chip);
      await tester.pump();
      expectHittable(tester, chip);
    }
    await tester.ensureVisible(find.text('First Module'));
    await tester.pump();
    expectHittable(tester, find.text('First Module'));
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(
      bazaarTestApp(platform: defaultTargetPlatform, router: _router(), record: _firstCompleted()),
    );
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
