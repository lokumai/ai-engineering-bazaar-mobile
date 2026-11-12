@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/text_find.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

/// The words of a paragraph drawn with a ground: the marks, in order, and which is the current one.
List<(String, bool)> _marks(WidgetTester tester, String paragraph) {
  final text = tester.widget<RichText>(
    find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText() == paragraph),
  );
  final marks = <(String, bool)>[];
  text.text.visitChildren((span) {
    if (span is TextSpan && span.style?.background != null) {
      marks.add((span.text!, span.style!.background!.color.toARGB32() == BazaarFixedColors.caution.toARGB32()));
    }
    return true;
  });
  return marks;
}

const _first = 'Agents call tools. An agent plans.';
const _second = 'Nothing here.';
const _third = 'The agents loop.';

Widget _page(TextFinder? finder) {
  Widget paragraph(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 400),
    child: InlineText(
      inlines: [TextInline(text: text)],
      style: const TextStyle(fontSize: 16),
      onLink: (_) {},
    ),
  );
  final column = SingleChildScrollView(
    child: Column(children: [paragraph(_first), paragraph(_second), paragraph(_third)]),
  );
  return SizedBox(
    height: 600,
    child: finder == null ? column : TextFindScope(finder: finder, child: column),
  );
}

void main() {
  testWidgets('without a finder nothing is marked', (tester) async {
    await pumpInTheme(tester, _page(null), Brightness.light);

    expect(_marks(tester, _first), isEmpty);
  });

  testWidgets('marks every word that answers the search, counts them and steps from one to the next', (tester) async {
    final finder = TextFinder(query: 'agent', lang: 'en');
    addTearDown(finder.dispose);
    await pumpInTheme(tester, _page(finder), Brightness.light);
    await tester.pump();

    expect(finder.total, 3);
    expect(finder.position, 0);
    expect(_marks(tester, _first), [('Agents', false), ('agent', false)]);
    expect(_marks(tester, _second), isEmpty);

    finder.startAt(double.negativeInfinity);
    await tester.pumpAndSettle();
    expect(finder.position, 1);
    expect(_marks(tester, _first), [('Agents', true), ('agent', false)]);

    finder.next();
    await tester.pumpAndSettle();
    expect(finder.position, 2);
    expect(_marks(tester, _first), [('Agents', false), ('agent', true)]);

    finder.next();
    await tester.pumpAndSettle();
    expect(finder.position, 3);
    expect(_marks(tester, _third), [('agents', true)]);
    expect(tester.getTopLeft(find.text(_third)).dy, lessThan(600), reason: 'the step scrolls the mark into view');

    finder.next();
    await tester.pumpAndSettle();
    expect(finder.position, 1, reason: 'after the last mark, the first');

    finder.previous();
    await tester.pumpAndSettle();
    expect(finder.position, 3, reason: 'before the first mark, the last');
  });

  testWidgets('starts at the first mark at or below a place on the page', (tester) async {
    final finder = TextFinder(query: 'agents', lang: 'en');
    addTearDown(finder.dispose);
    await pumpInTheme(tester, _page(finder), Brightness.light);
    await tester.pump();

    finder.startAt(tester.getTopLeft(find.text(_third)).dy);
    await tester.pump();

    expect(_marks(tester, _third), [('agents', true)]);
  });

  testWidgets('a step tells onStep, so the reader lets go of the heading it opened at', (tester) async {
    var steps = 0;
    final finder = TextFinder(query: 'agent', lang: 'en')..onStep = () => steps++;
    addTearDown(finder.dispose);
    await pumpInTheme(tester, _page(finder), Brightness.light);
    await tester.pump();

    finder.next();
    await tester.pumpAndSettle();

    expect(steps, 1);
  });

  testWidgets('words that answer nothing mark nothing, and the steps do nothing', (tester) async {
    final finder = TextFinder(query: 'zebra', lang: 'en');
    addTearDown(finder.dispose);
    await pumpInTheme(tester, _page(finder), Brightness.light);
    await tester.pump();

    finder.next();
    await tester.pump();

    expect(finder.total, 0);
    expect(finder.position, 0);
    expect(_marks(tester, _first), isEmpty);
  });
}
