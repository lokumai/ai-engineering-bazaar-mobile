@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/term_bubble.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/themed_app.dart';

void main() {
  // Review 11, content 9: the definition's links did nothing, and at a large text size a long one grew past the screen.
  testWidgets('a link in the definition opens, and a long one scrolls in the bubble at a large size', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <LinkTarget>[];
    final term = GlossaryTerm(
      moduleKey: 'alpha/first',
      index: 0,
      name: 'Token',
      forms: const ['token'],
      definition: [
        const LinkInline(
          target: ExternalTarget(url: 'https://example.test/'),
          inlines: [TextInline(text: 'More')],
        ),
        TextInline(text: ' word' * 400),
      ],
    );
    await tester.pumpWidget(
      themedApp(
        MediaQuery(
          data: const MediaQueryData(size: Size(368, 600), textScaler: TextScaler.linear(3)),
          child: TermBubble(term: term, at: const Offset(180, 500), onLink: opened.add),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('term-bubble'))).top, greaterThanOrEqualTo(0));
    expect(find.descendant(of: find.byType(TermBubble), matching: find.byType(SingleChildScrollView)), findsOneWidget);

    await tester.tapOnText(find.textRange.ofSubstring('More'));
    expect(opened, const [ExternalTarget(url: 'https://example.test/')]);
  });
}
