@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/app/shell/track_switch.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/accessibility.dart';
import '../../support/bazaar_app_harness.dart';

final _engineers = find.byKey(TrackSwitch.segmentKey(Track.engineers));
final _everyone = find.byKey(TrackSwitch.segmentKey(Track.everyone));

Finder _destination(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Pumps the app's router at [location] with [track], and settles.
Future<GoRouter> _pumpAt(WidgetTester tester, String location, TrackCubit track) async {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  addTearDown(track.close);
  await tester.pumpWidget(bazaarTestApp(router: router, track: track));
  await tester.pumpAndSettle();
  return router;
}

/// The path of the page on top, a pushed one included.
String _path(GoRouter router) => router.state.uri.path;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens [title] from the catalog root by its row or section title, which pushes it.
Future<void> _pushFromCatalog(WidgetTester tester, String title) =>
    _tap(tester, find.descendant(of: find.byType(CatalogOverview), matching: find.text(title)));

/// The platform calls the framework makes; Android back with nothing to pop asks for `SystemNavigator.pop`.
List<String> _watchPlatformCalls(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    calls.add(call.method);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

/// Android back, settled.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void _expectSelected(WidgetTester tester, Track track) {
  expect(tester.getSemantics(find.byKey(TrackSwitch.segmentKey(track))), isSemantics(isSelected: true, isButton: true));
  expect(
    tester.getSemantics(find.byKey(TrackSwitch.segmentKey(track.other))),
    isSemantics(isSelected: false, isButton: true),
  );
}

void main() {
  testWidgets('the bar shows the app title and both track segments', (tester) async {
    await _pumpAt(tester, '/', TrackCubit());

    // The placeholder at `/` shows the title as well, so the title is looked up in the bar's row.
    final bar = find.ancestor(of: find.byType(TrackSwitch), matching: find.byType(Row)).first;
    expect(find.descendant(of: bar, matching: find.text('AI Engineering Bazaar')), findsOneWidget);
    expect(_engineers, findsOneWidget);
    expect(_everyone, findsOneWidget);
    expect(tester.getSemantics(_engineers), isSemantics(label: 'For Engineers', isSelected: true, isButton: true));
    expect(tester.getSemantics(_everyone), isSemantics(label: 'For Everyone', isSelected: false, isButton: true));
  });

  testWidgets('the switch keeps the page in the other track', (tester) async {
    final router = await _pumpAt(tester, '/sheets/alpha', TrackCubit());

    await tester.tap(_everyone);
    await tester.pumpAndSettle();
    expect(_path(router), '/everyone/sheets/alpha');

    router.go('/courses/alpha/first');
    await tester.pumpAndSettle();
    await tester.tap(_everyone);
    await tester.pumpAndSettle();
    expect(_path(router), '/everyone/courses/alpha/first');

    router.go('/everyone/sheets');
    await tester.pumpAndSettle();
    await tester.tap(_engineers);
    await tester.pumpAndSettle();
    expect(_path(router), '/');
  });

  testWidgets('the switch on a pushed page opens the other track on top, and back returns to it', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/', track);
    await _pushFromCatalog(tester, 'Beta Level');
    await _tap(tester, find.widgetWithText(ChoiceChip, 'Planned'));
    expect(find.text('Showing 1 of 6'), findsOneWidget);

    // The segment of the page shown does nothing: the page and the catalog below it stay.
    await _tap(tester, _engineers);
    expect(_path(router), '/sheets/beta');
    expect(find.text('Showing 1 of 6'), findsOneWidget);
    expect(router.canPop(), isTrue);

    await _tap(tester, _everyone);
    expect(_path(router), '/everyone/sheets/beta');
    expect(track.state, Track.everyone);

    final calls = _watchPlatformCalls(tester);
    await _back(tester);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(_path(router), '/sheets/beta');
    expect(find.text('Showing 1 of 6'), findsOneWidget, reason: 'the page below keeps its Status filter');
    expect(track.state, Track.engineers);
    _expectSelected(tester, Track.engineers);

    await _back(tester);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(_path(router), '/');
  });

  testWidgets('back after a switch on a pushed module returns to the module of the first track', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/', track);
    await _pushFromCatalog(tester, 'First Module');
    expect(_path(router), '/courses/alpha/first');

    await _tap(tester, _everyone);
    expect(_path(router), '/everyone/courses/alpha/first');
    _expectSelected(tester, Track.everyone);

    final calls = _watchPlatformCalls(tester);
    await _back(tester);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(_path(router), '/courses/alpha/first');
    expect(track.state, Track.engineers);
    _expectSelected(tester, Track.engineers);
  });

  testWidgets('on a page of neither track the switch changes the remembered track only', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/profile', track);

    await tester.tap(_everyone);
    await tester.pumpAndSettle();

    expect(_path(router), '/profile');
    expect(track.state, Track.everyone);
    _expectSelected(tester, Track.everyone);
  });

  testWidgets('opening a track page remembers its track', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/everyone/sheets', track);

    expect(track.state, Track.everyone);

    router.go('/profile');
    await tester.pumpAndSettle();
    _expectSelected(tester, Track.everyone);
  });

  testWidgets('the bottom navigation', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/sheets/alpha', track);

    expect(_destination('Catalog'), findsOneWidget);
    expect(_destination('Progress'), findsOneWidget);
    expect(_destination('Settings'), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);

    await tester.tap(_destination('Progress'));
    await tester.pumpAndSettle();
    expect(_path(router), '/profile');
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);

    await tester.tap(_destination('Settings'));
    await tester.pumpAndSettle();
    expect(_path(router), '/settings');
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);

    router.go('/profile');
    await tester.pumpAndSettle();
    track.select(Track.everyone);
    await tester.pumpAndSettle();
    await tester.tap(_destination('Catalog'));
    await tester.pumpAndSettle();
    expect(_path(router), '/everyone/sheets');
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = AppRouterFactory(initialLocation: '/').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    expectHittable(tester, _engineers);
    expectHittable(tester, _everyone);
    expectHittable(tester, _destination('Catalog'));
    expectHittable(tester, _destination('Progress'));
    expectHittable(tester, _destination('Settings'));
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    final router = AppRouterFactory(initialLocation: '/profile').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(platform: defaultTargetPlatform, router: router));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
