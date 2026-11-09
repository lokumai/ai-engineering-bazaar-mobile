@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/dev_console/content_gallery_page.dart';
import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/app/router/not_found_page.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/pages/progress_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/bazaar_app_harness.dart';

/// Pumps the app's router at `/`, then goes to [location] and settles.
Future<RouteMatchList> _matchAt(WidgetTester tester, String location) async {
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router));
  router.go(location);
  await tester.pumpAndSettle();
  return router.routerDelegate.currentConfiguration;
}

/// [location] as written and, except for `/`, with a trailing slash: go_router 18.1.1 strips the slash before matching.
Set<String> _forms(String location) => {location, if (location != '/') '$location/'};

void main() {
  test('starts on /', () {
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  // (location, path after redirects, route name, path parameters)
  const rows = <(String, String, String, Map<String, String>)>[
    ('/', '/', 'catalog', {}),
    ('/everyone/sheets', '/everyone/sheets', 'catalogEveryone', {}),
    ('/sheets', '/', 'catalog', {}),
    ('/sheets/alpha', '/sheets/alpha', 'level', {'level': 'alpha'}),
    ('/everyone/sheets/alpha', '/everyone/sheets/alpha', 'levelEveryone', {'level': 'alpha'}),
    ('/courses', '/', 'catalog', {}),
    ('/courses/alpha', '/sheets/alpha', 'level', {'level': 'alpha'}),
    ('/courses/alpha/first', '/courses/alpha/first', 'module', {'level': 'alpha', 'module': 'first'}),
    (
      '/everyone/courses/alpha/first',
      '/everyone/courses/alpha/first',
      'moduleEveryone',
      {'level': 'alpha', 'module': 'first'},
    ),
    ('/profile', '/profile', 'progress', {}),
    ('/settings', '/settings', 'settings', {}),
  ];
  for (final (location, path, name, params) in rows) {
    for (final form in _forms(location)) {
      testWidgets('$form opens $name at $path inside the shell', (tester) async {
        final match = await _matchAt(tester, form);

        expect(match.isError, isFalse);
        expect(match.uri.path, path);
        expect(match.last.route.name, name);
        expect(match.pathParameters, params);
        expect(find.byType(BazaarShell), findsOneWidget);
        // The default missingContentRepository() settles the reader on its unreadable state.
        if (name.startsWith('module')) {
          expect(find.byType(ModuleReaderPage), findsOneWidget);
          // Decision A38: the router is the one place that hands the quiz feature's panel to the reader.
          expect(tester.widget<ModuleReaderPage>(find.byType(ModuleReaderPage)).quizBuilder, buildQuizPanel);
        }
        if (name == 'progress') expect(find.byType(ProgressPage), findsOneWidget);
      });
    }
  }

  const notFound = [
    '/dashboard',
    '/path',
    '/report',
    '/everyone',
    '/everyone/courses',
    '/everyone/courses/alpha',
    '/sheets/alpha/first',
    '/legend',
    '/nope',
  ];
  for (final location in notFound) {
    for (final form in _forms(location)) {
      testWidgets('$form shows the not-found page outside the shell', (tester) async {
        final match = await _matchAt(tester, form);

        expect(match.isError, isTrue);
        expect(find.byType(NotFoundPage), findsOneWidget);
        expect(find.byType(BazaarShell), findsNothing);
      });
    }
  }

  // Tests run with kDebugMode true; the default missingContentRepository() makes every document unreadable, so the
  // gallery settles.
  testWidgets('/debug/gallery opens the content gallery in a debug build', (tester) async {
    final router = const AppRouterFactory(initialLocation: '/debug/gallery').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.last.route.name, 'debugGallery');
    expect(find.byType(ContentGalleryPage), findsOneWidget);
  });

  // Decision A6: a phone cannot send Ctrl+Shift+D, so a debug build opens the console from Settings.
  testWidgets('/settings offers the developer console in a debug build', (tester) async {
    final router = const AppRouterFactory(initialLocation: '/settings').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Developer console'), findsOneWidget);
    await tester.tap(find.text('Developer console'));
    await tester.pumpAndSettle();

    expect(find.text('Time Travel'), findsOneWidget);
  });

  testWidgets('route transitions take no time under reduced motion', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router));
    router.go('/settings');
    await tester.pump();

    final route = ModalRoute.of(tester.element(find.byType(SettingsScreen)))!;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('route transitions animate otherwise', (tester) async {
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router));
    router.go('/settings');
    await tester.pumpAndSettle();

    final route = ModalRoute.of(tester.element(find.byType(SettingsScreen)))!;
    expect(route.transitionDuration, isNot(Duration.zero));
    expect(route.reverseTransitionDuration, isNot(Duration.zero));
  });
}
