@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/code_block_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

/// The code body's root span.
TextSpan bodySpan(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('code-body'))).textSpan! as TextSpan;

/// Every leaf span with its merged style.
List<(String, TextStyle)> flatten(InlineSpan span, [TextStyle inherited = const TextStyle()]) {
  if (span is! TextSpan) return const [];
  final style = inherited.merge(span.style);
  return [
    if (span.text != null) (span.text!, style),
    for (final child in span.children ?? const <InlineSpan>[]) ...flatten(child, style),
  ];
}

void main() {
  setUpAll(() => S.load(const Locale('en')));

  testWidgets('token roles colour the slab and only bold tokens are w600', (tester) async {
    await pumpBlocks(tester, const [
      CodeBlock(
        language: 'python',
        lines: [
          [CodeToken(text: 'def', role: 'keyword', bold: true), CodeToken(text: ' f', role: 'function', bold: false)],
          [],
          [CodeToken(text: '42', role: 'number', bold: false), CodeToken(text: 'x', role: 'magic', bold: false)],
        ],
      ),
    ]);

    final spans = {for (final (text, style) in flatten(bodySpan(tester))) text: style};
    expect(bodySpan(tester).toPlainText(), 'def f\n\n42x'); // an empty line stays a line
    expect(spans['def']!.color, BazaarSlab.forRole('keyword'));
    expect(spans['def']!.fontWeight, FontWeight.w600);
    expect(spans[' f']!.color, BazaarSlab.forRole('function'));
    expect(spans['42']!.color, BazaarSlab.forRole('number'));
    expect(spans['42']!.fontWeight, FontWeight.w400); // A17
    expect(spans['x']!.color, BazaarSlab.forRole(null));
    expect(spans['def']!.fontFamily, monoFamily(TargetPlatform.android));
    expect(spans['def']!.fontSize, BazaarType.code.size);
    expect(spans['def']!.height, BazaarType.code.height);
    expect(tester.widget<Text>(find.byKey(const Key('code-body'))).softWrap, isFalse);

    expect(tester.getSemantics(find.byKey(const Key('code-block'))), matchesSemantics(label: 'python code'));
    expect(
      find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal),
      findsOneWidget,
    );
  });

  testWidgets('the head shows the language in the muted slab ink', (tester) async {
    await pumpBlocks(tester, const [
      CodeBlock(
        language: 'bash',
        lines: [
          [CodeToken(text: 'ls', role: null, bold: false)],
        ],
      ),
    ]);

    final head = tester.widget<Text>(find.text('bash'));
    expect(head.style!.color, BazaarFixedColors.slabOnSurfaceMuted);
    expect(head.style!.fontSize, BazaarType.mark.size);
    final slab = tester.widget<Container>(find.byKey(const Key('code-slab'))).decoration! as BoxDecoration;
    expect(slab.color, BazaarFixedColors.slabSurface);
    expect((slab.border! as Border).top.color, BazaarFixedColors.slabLine);
    expect(find.byType(CodeBlockView), findsOneWidget);
  });

  testWidgets('the slab is the same in the dark theme', (tester) async {
    await pumpBlocks(tester, const [
      CodeBlock(
        language: 'bash',
        lines: [
          [CodeToken(text: 'ls', role: null, bold: false)],
        ],
      ),
    ], brightness: Brightness.dark);

    final slab = tester.widget<Container>(find.byKey(const Key('code-slab'))).decoration! as BoxDecoration;
    expect(slab.color, BazaarFixedColors.slabSurface);
  });

  testWidgets('output reads as program output', (tester) async {
    await pumpBlocks(tester, const [
      CodeBlock(
        language: 'output',
        lines: [
          [CodeToken(text: 'ok', role: null, bold: false)],
        ],
      ),
    ]);

    expect(tester.getSemantics(find.byKey(const Key('code-block'))), matchesSemantics(label: 'Program output'));
    expect(find.text('output'), findsOneWidget);
  });

  testWidgets('a long line scrolls sideways instead of wrapping', (tester) async {
    await pumpBlocks(tester, [
      CodeBlock(
        language: 'text',
        lines: [
          [CodeToken(text: 'x' * 200, role: null, bold: false)],
        ],
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('code-body'))).width, greaterThan(390));
  });
}
