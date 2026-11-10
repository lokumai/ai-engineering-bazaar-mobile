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
import '../../../../support/fold.dart';

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

Finder _inOverview(String text) => find.descendant(of: find.byType(CatalogOverview), matching: find.text(text));

/// The Planned mark in the row of the module [key].
Finder _plannedIn(String key) =>
    find.descendant(of: find.byKey(CatalogOverview.rowKey(key)), matching: find.bySemanticsLabel('Planned'));

/// The button of the level titled [title], found by the start of its spoken label.
Finder _level(String title) => find.bySemanticsLabel(RegExp('^$title,'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on its name, one button per level, with no filters, the next level open (owner review)', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    // The page's name heads its content, so the catalog and the Quiz tab do not open alike (review findings, D).
    expect(find.descendant(of: find.byType(ListView), matching: find.text('Catalog')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    for (final slug in ['alpha', 'beta', 'gamma']) {
      expect(find.byKey(CatalogOverview.levelKey(slug)), findsOneWidget, reason: slug);
    }
    expect(
      tester.getSemantics(_level('Alpha Level')),
      isSemantics(label: 'Alpha Level, 3 modules · ~1 h 15 min, 1/3 completed', isButton: true, hasExpandedState: true),
    );
    expect(
      tester.getSemantics(_level('Alpha Level')),
      isSemantics(isExpanded: true, hasExpandedState: true),
      reason: 'alpha/second is the next module to read',
    );
    expect(tester.getSemantics(_level('Beta Level')), isSemantics(isExpanded: false, hasExpandedState: true));
    expect(_inOverview('Fourth Module'), findsNothing, reason: 'beta starts closed');
  });

  testWidgets('a level opens its modules under it, and a second tap closes them', (tester) async {
    await _pumpCatalog(tester);

    await openFold(tester, _level('Alpha Level'));
    expect(tester.getSemantics(_level('Alpha Level')), isSemantics(isExpanded: true, hasExpandedState: true));
    for (final title in ['First Module', 'Second Module', 'Third Module']) {
      expect(_inOverview(title), findsOneWidget, reason: title);
    }
    expect(_inOverview('Fourth Module'), findsNothing, reason: 'beta stays closed');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Complete First Module')),
      isSemantics(hasCheckedState: true, isChecked: true),
      reason: 'alpha/first is completed',
    );
    expect(_plannedIn('alpha/third'), findsOneWidget, reason: 'alpha/third is planned For Engineers');

    await _tap(tester, _level('Beta Level'));
    expect(_inOverview('First Module'), findsOneWidget, reason: 'several levels open at once');
    expect(_inOverview('Fourth Module'), findsOneWidget);

    await _tap(tester, _level('Alpha Level'));
    expect(_inOverview('First Module'), findsNothing);
    expect(tester.getSemantics(_level('Alpha Level')), isSemantics(isExpanded: false, hasExpandedState: true));
  });

  testWidgets('what the reader opens or closes stays while the app runs; a new launch opens the next level', (
    tester,
  ) async {
    final router = await _pumpCatalog(tester);
    await _tap(tester, _level('Alpha Level'));
    await _tap(tester, _level('Beta Level'));

    router.go('/quiz');
    await tester.pumpAndSettle();
    router.go('/sheets');
    await tester.pumpAndSettle();
    expect(_inOverview('First Module'), findsNothing, reason: 'alpha stays closed');
    expect(_inOverview('Fourth Module'), findsOneWidget, reason: 'beta stays open');

    await tester.pumpWidget(const SizedBox());
    await _pumpCatalog(tester);
    expect(_inOverview('First Module'), findsOneWidget, reason: 'a new launch');
    expect(_inOverview('Fourth Module'), findsNothing);
  });

  testWidgets('the For Everyone catalog lists the same modules, planned where not written', (tester) async {
    await _pumpCatalog(tester, '/everyone/sheets');
    await openFold(tester, _level('Alpha Level'));

    expect(_inOverview('First Module'), findsOneWidget);
    expect(find.text('First Story'), findsNothing);
    expect(_plannedIn('alpha/second'), findsOneWidget);
    expect(_plannedIn('alpha/third'), findsOneWidget);
    expect(_plannedIn('alpha/first'), findsNothing);
  });

  testWidgets('a module opens the module of the track, and back finds its level still open', (tester) async {
    var router = await _pumpCatalog(tester);
    await openFold(tester, _level('Alpha Level'));
    await _tap(tester, _inOverview('First Module'));
    expect(_path(router), '/courses/alpha/first');
    router.pop();
    await tester.pumpAndSettle();
    expect(_path(router), '/sheets');
    expect(_inOverview('First Module'), findsOneWidget);

    router = await _pumpCatalog(tester, '/everyone/sheets');
    await openFold(tester, _level('Alpha Level'));
    await _tap(tester, _inOverview('First Module'));
    expect(_path(router), '/everyone/courses/alpha/first');
  });

  testWidgets('text scale 2.0', (tester) async {
    await pumpAtTextScale(tester, bazaarTestApp(router: _router(), record: _firstCompleted()), scale: 2.0);

    expect(tester.takeException(), isNull);
    await openFold(tester, _level('Alpha Level'));
    expect(tester.takeException(), isNull);
    for (final target in [_level('Gamma Level'), _inOverview('Third Module')]) {
      await tester.ensureVisible(target);
      await tester.pump();
      expectHittable(tester, target);
    }
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(
      bazaarTestApp(platform: defaultTargetPlatform, router: _router(), record: _firstCompleted()),
    );
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
