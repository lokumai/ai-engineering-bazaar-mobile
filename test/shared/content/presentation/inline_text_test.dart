@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/logo_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';
import '../../../support/contrast.dart';

const _style = TextStyle(fontSize: 16);

Future<void> pump(WidgetTester tester, List<Inline> inlines, {LinkHandler? onLink}) async {
  await pumpInTheme(tester, InlineText(inlines: inlines, style: _style, onLink: onLink ?? (_) {}), Brightness.light);
}

/// The span [InlineText] builds, before `Text.rich` wraps it in the default text style.
TextSpan rootSpan(WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: find.byType(InlineText), matching: find.byType(Text)).first).textSpan!
        as TextSpan;

/// Every leaf [TextSpan] with text, in order.
List<TextSpan> leafSpans(InlineSpan span) => [
  if (span is TextSpan) ...[
    if (span.text != null) span,
    for (final child in span.children ?? const <InlineSpan>[]) ...leafSpans(child),
  ],
];

/// Every leaf [TextSpan] with text and the style it is drawn in, its ancestors' styles merged under its own.
List<(String, TextStyle)> flatten(InlineSpan span, [TextStyle inherited = const TextStyle()]) {
  if (span is! TextSpan) return const [];
  final style = inherited.merge(span.style);
  return [
    if (span.text != null) (span.text!, style),
    for (final child in span.children ?? const <InlineSpan>[]) ...flatten(child, style),
  ];
}

List<GestureRecognizer> recognizers(InlineSpan span) => [
  if (span is TextSpan) ...[
    ?span.recognizer,
    for (final child in span.children ?? const <InlineSpan>[]) ...recognizers(child),
  ],
];

void main() {
  testWidgets('text, strong, emphasis, delete, code and break map to spans', (tester) async {
    await pump(tester, const [
      TextInline(text: 'a'),
      StrongInline(inlines: [TextInline(text: 'b')]),
      EmphasisInline(inlines: [TextInline(text: 'c')]),
      DeleteInline(inlines: [TextInline(text: 'd')]),
      BreakInline(),
      CodeInline(text: 'e'),
    ]);

    final spans = flatten(rootSpan(tester));
    expect(spans.map((s) => s.$1).join(), 'abcd\ne');
    expect(spans[1].$2.fontWeight, FontWeight.w600); // A17: bold is w600
    expect(spans[2].$2.fontStyle, FontStyle.italic);
    expect(spans[3].$2.decoration, TextDecoration.lineThrough);
    expect(spans[5].$2.fontFamily, monoFamily(TargetPlatform.android));
    expect(spans[5].$2.fontSize, BazaarType.meta.size);
    // A Paint keeps its colour as 32-bit ARGB, so the comparison is on that value.
    expect(
      spans[5].$2.background!.color.toARGB32(),
      tester.element(find.byType(InlineText)).bazaarColors.surfaceSunken.toARGB32(),
    );
  });

  testWidgets('an external link gets a word-joined arrow hidden from semantics', (tester) async {
    await pump(tester, const [
      LinkInline(
        target: ExternalTarget(url: 'https://example.com/'),
        inlines: [TextInline(text: 'site')],
      ),
    ]);

    final arrow = leafSpans(rootSpan(tester)).last;
    expect(arrow.text, '\u2060↗');
    expect(arrow.semanticsLabel, '');
    expect(arrow.style!.color, tester.element(find.byType(InlineText)).bazaarColors.onSurfaceFaint);
    expect(arrow.style!.fontSize, BazaarType.mark.size);
  });

  testWidgets('a link to another kind of target has no arrow', (tester) async {
    await pump(tester, const [
      LinkInline(
        target: AnchorTarget(id: 'part-two'),
        inlines: [TextInline(text: 'below')],
      ),
    ]);

    expect(leafSpans(rootSpan(tester)).map((s) => s.text).join(), 'below');
  });

  testWidgets('tapping a link calls onLink with its target', (tester) async {
    final recorded = <LinkTarget>[];
    await pump(tester, const [
      TextInline(text: 'Read the '),
      LinkInline(
        target: ModuleTarget(key: 'alpha/second', track: Track.engineers, lang: 'en', fragment: null),
        inlines: [
          TextInline(text: 'next '),
          StrongInline(inlines: [TextInline(text: 'part')]),
        ],
      ),
      TextInline(text: ' now.'),
    ], onLink: recorded.add);

    await tester.tapOnText(find.textRange.ofSubstring('next part'));
    expect(recorded, const [ModuleTarget(key: 'alpha/second', track: Track.engineers, lang: 'en', fragment: null)]);

    recorded.clear();
    await tester.tapOnText(find.textRange.ofSubstring('Read'));
    expect(recorded, isEmpty);
  });

  testWidgets('a link has weight 500 and an ornament underline', (tester) async {
    await pump(tester, const [
      LinkInline(
        target: CatalogTarget(),
        inlines: [TextInline(text: 'catalog')],
      ),
    ]);

    final (text, style) = flatten(rootSpan(tester)).single;
    expect(text, 'catalog');
    expect(style.fontWeight, FontWeight.w500);
    expect(style.decoration, TextDecoration.underline);
    expect(style.decorationColor, BazaarFixedColors.ornament);
    expect(style.decorationThickness, 1);
  });

  testWidgets('an unknown target renders its inlines as plain text', (tester) async {
    final recorded = <LinkTarget>[];
    await pump(tester, const [
      LinkInline(
        target: UnknownTarget(kind: 'poll'),
        inlines: [TextInline(text: 'plain')],
      ),
    ], onLink: recorded.add);

    expect(recognizers(rootSpan(tester)), isEmpty);
    final (text, style) = flatten(rootSpan(tester)).single;
    expect(text, 'plain');
    expect(style.decoration, isNull);
    expect(style.fontWeight, isNull);

    await tester.tapOnText(find.textRange.ofSubstring('plain'));
    expect(recorded, isEmpty);
  });

  testWidgets('an unknown inline renders its inlines, or nothing', (tester) async {
    await pump(tester, const [
      UnknownInline(
        type: 'x',
        inlines: [TextInline(text: 'kept')],
      ),
    ]);
    expect(rootSpan(tester).toPlainText(), 'kept');

    await pump(tester, const [UnknownInline(type: 'x', inlines: [])]);
    expect(rootSpan(tester).toPlainText(), '');
  });

  testWidgets('a logo is a widget span held to the next word by a word joiner', (tester) async {
    await pump(tester, const [
      LogoInline(src: 'course-images/alpha/logos/x.svg', alt: '', mono: false),
      TextInline(text: 'Name rest'),
    ]);

    final children = rootSpan(tester).children!;
    expect(children[0], isA<WidgetSpan>());
    expect((children[1] as TextSpan).text, '\u2060');
    expect(tester.widget<LogoView>(find.byType(LogoView)).fontSize, 16); // the style's font size in the harness
    expect(tester.widget<LogoView>(find.byType(LogoView)).src, 'course-images/alpha/logos/x.svg');
  });

  testWidgets('a link holding a logo and its name is one link node named by the name', (tester) async {
    final handle = tester.ensureSemantics();
    final recorded = <LinkTarget>[];
    await pump(tester, const [
      TextInline(text: 'Run it with '),
      LinkInline(
        target: ExternalTarget(url: 'https://ollama.com/'),
        inlines: [
          LogoInline(src: 'course-images/alpha/logos/x.svg', alt: '', mono: false),
          TextInline(text: 'Ollama'),
        ],
      ),
      TextInline(text: ' on a laptop.'),
    ], onLink: recorded.add);

    final links = <SemanticsNode>[];
    void collect(SemanticsNode node) {
      if (node.flagsCollection.isLink) links.add(node);
      node.visitChildren((child) {
        collect(child);
        return true;
      });
    }

    collect(tester.getSemantics(find.byType(InlineText)));
    expect(links.map((node) => node.label), ['Ollama']);

    links.single.owner!.performAction(links.single.id, SemanticsAction.tap);
    expect(recorded, const [ExternalTarget(url: 'https://ollama.com/')]);
    handle.dispose();
  });

  testWidgets('a rebuild replaces the recognizers and keeps links working', (tester) async {
    final recorded = <LinkTarget>[];
    const inlines = [
      LinkInline(
        target: AnchorTarget(id: 'a'),
        inlines: [TextInline(text: 'jump')],
      ),
    ];
    await pump(tester, inlines, onLink: recorded.add);
    final first = recognizers(rootSpan(tester)).single;

    await pump(tester, inlines, onLink: recorded.add);
    final second = recognizers(rootSpan(tester)).single;
    expect(identical(first, second), isFalse);

    await tester.tapOnText(find.textRange.ofSubstring('jump'));
    expect(recorded, const [AnchorTarget(id: 'a')]);
  });

  test('inlinePlainText', () {
    expect(
      inlinePlainText(const [
        TextInline(text: 'a'),
        BreakInline(),
        CodeInline(text: 'b'),
        LogoInline(src: 's', alt: '', mono: false),
      ]),
      'a b',
    );
    expect(
      inlinePlainText(const [
        StrongInline(inlines: [TextInline(text: 'c')]),
        EmphasisInline(inlines: [TextInline(text: 'd')]),
        DeleteInline(inlines: [TextInline(text: 'e')]),
        LinkInline(
          target: CatalogTarget(),
          inlines: [TextInline(text: 'f')],
        ),
        UnknownInline(
          type: 'x',
          inlines: [TextInline(text: 'g')],
        ),
      ]),
      'cdefg',
    );
  });

  test('inline code reads at 4.5 or more on surfaceSunken in both themes', () {
    // The web paints this pair but its contrast test does not check it (spec 3.8: a Dart test in the commit that adds
    // the pair); the same pair carries the table head (Task 10.3) and the quiz verdict (Task 11.2).
    for (final c in [BazaarColors.light, BazaarColors.dark]) {
      expect(contrastRatio(c.onSurface, c.surfaceSunken), greaterThanOrEqualTo(4.5));
    }
  });
}
