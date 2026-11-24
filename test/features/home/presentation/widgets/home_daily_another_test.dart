@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

void main() {
  // Review 11, features 7: Show another was the card's own state, and Home is built again after a tab switch, so the
  // day's first card came back.
  testWidgets("the card Show another brought stays after another tab and back", (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    HeadingBlock h(String id, String text) => HeadingBlock(
      depth: 2,
      id: id,
      mark: null,
      inlines: [TextInline(text: text)],
    );
    ParagraphBlock p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      final key = path.split('/').skip(3).take(2).join('/');
      return testDoc(
        key: key,
        title: key,
        body: [h('s1', 'Section one of $key'), p('First words.'), h('s2', 'Section two of $key'), p('More words.')],
      );
    });
    final router = const AppRouterFactory(initialLocation: '/').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, repository: repository));
    await tester.pumpAndSettle();
    String heading() =>
        find.textContaining('Section ').evaluate().map((e) => (e.widget as Text).data ?? '').join(' | ');
    final first = heading();
    await tester.tap(find.byKey(const ValueKey('home-daily-another')));
    await tester.pumpAndSettle();
    final another = heading();
    expect(another, isNot(first));

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.byTooltip('Catalog')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.byTooltip('Home')));
    await tester.pumpAndSettle();

    expect(heading(), another);
  });
}
