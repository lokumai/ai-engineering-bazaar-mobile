@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_search.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

/// The catalog's search (plan 7.1): every module document of the fixture reads as one module with an opening and a
/// section on retrieval.
MockContentRepository _repository() {
  final repository = MockContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((invocation) async {
    final path = invocation.positionalArguments.single as String;
    final key = path.split('/').skip(3).take(2).join('/');
    return testDoc(
      key: key,
      title: 'Module $key',
      body: const [
        ParagraphBlock(inlines: [TextInline(text: 'An opening about agents.')], lead: false),
        HeadingBlock(
          depth: 2,
          id: 'retrieval',
          mark: null,
          inlines: [TextInline(text: 'Retrieval')],
        ),
        ParagraphBlock(inlines: [TextInline(text: 'Finding the passages that answer.')], lead: false),
      ],
    );
  });
  when(() => repository.readObject(any())).thenAnswer((_) async => throw UnimplementedError());
  return repository;
}

Future<GoRouter> _pump(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android}) async {
  final router = AppRouterFactory(initialLocation: '/sheets').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: _repository(), platform: platform));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(CatalogSearchField.settle);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the field heads the catalog, and the levels show until words are typed', (tester) async {
    await _pump(tester);

    expect(find.widgetWithText(TextField, 'Search the modules'), findsOneWidget);
    expect(find.byType(CatalogOverview), findsOneWidget);
    expect(find.byType(CatalogSearchResults), findsNothing);
  });

  testWidgets('typed words show the hits in place of the levels, the matched word in bold', (tester) async {
    await _pump(tester);

    await _type(tester, 'passages');

    expect(find.byType(CatalogOverview), findsNothing);
    expect(find.text('6 results'), findsOneWidget);
    expect(find.text('Retrieval'), findsNWidgets(6));
    final excerpt = tester
        .widgetList<RichText>(find.descendant(of: find.byType(CatalogSearchResults), matching: find.byType(RichText)))
        .firstWhere((text) => text.text.toPlainText() == 'Finding the passages that answer.');
    final bold = <String>[];
    excerpt.text.visitChildren((span) {
      if (span is TextSpan && span.style?.fontWeight == FontWeight.w700) bold.add(span.text!);
      return true;
    });
    expect(bold, ['passages']);
  });

  testWidgets('a hit opens its module at its section, and back finds the search again', (tester) async {
    final router = await _pump(tester);
    await _type(tester, 'passages');

    await tester.tap(find.text('Retrieval').first);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, startsWith('/courses/'));
    final target = router.state.extra! as ReaderTarget;
    expect((target.fragment, target.query), ('retrieval', 'passages'));

    // The bar's back finds the search as it was left (the owner, 2026-11-11).
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/sheets');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'passages');
    expect(find.text('6 results'), findsOneWidget);
  });

  testWidgets('words that match nothing say so, and the clear button brings the levels back', (tester) async {
    await _pump(tester);

    await _type(tester, 'zebra');
    expect(find.text('Nothing found for “zebra”.'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear the search'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogOverview), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('meets the platform guidelines while searching', variant: bazaarPlatforms, (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);
    await _type(tester, 'passages');

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
