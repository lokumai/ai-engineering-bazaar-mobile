@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/accessibility.dart';
import '../../support/bazaar_app_harness.dart';
import '../../support/fold.dart';

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
  await openFold(tester, find.bySemanticsLabel(RegExp('^$level,')));
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

/// The shell over a long list at [location], a module page unless told otherwise, for the scroll behaviour alone.
Future<void> _pumpLongPage(WidgetTester tester, String location) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (_, state, child) => BazaarShell(location: state.uri.path, child: child),
        routes: [
          for (final path in ['/courses/:level/:module', '/sheets'])
            GoRoute(
              path: path,
              builder: (_, _) =>
                  ListView(children: [for (var i = 0; i < 40; i++) SizedBox(height: 100, child: Text('$i'))]),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router));
  await tester.pumpAndSettle();
}

/// The height the navigation takes at the foot of the shell.
double _navHeight(WidgetTester tester) =>
    tester.getSize(find.ancestor(of: find.byType(NavigationBar), matching: find.byType(ClipRect)).first).height;

/// The height the bar and the band take under the status strip.
double _barHeight(WidgetTester tester) =>
    tester.getSize(find.ancestor(of: find.byType(BazaarBar), matching: find.byType(ClipRect)).first).height;

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView), Offset(0, dy));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tab\'s page has an empty bar, and the lattice band under the status strip; no track switch', (
    tester,
  ) async {
    await _pumpAt(tester, '/sheets', TrackCubit());

    final bar = find.byType(BazaarBar);
    expect(find.descendant(of: bar, matching: find.byType(Text)), findsNothing);
    expect(find.descendant(of: bar, matching: find.byType(Image)), findsNothing);
    expect(tester.getSize(bar).height, 0);
    expect(find.byType(LatticeBand), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(LatticeBand)).dy,
      tester.getBottomLeft(find.byType(BazaarStatusStrip)).dy,
      reason: 'right under the strip',
    );
    expect(find.text('For Everyone'), findsNothing, reason: 'plan 1L: no switch on the pages');
  });

  testWidgets('the bar names a level and a module from the index, and none of the four tabs (owner, 2026-11-10)', (
    tester,
  ) async {
    for (final location in ['/', '/sheets', '/everyone/sheets', '/quiz', '/settings']) {
      await _pumpAt(tester, location, TrackCubit());
      expect(
        find.descendant(of: find.byType(BazaarBar), matching: find.byType(Text)),
        findsNothing,
        reason: location,
      );
    }
    for (final (location, title) in [('/sheets/alpha', 'Alpha Level'), ('/courses/alpha/first', 'First Module')]) {
      await _pumpAt(tester, location, TrackCubit());
      expect(
        find.descendant(of: find.byType(BazaarBar), matching: find.text(title)),
        findsOneWidget,
        reason: location,
      );
    }
  });

  testWidgets("a level's page and a module's carry the level's hue, with the title at the end of the bar", (
    tester,
  ) async {
    for (final location in ['/sheets/beta', '/courses/beta/fourth', '/everyone/sheets/beta']) {
      await _pumpAt(tester, location, TrackCubit());
      final bar = find.byType(BazaarBar);
      final context = tester.element(bar);
      expect(tester.widget<BazaarBar>(bar).accent, levelHue(context, 1), reason: location);
      final title = find.descendant(of: bar, matching: find.byType(Text)).last;
      expect(tester.getTopRight(title).dx, closeTo(tester.getTopRight(bar).dx - 16, 1), reason: location);
    }
    for (final location in ['/', '/sheets', '/quiz', '/settings']) {
      await _pumpAt(tester, location, TrackCubit());
      expect(tester.widget<BazaarBar>(find.byType(BazaarBar)).accent, isNull, reason: location);
    }
  });

  testWidgets('on a module page the navigation slides away on a scroll down and back on a scroll up', (tester) async {
    await _pumpLongPage(tester, '/courses/alpha/first');
    final full = _navHeight(tester);
    final bar = _barHeight(tester);
    expect(full, greaterThan(0));
    expect(bar, greaterThanOrEqualTo(LatticeBand.thinHeight));

    await _scroll(tester, -10);
    expect(_navHeight(tester), full, reason: 'a short move leaves it');
    await _scroll(tester, -300);
    expect(_navHeight(tester), 0, reason: 'hidden while reading down');
    expect(_barHeight(tester), 0, reason: 'the bar and the band fold with it');
    expect(find.byType(BazaarStatusStrip), findsOneWidget);
    expect(find.bySemanticsLabel('Home'), findsNothing, reason: 'hidden from assistive technology');

    await _scroll(tester, 100);
    expect(_navHeight(tester), full, reason: 'back on a scroll up');
    expect(_barHeight(tester), bar);

    await _scroll(tester, -300);
    expect(_navHeight(tester), 0);
    await _scroll(tester, -10000);
    expect(_navHeight(tester), full, reason: 'back at the end');
  });

  testWidgets('the navigation stays on a page that is not a module, and while a screen reader runs', (tester) async {
    await _pumpLongPage(tester, '/sheets');
    final full = _navHeight(tester);
    await _scroll(tester, -300);
    expect(_navHeight(tester), full, reason: 'the catalog');

    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      accessibleNavigation: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpLongPage(tester, '/courses/alpha/first');
    await _scroll(tester, -300);
    expect(_navHeight(tester), full, reason: 'a screen reader');
  });

  testWidgets('under reduced motion the navigation goes at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpLongPage(tester, '/courses/alpha/first');
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(_navHeight(tester), 0);
  });

  testWidgets('the status strip is on the page ground with icons that read on it, and the bar starts under it', (
    tester,
  ) async {
    for (final (brightness, icons) in [(Brightness.light, Brightness.dark), (Brightness.dark, Brightness.light)]) {
      final router = AppRouterFactory(initialLocation: '/sheets').create();
      addTearDown(router.dispose);
      await tester.pumpWidget(bazaarTestApp(router: router, brightness: brightness));
      await tester.pumpAndSettle();

      final strip = find.byType(BazaarStatusStrip);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(of: strip, matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
      );
      expect(region.value.statusBarIconBrightness, icons, reason: 'Android, $brightness');
      expect(region.value.statusBarBrightness, brightness, reason: 'iOS, $brightness');
      final ground = Theme.of(tester.element(strip)).scaffoldBackgroundColor;
      expect(tester.widget<ColoredBox>(find.descendant(of: strip, matching: find.byType(ColoredBox))).color, ground);
      expect(tester.getBottomLeft(strip).dy, tester.getTopLeft(find.byType(BazaarBar)).dy);
    }
  });

  testWidgets('the bar is as high with a back button as without', (tester) async {
    await _pumpAt(tester, '/courses/alpha/first', TrackCubit());
    expect(find.byType(BackButton), findsNothing, reason: 'opened directly');
    final root = tester.getSize(find.byType(BazaarBar)).height;
    await _pumpAt(tester, '/sheets', TrackCubit());
    await _pushFromCatalog(tester, 'Alpha Level', 'First Module');
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.getSize(find.byType(BazaarBar)).height, root);
    expect(root, BazaarBar.height, reason: "the bar alone, the strip being the shell's");
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

    router.go('/quiz');
    await tester.pumpAndSettle();
    expect(track.state, Track.everyone, reason: 'a page of neither track keeps the remembered track');
  });

  testWidgets('the bottom navigation', (tester) async {
    final track = TrackCubit();
    final router = await _pumpAt(tester, '/sheets/alpha', track);
    int selected() => tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    expect(_destination('Home'), findsOneWidget);
    expect(_destination('Catalog'), findsOneWidget);
    expect(_destination('Quiz'), findsOneWidget);
    expect(_destination('Settings'), findsOneWidget);
    expect(selected(), 1, reason: 'a level page is under Catalog');

    await tester.tap(_destination('Quiz'));
    await tester.pumpAndSettle();
    expect(_path(router), '/quiz');
    expect(selected(), 2);

    await tester.tap(_destination('Settings'));
    await tester.pumpAndSettle();
    expect(_path(router), '/settings');
    expect(selected(), 3);

    await tester.tap(_destination('Home'));
    await tester.pumpAndSettle();
    expect(_path(router), '/');
    expect(selected(), 0);

    router.go('/quiz');
    await tester.pumpAndSettle();
    track.select(Track.everyone);
    await tester.pumpAndSettle();
    await tester.tap(_destination('Catalog'));
    await tester.pumpAndSettle();
    expect(_path(router), '/everyone/sheets');
    expect(selected(), 1);
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = AppRouterFactory(initialLocation: '/sheets').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router), scale: 2.0);

    expect(tester.takeException(), isNull);
    expectHittable(tester, _destination('Home'));
    expectHittable(tester, _destination('Catalog'));
    expectHittable(tester, _destination('Quiz'));
    expectHittable(tester, _destination('Settings'));
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    final router = AppRouterFactory(initialLocation: '/quiz').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(platform: defaultTargetPlatform, router: router));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
