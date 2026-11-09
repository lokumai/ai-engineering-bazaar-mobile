@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/link_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/url_launcher_stub.dart';

void main() {
  late List<(String, Object?)> opened;
  late List<String> scrolled;
  late Object? thrown;

  setUp(() {
    opened = [];
    scrolled = [];
    thrown = null;
  });

  GoRouter routerFor(LinkTarget target) {
    Widget recording(GoRouterState state) {
      opened.add((state.uri.path, state.extra));
      return const Text('module');
    }

    return GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/sheets', builder: (_, _) => const Text('catalog')),
        GoRoute(
          path: '/start',
          builder: (context, _) => TextButton(
            onPressed: () {
              try {
                followLink(context, target, scrollTo: scrolled.add);
              } catch (error) {
                thrown = error;
              }
            },
            child: const Text('follow'),
          ),
        ),
        GoRoute(path: '/courses/:level/:module', builder: (_, state) => recording(state)),
        GoRoute(path: '/everyone/courses/:level/:module', builder: (_, state) => recording(state)),
      ],
    );
  }

  Future<GoRouter> follow(WidgetTester tester, LinkTarget target) async {
    final router = routerFor(target);
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('follow'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a module target pushes the module in its track with the fragment as extra', (tester) async {
    final router = await follow(
      tester,
      const ModuleTarget(key: 'alpha/second', track: Track.everyone, lang: 'tr', fragment: 'part-two'),
    );

    expect(opened, const [('/everyone/courses/alpha/second', 'part-two')]);
    expect(router.canPop(), isTrue);
  });

  testWidgets('a module target in the For Engineers track without a fragment pushes null as extra', (tester) async {
    final router = await follow(
      tester,
      const ModuleTarget(key: 'alpha/second', track: Track.engineers, lang: 'en', fragment: null),
    );

    expect(opened, const [('/courses/alpha/second', null)]);
    expect(router.canPop(), isTrue);
  });

  testWidgets('an anchor target scrolls within the page', (tester) async {
    final router = await follow(tester, const AnchorTarget(id: 'part-two'));

    expect(scrolled, ['part-two']);
    expect(opened, isEmpty);
    expect(router.state.uri.path, '/start');
  });

  testWidgets('a catalog target goes to the For Engineers catalog root', (tester) async {
    final router = await follow(tester, const CatalogTarget());

    expect(router.state.uri.path, '/sheets');
    expect(find.text('catalog'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('an external target opens the url outside the app', (tester) async {
    final calls = stubOpeningUrlLauncher(canLaunch: true);
    final router = await follow(tester, const ExternalTarget(url: 'https://example.com/x'));

    expect(calls.launchedUrls, ['https://example.com/x']);
    expect(router.state.uri.path, '/start');
  });

  testWidgets('an unknown target throws', (tester) async {
    await follow(tester, const UnknownTarget(kind: 'poll'));

    expect(thrown, isA<StateError>());
    expect(opened, isEmpty);
    expect(scrolled, isEmpty);
  });
}
