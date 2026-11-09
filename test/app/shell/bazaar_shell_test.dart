@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_label.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/accessibility.dart';
import '../../support/bazaar_app_harness.dart';

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

/// Opens the module [title] from the catalog root: its level [level] opens first, then the module is pushed.
Future<void> _pushFromCatalog(WidgetTester tester, String level, String title) async {
  await _tap(tester, find.bySemanticsLabel(RegExp('^$level,')));
  await _tap(tester, find.descendant(of: find.byType(CatalogOverview), matching: find.text(title)));
}

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

void main() {
  testWidgets('the bar shows the logo and the app title over the lattice band; the page names its track', (
    tester,
  ) async {
    await _pumpAt(tester, '/sheets', TrackCubit());

    final bar = find.ancestor(of: find.byType(Image), matching: find.byType(Row)).first;
    final barSurface = find.ancestor(of: bar, matching: find.byType(Material)).first;
    expect(find.descendant(of: bar, matching: find.text('AI Engineering Bazaar')), findsOneWidget);
    expect(find.byType(LatticeBand), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(LatticeBand)).dy,
      tester.getBottomLeft(barSurface).dy,
      reason: 'under the bar',
    );
    expect(find.descendant(of: find.byType(TrackLabel), matching: find.text('For Engineers')), findsOneWidget);
    expect(find.text('For Everyone'), findsNothing, reason: 'plan 1L: no switch on the pages');
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

    await _pushFromCatalog(tester, 'Alpha Level', 'First Module');
    expect(find.byType(BackButton), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(_path(router), '/sheets');
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Android back pops a pushed page and leaves the app only from the first page', (tester) async {
    final router = await _pumpAt(tester, '/sheets', TrackCubit());
    final calls = _watchPlatformCalls(tester);
    await _pushFromCatalog(tester, 'Beta Level', 'Fourth Module');
    expect(_path(router), '/courses/beta/fourth');

    await _back(tester);
    expect(_path(router), '/sheets');
    expect(calls, isNot(contains('SystemNavigator.pop')));

    await _back(tester);
    expect(calls, contains('SystemNavigator.pop'));
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

  testWidgets('a page of the other track, opened by a link, names that track', (tester) async {
    final track = TrackCubit();
    await _pumpAt(tester, '/everyone/sheets/beta', track);

    expect(find.descendant(of: find.byType(TrackLabel), matching: find.text('For Everyone')), findsOneWidget);
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = AppRouterFactory(initialLocation: '/sheets').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
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
