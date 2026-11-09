@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/callout_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/content_builders.dart';

CalloutBlock callout(
  CalloutKind kind, {
  List<Inline>? title = const [TextInline(text: 'Stop here')],
  CalloutAction? action,
}) => CalloutBlock(
  kind: kind,
  title: title,
  blocks: const [
    ParagraphBlock(inlines: [TextInline(text: 'Body.')], lead: false),
  ],
  action: action,
);

BoxDecoration cardOf(WidgetTester tester) =>
    tester.widget<Container>(find.byKey(const Key('callout-card'))).decoration! as BoxDecoration;

TextStyle styleOf(WidgetTester tester, String text) =>
    tester.widget<InlineText>(find.ancestor(of: find.text(text), matching: find.byType(InlineText)).first).style;

void main() {
  setUpAll(() => S.load(const Locale('en')));

  testWidgets('a callout has no default title and no icon', (tester) async {
    await pumpBlocks(tester, [callout(CalloutKind.note, title: null)]);

    expect(find.byType(CalloutView), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.textContaining('Note'), findsNothing);
    expect(find.text('Body.'), findsOneWidget);
  });

  testWidgets('callout edges by kind', (tester) async {
    final colors = BazaarColors.light;
    final expected = {
      CalloutKind.important: (colors.primary, colors.surfaceRaised),
      CalloutKind.note: (colors.lineStrong, colors.surfaceRaised),
      CalloutKind.tip: (BazaarFixedColors.success, colors.surfaceRaised),
      CalloutKind.caution: (colors.fault, colors.surfaceRaised),
      CalloutKind.warning: (BazaarFixedColors.onCaution, BazaarFixedColors.caution),
    };
    for (final MapEntry(key: kind, value: (edge, fill)) in expected.entries) {
      await pumpBlocks(tester, [callout(kind)]);
      final decoration = cardOf(tester);
      final border = decoration.border! as Border;
      expect(border.top.color, edge, reason: kind.name);
      expect(border.top.width, 2, reason: kind.name);
      expect(decoration.color, fill, reason: kind.name);
      expect(decoration.borderRadius, BazaarShapes.leaf, reason: kind.name);
    }
  });

  testWidgets('a callout title is bold subsection type in the title ink, centred', (tester) async {
    await pumpBlocks(tester, [callout(CalloutKind.important)]);

    final style = styleOf(tester, 'Stop here');
    expect(style.fontSize, BazaarType.subsection.size);
    expect(style.fontWeight, FontWeight.w700);
    expect(style.color, BazaarColors.light.onSurfaceTitle);
    final title = tester.widget<InlineText>(
      find.ancestor(of: find.text('Stop here'), matching: find.byType(InlineText)),
    );
    expect(title.textAlign, TextAlign.center);
    final body = tester.widget<InlineText>(find.ancestor(of: find.text('Body.'), matching: find.byType(InlineText)));
    expect(body.textAlign, TextAlign.center);
    expect(tester.getTopLeft(find.text('Body.')).dy, greaterThan(tester.getBottomLeft(find.text('Stop here')).dy));
  });

  testWidgets('a warning title and body are drawn in onCaution', (tester) async {
    await pumpBlocks(tester, [callout(CalloutKind.warning)], brightness: Brightness.dark);

    final title = styleOf(tester, 'Stop here');
    expect(title.fontSize, BazaarType.section.size);
    expect(title.color, BazaarFixedColors.onCaution);
    expect(styleOf(tester, 'Body.').color, BazaarFixedColors.onCaution);
  });

  testWidgets('a quote inside a warning takes its own ink and keeps the callout alignment', (tester) async {
    await pumpBlocks(
      tester,
      const [
        CalloutBlock(
          kind: CalloutKind.warning,
          title: [TextInline(text: 'Stop here')],
          blocks: [
            ParagraphBlock(inlines: [TextInline(text: 'Body.')], lead: false),
            QuoteBlock(
              label: 'NOTE',
              blocks: [
                ParagraphBlock(inlines: [TextInline(text: 'Quoted.')], lead: false),
              ],
            ),
          ],
          action: null,
        ),
      ],
      brightness: Brightness.dark,
      platform: defaultTargetPlatform,
    );

    expect(styleOf(tester, 'Body.').color, BazaarFixedColors.onCaution);
    expect(styleOf(tester, 'Quoted.').color, BazaarColors.dark.onSurface);
    final quoted = tester.widget<InlineText>(
      find.ancestor(of: find.text('Quoted.'), matching: find.byType(InlineText)),
    );
    expect(quoted.textAlign, TextAlign.center);
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('a callout is a container named by its title', (tester) async {
    await pumpBlocks(tester, [
      callout(
        CalloutKind.important,
        title: const [
          StrongInline(inlines: [TextInline(text: 'Stop')]),
          TextInline(text: ' here'),
        ],
      ),
    ]);

    expect(find.bySemanticsLabel('Stop here'), findsWidgets);
    final node = tester.getSemantics(find.byKey(const Key('callout')));
    expect(node.label, 'Stop here');
  });

  testWidgets('a callout action is a filled button with the external mark', (tester) async {
    final harness = await pumpBlocks(tester, [
      callout(
        CalloutKind.important,
        action: const CalloutAction(
          target: ExternalTarget(url: 'https://example.com/'),
          inlines: [TextInline(text: 'Read more')],
        ),
      ),
    ]);

    final button = find.byType(FilledButton);
    expect(find.descendant(of: button, matching: find.text('Read more')), findsOneWidget);
    expect(find.descendant(of: button, matching: find.text('\u2060↗')), findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(minTapTarget(TargetPlatform.android)));
    expect(tester.getTopLeft(button).dy - tester.getBottomLeft(find.text('Body.')).dy, greaterThanOrEqualTo(22));

    await tester.tap(button);
    expect(harness.links, const [ExternalTarget(url: 'https://example.com/')]);
  });

  testWidgets('an action to an anchor has no external mark', (tester) async {
    await pumpBlocks(tester, [
      callout(
        CalloutKind.tip,
        action: const CalloutAction(
          target: AnchorTarget(id: 'two'),
          inlines: [TextInline(text: 'Jump')],
        ),
      ),
    ]);

    expect(find.text('Jump'), findsOneWidget);
    expect(find.text('\u2060↗'), findsNothing);
  });

  testWidgets('a callout sits inside a block list with its margins', (tester) async {
    await pumpBlocks(tester, [
      const ParagraphBlock(inlines: [TextInline(text: 'Before.')], lead: false),
      callout(CalloutKind.note),
    ]);

    expect(find.byType(BlockList), findsWidgets);
    // The paragraph keeps 17 below it and the callout 36 above it; adjacent margins collapse to the larger, as on the web.
    expect(
      tester.getTopLeft(find.byKey(const Key('callout-card'))).dy - tester.getBottomLeft(find.text('Before.')).dy,
      36,
    );
  });
}
