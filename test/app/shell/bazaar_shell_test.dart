@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_switch.dart';
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
  // The page's list builds lazily, so a widget scrolled far up is no longer built: scroll back to it first.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, -200, scrollable: find.byType(Scrollable).last);
  }
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
  testWidgets('the bar shows the logo and the app title over the lattice band; the switch is on the page', (
    tester,
  ) async {
    await _pumpAt(tester, '/sheets', TrackCubit());

    final bar = find.ancestor(of: find.byType(Image), matching: find.byType(Row)).first;
    final barSurface = find.ancestor(of: bar, matching: find.byType(Material)).first;
    expect(find.descendant(of: bar, matching: find.text('AI Engineering Bazaar')), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byType(TrackSwitch)), findsNothing);
    expect(find.byType(LatticeBand), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(LatticeBand)).dy,
      tester.getBottomLeft(barSurface).dy,
      reason: 'under the bar',
    );
    expect(tester.getSemantics(_engineers), isSemantics(label: 'For Engineers', isSelected: true, isButton: true));
    expect(tester.getSemantics(_everyone), isSemantics(label: 'For Everyone', isSelected: false, isButton: true));
  });

  testWidgets('the bar asks for light status bar icons, since it is navy in both themes', (tester) async {
    await _pumpAt(tester, '/sheets', TrackCubit());

    final bar = find.ancestor(of: find.byType(Image), matching: find.byType(Row)).first;
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.ancestor(of: bar, matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)).first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.light, reason: 'Android');
    expect(region.value.statusBarBrightness, Brightness.dark, reason: 'iOS: the bar behind the status bar is dark');
  });

  testWidgets('the bar offers back only over a pushed page, and back returns to the page below', (tester) async {
    final router = await _pumpAt(tester, '/sheets', TrackCubit());
    expect(find.byType(BackButton), findsNothing);

    await _pushFromCatalog(tester, 'First Module');
    expect(find.byType(BackButton), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(_path(router), '/sheets');
    expect(find.byType(BackButton), findsNothing);
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
    expect(_path(router), '/sheets');
  });

  testWidgets('the switch on a pushed page opens the other track on top, and back returns to it', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/sheets', track);
    await _pushFromCatalog(tester, 'Beta Level');
    // Open a card's Description: state of this page, kept while it stays below.
    await _tap(tester, find.text('Description'));
    expect(find.text('Summary of the fourth module.'), findsOneWidget);

    // The segment of the page shown does nothing: the page and the catalog below it stay.
    await _tap(tester, _engineers);
    expect(_path(router), '/sheets/beta');
    expect(find.text('Summary of the fourth module.'), findsOneWidget);
    expect(router.canPop(), isTrue);

    await _tap(tester, _everyone);
    expect(_path(router), '/everyone/sheets/beta');
    expect(track.state, Track.everyone);

    final calls = _watchPlatformCalls(tester);
    await _back(tester);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(_path(router), '/sheets/beta');
    expect(find.text('Summary of the fourth module.'), findsOneWidget, reason: 'the page below keeps its state');
    expect(track.state, Track.engineers);
    _expectSelected(tester, Track.engineers);

    await _back(tester);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(_path(router), '/sheets');
  });

  testWidgets('back after a switch on a pushed module returns to the module of the first track', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/sheets', track);
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

  testWidgets('opening a track page remembers its track', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/everyone/sheets', track);

    expect(track.state, Track.everyone);

    router.go('/profile');
    await tester.pumpAndSettle();
    expect(track.state, Track.everyone, reason: 'a page of neither track keeps the remembered track');
  });

  testWidgets('the bottom navigation', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/sheets/alpha', track);
    int selected() => tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    expect(_destination('Home'), findsOneWidget);
    expect(_destination('Catalog'), findsOneWidget);
    expect(_destination('Progress'), findsOneWidget);
    expect(_destination('Settings'), findsOneWidget);
    expect(selected(), 1, reason: 'a level page is under Catalog');

    await tester.tap(_destination('Progress'));
    await tester.pumpAndSettle();
    expect(_path(router), '/profile');
    expect(selected(), 2);

    await tester.tap(_destination('Settings'));
    await tester.pumpAndSettle();
    expect(_path(router), '/settings');
    expect(selected(), 3);

    await tester.tap(_destination('Home'));
    await tester.pumpAndSettle();
    expect(_path(router), '/');
    expect(selected(), 0);

    router.go('/profile');
    await tester.pumpAndSettle();
    track.select(Track.everyone);
    await tester.pumpAndSettle();
    await tester.tap(_destination('Catalog'));
    await tester.pumpAndSettle();
    expect(_path(router), '/everyone/sheets');
    expect(selected(), 1);
  });

  testWidgets('on Home, a page of neither track, the switch changes the remembered track only', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/', track);

    await _tap(tester, _everyone);

    expect(_path(router), '/');
    expect(track.state, Track.everyone);
    _expectSelected(tester, Track.everyone);
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = AppRouterFactory(initialLocation: '/sheets').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    expectHittable(tester, _engineers);
    expectHittable(tester, _everyone);
    expectHittable(tester, _destination('Home'));
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
