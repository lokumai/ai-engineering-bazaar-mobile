@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

/// The glossary's terms in a module's text (plan 13.9).

HeadingBlock _h(String id, String text) => HeadingBlock(
  depth: 2,
  id: id,
  mark: null,
  inlines: [TextInline(text: text)],
);

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

ListItem _term(String name, String definition) => ListItem(
  checked: null,
  taskIndex: null,
  blocks: [
    ParagraphBlock(
      inlines: [
        StrongInline(inlines: [TextInline(text: name)]),
        TextInline(text: ': $definition'),
      ],
      lead: false,
    ),
  ],
);

final _doc = testDoc(
  body: [
    _h('lamps', 'Lamps'),
    _p('The wick draws oil, and the wick burns.'),
    _h('words', 'Words'),
    ListBlock(ordered: false, start: null, items: [_term('Wick', 'what burns.'), _term('Glass', 'keeps wind out.')]),
    _h('refs', 'Sources'),
    _p('A book on the wick.'),
  ],
);

/// The dotted spans of the paragraph that reads [text].
List<TextSpan> _dotted(WidgetTester tester, String text) {
  final paragraph = tester.widget<RichText>(
    find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text),
  );
  final spans = <TextSpan>[];
  paragraph.text.visitChildren((span) {
    if (span is TextSpan && span.style?.decorationStyle == TextDecorationStyle.dotted) spans.add(span);
    return true;
  });
  return spans;
}

void main() {
  testWidgets('a term is dotted where it first appears in a section; a tap shows its definition, and closes', (
    tester,
  ) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _doc);
    final review = ReviewBloc(store: MemoryReviewStore())..add(const ReviewStarted());
    addTearDown(review.close);
    final router = AppRouterFactory(initialLocation: '/courses/alpha/first').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, repository: repository, review: review));
    await tester.pumpAndSettle();

    expect([for (final span in _dotted(tester, 'The wick draws oil, and the wick burns.')) span.text], ['wick']);
    expect(_dotted(tester, 'Wick: what burns.'), isEmpty, reason: 'not in the Key Terms themselves');
    expect(_dotted(tester, 'A book on the wick.'), isEmpty, reason: 'not in the References');

    await tester.tapOnText(find.textRange.ofSubstring('wick').first);
    await tester.pumpAndSettle();
    final bubble = find.byKey(const ValueKey('term-bubble'));
    expect(bubble, findsOneWidget);
    expect(find.descendant(of: bubble, matching: find.text('what burns.', findRichText: true)), findsOneWidget);
    expect(review.state.history.cards.keys, ['term:engineers/alpha/first#0'], reason: 'looked up');

    await tester.tapAt(tester.getTopLeft(find.byKey(const ValueKey('term-barrier'))) + const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(bubble, findsNothing, reason: 'a tap anywhere else closes it');
  });

  testWidgets('the dotted terms and the bubble meet the platform guidelines', variant: bazaarPlatforms, (tester) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _doc);
    final router = AppRouterFactory(initialLocation: '/courses/alpha/first').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, repository: repository, platform: defaultTargetPlatform));
    await tester.pumpAndSettle();
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    await tester.tapOnText(find.textRange.ofSubstring('wick').first);
    await tester.pumpAndSettle();
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
