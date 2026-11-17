@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_search.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

/// The search's topic chips (plan 13.10): every module of the fixture has Wick and Glass in its Key Terms.
ModuleDoc _doc() {
  HeadingBlock h(String id) => HeadingBlock(
    depth: 2,
    id: id,
    mark: null,
    inlines: [TextInline(text: id)],
  );
  ListItem term(String name) => ListItem(
    checked: null,
    taskIndex: null,
    blocks: [
      ParagraphBlock(
        inlines: [
          StrongInline(inlines: [TextInline(text: name)]),
          const TextInline(text: ': a part of a lamp.'),
        ],
        lead: false,
      ),
    ],
  );
  return testDoc(
    body: [
      h('lamps'),
      ParagraphBlock(inlines: [TextInline(text: 'Lamps and passages.')], lead: false),
      h('words'),
      ListBlock(ordered: false, start: null, items: [term('Wick'), term('Glass')]),
      h('refs'),
    ],
  );
}

Future<GoRouter> _pump(WidgetTester tester) async {
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _doc());
  final router = AppRouterFactory(initialLocation: '/sheets').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: repository));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('a few terms stand under the empty field; a chip opens the term in the glossary, not a search', (
    tester,
  ) async {
    final router = await _pump(tester);
    expect(find.text('Terms to look up'), findsOneWidget);
    final wick = find.byKey(const ValueKey('topic-term:engineers/alpha/first#0'));
    expect(wick, findsOneWidget);

    await tester.tap(wick);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/practice/glossary');
    expect(router.state.uri.queryParameters['term'], 'term:engineers/alpha/first#0');
    expect(find.text('a part of a lamp.', findRichText: true), findsOneWidget, reason: 'the term open');
  });

  // The owner, on the phone (2026-11-17): what stood under the field once closed the keyboard at the first letter.
  testWidgets('the keyboard stays up while the chips give way to the hits', (tester) async {
    await _pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    for (final typed in ['p', 'pa', 'passages']) {
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump(CatalogSearchField.settle);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.testTextInput.isVisible, isTrue, reason: 'after "$typed"');
    }
    expect(find.text('Terms to look up'), findsNothing);
  });
}
