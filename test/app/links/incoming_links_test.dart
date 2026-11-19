@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/links/incoming_links.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _base = 'https://example.test/';

/// Links that waited, then ones that come.
final class _Links implements ILinkSource {
  _Links(this.waiting);

  final List<Uri> waiting;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<List<Uri>> takeWaiting() async => waiting;

  @override
  Stream<Uri> get links => controller.stream;
}

Future<GoRouter> _pump(WidgetTester tester, _Links links) async {
  Widget page(GoRouterState state) => Text('${state.uri.path} ${state.extra ?? ''}');
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, state) => page(state)),
      GoRoute(path: '/courses/:level/:module', builder: (_, state) => page(state)),
      GoRoute(path: '/everyone/sheets/:level', builder: (_, state) => page(state)),
      GoRoute(path: '/transfer', builder: (_, state) => page(state)),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(links.controller.close);
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ILinkSource>.value(value: links),
        RepositoryProvider<WebLinks>.value(value: const WebLinks(_base)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => IncomingLinks(router: router, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('opens the link the app was opened with, the language of the link read past (plan 17.2)', (tester) async {
    await _pump(tester, _Links([Uri.parse('${_base}tr/courses/alpha/first/')]));
    expect(find.text('/courses/alpha/first '), findsOneWidget);
  });

  testWidgets('opens a transfer over the page, its payload as the extra, and leaves other links alone', (tester) async {
    final links = _Links(const []);
    await _pump(tester, links);

    links.controller.add(Uri.parse('${_base}legend/'));
    links.controller.add(Uri.parse('https://elsewhere.test/courses/alpha/first/'));
    await tester.pumpAndSettle();
    expect(find.text('/ '), findsOneWidget);

    links.controller.add(Uri.parse('${_base}everyone/sheets/alpha/'));
    await tester.pumpAndSettle();
    expect(find.text('/everyone/sheets/alpha '), findsOneWidget);

    links.controller.add(Uri.parse('aibazaar://transfer#t=abc'));
    await tester.pumpAndSettle();
    expect(find.text('/transfer abc'), findsOneWidget);
  });
}
