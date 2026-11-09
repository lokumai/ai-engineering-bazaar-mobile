@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/table_block_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

Cell cell(String text) => Cell(inlines: [TextInline(text: text)]);

final table = TableBlock(
  number: '4',
  title: 'Results',
  rowHeaders: true,
  align: const [null, null, CellAlign.right],
  head: [cell('Name'), cell('Kind'), cell('Count')],
  rows: [
    [cell('alpha'), cell('one'), cell('12')],
    [cell('beta'), cell('two'), cell('7')],
  ],
);

InlineText inlineOf(WidgetTester tester, String text) =>
    tester.widget<InlineText>(find.ancestor(of: find.text(text), matching: find.byType(InlineText)).first);

void main() {
  setUpAll(() => S.load(const Locale('en')));

  testWidgets('the table caption sits above the cells inside the frame', (tester) async {
    await pumpBlocks(tester, [table]);

    final caption = find.text('TBL. 4 · Results');
    expect(caption, findsOneWidget);
    expect(tester.getTopLeft(caption).dy, lessThan(tester.getTopLeft(find.text('Name')).dy));
    expect(find.descendant(of: find.byKey(const Key('table-frame')), matching: caption), findsOneWidget);
    final captionStyle = tester.widget<Text>(caption).style!;
    expect(captionStyle.fontWeight, FontWeight.w600);
    expect(captionStyle.fontSize, BazaarType.meta.size);
    expect(captionStyle.color, BazaarColors.light.onSurface);

    expect(tester.getSemantics(find.byKey(const Key('table-region'))).label, 'Table 4');
    expect(find.byType(TableBlockView), findsOneWidget);
  });

  testWidgets('row headers and head cells are w600, other cells w400', (tester) async {
    await pumpBlocks(tester, [table]);

    for (final head in ['Name', 'Kind', 'Count']) {
      final style = inlineOf(tester, head).style;
      expect(style.fontWeight, FontWeight.w600, reason: head);
      expect(style.fontSize, BazaarType.mark.size, reason: head);
      expect(style.color, BazaarColors.light.onSurface, reason: head);
    }
    expect(inlineOf(tester, 'alpha').style.fontWeight, FontWeight.w600);
    expect(inlineOf(tester, 'beta').style.fontWeight, FontWeight.w600);
    expect(inlineOf(tester, 'one').style.fontWeight, FontWeight.w400);
    expect(inlineOf(tester, '12').style.fontWeight, FontWeight.w400);
    expect(inlineOf(tester, 'one').style.fontSize, BazaarType.control.size);

    final head = tester.widget<Table>(find.byType(Table)).children.first.decoration! as BoxDecoration;
    expect(head.color, BazaarColors.light.surfaceSunken);
  });

  testWidgets('without row headers every body cell is w400', (tester) async {
    await pumpBlocks(tester, [
      TableBlock(
        number: '5',
        title: null,
        rowHeaders: false,
        align: const [null, null],
        head: [cell('A'), cell('B')],
        rows: [
          [cell('a1'), cell('b1')],
        ],
      ),
    ]);

    expect(find.text('TBL. 5'), findsOneWidget);
    expect(inlineOf(tester, 'a1').style.fontWeight, FontWeight.w400);
  });

  testWidgets('every cell is left-aligned whatever align says, and the table scrolls sideways', (tester) async {
    await pumpBlocks(tester, [table]);

    for (final text in ['Name', 'Kind', 'Count', 'alpha', 'one', '12', 'beta', 'two', '7']) {
      expect(inlineOf(tester, text).textAlign, TextAlign.left, reason: text); // A39
    }
    expect(
      find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal),
      findsOneWidget,
    );
  });

  testWidgets('a long cell wraps at 280 and a wide table scrolls without overflow', (tester) async {
    final long = List.filled(40, 'word').join(' ');
    await pumpBlocks(tester, [
      TableBlock(
        number: '6',
        title: null,
        rowHeaders: false,
        align: const [null, null, null],
        head: [cell('A'), cell('B'), cell('C')],
        rows: [
          [cell(long), cell(long), cell(long)],
        ],
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text(long).first).width, lessThanOrEqualTo(280));
  });

  testWidgets('a narrow table fills the frame', (tester) async {
    await pumpBlocks(tester, [
      TableBlock(
        number: '7',
        title: null,
        rowHeaders: false,
        align: const [null],
        head: [cell('A')],
        rows: [
          [cell('a')],
        ],
      ),
    ]);

    // The frame's 1 px border on each side leaves 388.
    expect(tester.getSize(find.byType(Table)).width, 388);
  });
}
