@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_search.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:flutter/foundation.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';
import '../../../../support/content_builders.dart';

/// The catalog's search (plan 7.1): every module document of the fixture reads as one module with an opening and a
/// section on retrieval.
MockContentRepository _repository({String Function()? opening}) {
  final repository = MockContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((invocation) async {
    final path = invocation.positionalArguments.single as String;
    final key = path.split('/').skip(3).take(2).join('/');
    return testDoc(
      key: key,
      title: 'Module $key',
      body: [
        ParagraphBlock(inlines: [TextInline(text: opening?.call() ?? 'An opening about agents.')], lead: false),
        const HeadingBlock(
          depth: 2,
          id: 'retrieval',
          mark: null,
          inlines: [TextInline(text: 'Retrieval')],
        ),
        ParagraphBlock(inlines: [TextInline(text: 'Finding the passages that answer.')], lead: false),
        HeadingBlock(
          depth: 2,
          id: 'memory',
          mark: null,
          inlines: [TextInline(text: 'Memory')],
        ),
        ParagraphBlock(inlines: [TextInline(text: 'Agents keep what they read.')], lead: false),
      ],
    );
  });
  when(() => repository.readObject(any())).thenAnswer((_) async => throw UnimplementedError());
  return repository;
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
}) async {
  final router = AppRouterFactory(initialLocation: '/sheets').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: _repository(), platform: platform, locale: locale));
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

  // The owner, on the phone (2026-11-17): the keyboard went away at the first letter, since what stood under the field
  // changed and the field was built again.
  testWidgets('the keyboard stays up while words are typed and the hits come', (tester) async {
    await _pump(tester);
    await tester.tap(find.byType(TextField));
    // The caret blinks while the field has focus, so the page never settles.
    await tester.pump(const Duration(milliseconds: 300));

    for (final typed in ['p', 'pa', 'passages']) {
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump(CatalogSearchField.settle);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.testTextInput.isVisible, isTrue, reason: 'after "$typed"');
    }
    expect(find.byType(CatalogSearchResults), findsOneWidget);
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

  // Review 8, finding 12: a Persian reader's search falls back to a module's English document, and its hits were laid out
  // right to left, the full stop at the left and the ellipsis on the wrong side.
  testWidgets('in Persian, a hit in an English document is laid out left to right', (tester) async {
    await _pump(tester, locale: const Locale('fa'));
    expect(Directionality.of(tester.element(find.byType(TextField))), TextDirection.rtl);

    await _type(tester, 'passages');

    final excerpt = find.descendant(
      of: find.byType(CatalogSearchResults),
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'Finding the passages that answer.',
      ),
    );
    expect(excerpt, findsWidgets);
    expect(Directionality.of(tester.element(excerpt.first)), TextDirection.ltr);
    final heading = find.descendant(of: find.byType(CatalogSearchResults), matching: find.text('Retrieval'));
    expect(Directionality.of(tester.element(heading.first)), TextDirection.ltr);
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

  testWidgets('another tab and back finds the search as it was left', (tester) async {
    final router = await _pump(tester);
    await _type(tester, 'passages');

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Home')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Catalog')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/sheets');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'passages');
    expect(find.text('6 results'), findsOneWidget);
  });

  testWidgets('a level is found by its name, with its module count, and opens its page', (tester) async {
    final router = await _pump(tester);
    await _type(tester, 'gamma');

    expect(find.text('Gamma Level'), findsOneWidget);
    expect(find.text('1 module'), findsOneWidget);
    await tester.tap(find.text('Gamma Level'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/sheets/gamma');
  });

  testWidgets('a tap elsewhere or a drag through the hits puts the keyboard away, as iOS has no back key', (
    tester,
  ) async {
    await _pump(tester, platform: TargetPlatform.iOS);

    await tester.showKeyboard(find.byType(TextField));
    await _type(tester, 'agent');
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.byType(SectionRule));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse, reason: 'a tap outside the field');

    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.isVisible, isTrue);
    // From the top of the hits, which is on screen.
    await tester.dragFrom(
      tester.getTopLeft(find.byType(CatalogSearchResults)) + const Offset(40, 40),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse, reason: 'a drag through the hits');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'agent', reason: 'the words stay');
  });

  // The content downloaded while the app was open was not searched until the app started again.
  testWidgets('content updated while the app is open is searched in its new text', (tester) async {
    var opening = 'An opening about agents.';
    final content = MockContentBloc();
    final states = StreamController<ContentState>();
    addTearDown(states.close);
    ContentReady ready(String version) => ContentReady(
      index: catalogFixtureIndex(contentVersion: version),
      origin: ContentOrigin.bundled,
      notice: null,
      refresh: const RefreshIdle(),
    );
    whenListen(content, states.stream, initialState: ready('a' * 64));
    final router = AppRouterFactory(initialLocation: '/sheets').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(
        router: router,
        content: content,
        repository: _repository(opening: () => opening),
      ),
    );
    await tester.pumpAndSettle();
    await _type(tester, 'zebra');
    expect(find.text('Nothing found for “zebra”.'), findsOneWidget);

    opening = 'An opening about a zebra.';
    states.add(ready('b' * 64));
    await tester.pumpAndSettle();
    await tester.pump(CatalogSearchField.settle);
    await tester.pumpAndSettle();
    expect(find.text('Nothing found for “zebra”.'), findsNothing);
    expect(find.byType(CatalogSearchResults), findsOneWidget);
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

  // Review 6, finding 9: the count was drawn in the level's hue, under the 4.5:1 text contrast on the card.
  testWidgets("a folded module's count of hits is muted text, not the level's hue", (tester) async {
    await _pump(tester);
    await _type(tester, 'agents');

    final count = find.text('2 matches').first;
    expect(tester.widget<Text>(count).style?.color, tester.element(count).bazaarColors.onSurfaceMuted);
  });

  // Plan 10.1 (the owner's testers, 2026-11-16): a module with many hits filled the screen.
  testWidgets('a module with more than one hit is folded to its best, and a tap on its head unfolds it', (
    tester,
  ) async {
    final router = await _pump(tester);
    await _type(tester, 'agents');

    expect(find.text('2 matches'), findsNWidgets(6));
    expect(find.text('An opening about agents.'), findsNWidgets(6), reason: 'the best hit of each module');
    expect(find.text('Memory'), findsNothing);
    expect(find.text('Open the module'), findsNothing);
    final head = find.ancestor(of: find.textContaining('Module alpha/first'), matching: find.byType(InkWell)).first;
    expect(tester.getSemantics(head), isSemantics(isExpanded: false, hasExpandedState: true));

    await tester.tap(find.textContaining('Module alpha/first'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/sheets', reason: 'the head of a folded card unfolds it');
    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Open the module'), findsOneWidget);
    expect(tester.getSemantics(head), isSemantics(isExpanded: true, hasExpandedState: true));

    await tester.tap(find.text('Memory'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, startsWith('/courses/'));
    expect((router.state.extra! as ReaderTarget).fragment, 'memory');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Memory'), findsOneWidget, reason: 'it stays unfolded');
    await tester.tap(find.text('Open the module'));
    await tester.pumpAndSettle();
    final target = router.state.extra! as ReaderTarget;
    expect((target.fragment, target.query), (null, 'agents'));
  });

  testWidgets('a folded card unfolds on a tap on its best hit too, and folds again on its head', (tester) async {
    await _pump(tester);
    await _type(tester, 'agents');

    await tester.tap(find.text('An opening about agents.').first);
    await tester.pumpAndSettle();
    expect(find.text('Memory'), findsOneWidget);

    await tester.tap(find.textContaining('Module alpha/first'));
    await tester.pumpAndSettle();
    expect(find.text('Memory'), findsNothing);
  });

  testWidgets('a module with one hit is not folded', (tester) async {
    final router = await _pump(tester);
    await _type(tester, 'passages');

    expect(find.textContaining('match'), findsNothing);
    await tester.tap(find.textContaining('Module alpha/first'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, startsWith('/courses/'));
  });

  // Plan 10.2: the hits can be kept to some levels.
  testWidgets('the levels with hits can be chosen, each with how many, and All brings every level back', (
    tester,
  ) async {
    await _pump(tester);
    await _type(tester, 'passages');

    expect(find.text('Alpha Level · 3'), findsOneWidget);
    expect(find.text('Beta Level · 2'), findsOneWidget);
    expect(find.text('Gamma Level · 1'), findsOneWidget);

    await tester.tap(find.text('Beta Level · 2'));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
    expect(find.textContaining('Module beta/fourth'), findsOneWidget);
    expect(find.textContaining('Module alpha/first'), findsNothing);

    // The row of levels scrolls sideways on a narrow phone.
    await tester.ensureVisible(find.text('Gamma Level · 1'));
    await tester.tap(find.text('Gamma Level · 1'));
    await tester.pumpAndSettle();
    expect(find.text('3 results'), findsOneWidget, reason: 'more than one level');

    await tester.ensureVisible(find.text('All'));
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('6 results'), findsOneWidget);
  });
}
