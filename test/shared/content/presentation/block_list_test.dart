@Tags(['widget'])
library;

import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/checklist_scope.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/content_builders.dart';
import '../../../support/url_launcher_stub.dart';

/// The style of the [InlineText] that draws [text].
TextStyle styleOf(WidgetTester tester, String text) =>
    tester.widget<InlineText>(find.ancestor(of: find.text(text), matching: find.byType(InlineText)).first).style;

BazaarColors colorsOf(WidgetTester tester) => tester.element(find.byType(BlockList).first).bazaarColors;

ListItem item(String text, {bool? checked, int? taskIndex}) => ListItem(
  checked: checked,
  taskIndex: taskIndex,
  blocks: [
    ParagraphBlock(inlines: [TextInline(text: text)], lead: false),
  ],
);

void main() {
  setUpAll(() => S.load(const Locale('en')));

  testWidgets('a paragraph uses the body step in the on-surface ink', (tester) async {
    await pumpBlocks(tester, const [
      ParagraphBlock(inlines: [TextInline(text: 'Body.')], lead: false),
    ]);

    final style = styleOf(tester, 'Body.');
    expect(style.fontSize, BazaarType.body.size);
    expect(style.height, BazaarType.body.height);
    expect(style.color, colorsOf(tester).onSurface);
  });

  testWidgets('a lead paragraph uses the lead step in the muted ink', (tester) async {
    await pumpBlocks(tester, const [
      ParagraphBlock(inlines: [TextInline(text: 'Lead.')], lead: true),
    ]);

    final style = styleOf(tester, 'Lead.');
    expect(style.fontSize, BazaarType.lead.size);
    expect(style.color, colorsOf(tester).onSurfaceMuted);
  });

  testWidgets('a paragraph passes its links to the render context', (tester) async {
    final harness = await pumpBlocks(tester, const [
      ParagraphBlock(
        inlines: [
          LinkInline(
            target: AnchorTarget(id: 'two'),
            inlines: [TextInline(text: 'below')],
          ),
        ],
        lead: false,
      ),
    ]);

    await tester.tapOnText(find.textRange.ofSubstring('below'));
    expect(harness.links, const [AnchorTarget(id: 'two')]);
  });

  group('the References\' Modules subsection (web D135)', () {
    HeadingBlock heading(int depth, String id, String text) => HeadingBlock(
      depth: depth,
      id: id,
      mark: '',
      inlines: [TextInline(text: text)],
    );

    testWidgets('is headed by the LokumAI mark in place of its compass, named by its words alone', (tester) async {
      await pumpBlocks(tester, [
        heading(2, 'body', 'Body'),
        heading(3, 'early', '🧭 Early'),
        heading(2, 'references', 'Kaynaklar'),
        heading(3, 'papers', '📄 Papers'),
        heading(3, 'modules', '🧭 Modüller'),
      ]);

      expect(find.byKey(BlockView.modulesMarkKey), findsOneWidget);
      expect(
        find.text('Modüller'),
        findsOneWidget,
        reason: 'the compass gone, matched by place and glyph, not by word',
      );
      expect(tester.getSemantics(find.text('Modüller')), matchesSemantics(isHeader: true, label: 'Modüller'));
      expect(find.text('🧭 Early'), findsOneWidget, reason: 'before the last ## heading, the compass stays');
      expect(find.text('📄 Papers'), findsOneWidget);
    });

    testWidgets('a document with no ## heading has no mark', (tester) async {
      await pumpBlocks(tester, [heading(3, 'modules', '🧭 Modules')]);

      expect(find.byKey(BlockView.modulesMarkKey), findsNothing);
      expect(find.text('🧭 Modules'), findsOneWidget);
    });
  });

  testWidgets('a depth-2 heading is a header without its mark and owns its key', (tester) async {
    final harness = await pumpBlocks(tester, const [
      HeadingBlock(
        depth: 2,
        id: 'two',
        mark: 'IV',
        inlines: [TextInline(text: 'Two')],
      ),
    ]);

    expect(find.textContaining('IV'), findsNothing);
    expect(tester.getSemantics(find.text('Two')), matchesSemantics(isHeader: true, label: 'Two'));
    expect(harness.keys['two']!.currentContext, isNotNull);
    final style = styleOf(tester, 'Two');
    expect(style.fontSize, BazaarType.section.size);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, colorsOf(tester).onSurfaceTitle);
    // In the display face, at its own spacing.
    expect(style.fontFamily, displayFamily);
    expect(style.letterSpacing, 0);
    expect(find.byKey(const Key('heading-rule')), findsOneWidget);
  });

  testWidgets('depth-3 and depth-4 headings use the subsection and body steps without the rule', (tester) async {
    final harness = await pumpBlocks(tester, const [
      HeadingBlock(
        depth: 3,
        id: 'three',
        mark: null,
        inlines: [TextInline(text: 'Three')],
      ),
      HeadingBlock(
        depth: 4,
        id: 'four',
        mark: null,
        inlines: [TextInline(text: 'Four')],
      ),
    ]);

    expect(styleOf(tester, 'Three').fontSize, BazaarType.subsection.size);
    expect(styleOf(tester, 'Three').fontWeight, FontWeight.w600);
    expect(styleOf(tester, 'Four').fontSize, BazaarType.body.size);
    expect(styleOf(tester, 'Four').fontWeight, FontWeight.w600);
    expect(tester.getSemantics(find.text('Four')), matchesSemantics(isHeader: true, label: 'Four'));
    expect(harness.keys.keys, ['three', 'four']);
    expect(find.byKey(const Key('heading-rule')), findsNothing);
  });

  testWidgets('an ordered list numbers from start', (tester) async {
    await pumpBlocks(tester, [
      ListBlock(ordered: true, start: 3, items: [item('c'), item('d')]),
      ListBlock(ordered: true, start: null, items: [item('a')]),
    ]);

    expect(find.text('3.'), findsOneWidget);
    expect(find.text('4.'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(tester.getTopLeft(find.text('c')).dx, greaterThanOrEqualTo(22));
  });

  group('an ordered list number ends left of its item text', () {
    /// The global right edge of the painted text of the marker [marker].
    double markerRight(WidgetTester tester, String marker) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(marker));
      final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: marker.length));
      return boxes.map((box) => paragraph.localToGlobal(Offset(box.right, 0)).dx).reduce(math.max);
    }

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('at text scale $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpBlocks(tester, [
          ListBlock(ordered: true, start: null, items: [item('first')]),
          ListBlock(ordered: true, start: 9, items: [item('ninth'), item('tenth')]),
        ]);

        expect(tester.takeException(), isNull);
        expect(markerRight(tester, '1.'), lessThan(tester.getTopLeft(find.text('first')).dx));
        final text = tester.getTopLeft(find.text('ninth')).dx;
        expect(tester.getTopLeft(find.text('tenth')).dx, text);
        expect(markerRight(tester, '9.'), lessThan(text));
        expect(markerRight(tester, '10.'), lessThan(text));
        expect(tester.getTopLeft(find.text('first')).dx, greaterThanOrEqualTo(22));
      });
    }
  });

  testWidgets('an unordered list shows bullets', (tester) async {
    await pumpBlocks(tester, [
      ListBlock(ordered: false, start: null, items: [item('a'), item('b')]),
    ]);

    expect(find.text('•'), findsNWidgets(2));
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('task boxes are read-only and show task.checked', (tester) async {
    await pumpBlocks(tester, [
      ListBlock(ordered: false, start: null, items: [item('done', checked: true), item('open', checked: false)]),
    ]);

    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes.map((b) => b.value), [true, false]);
    expect(boxes.every((b) => b.onChanged == null), isTrue); // A16
    expect(find.text('•'), findsNothing);
  });

  group('a live checklist (web D129)', () {
    testWidgets("the boxes show the reader's ticks, a tap reports the item's index, and each is named by its text", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final toggled = <(int, bool)>[];
      await pumpBlocks(
        tester,
        [
          ListBlock(
            ordered: false,
            start: null,
            items: [
              item('done', checked: false, taskIndex: 0),
              item('open', checked: true, taskIndex: 1),
              item('plain'),
            ],
          ),
        ],
        wrap: (child) => ChecklistScope(
          ticks: const {0},
          onToggle: (index, {required ticked}) => toggled.add((index, ticked)),
          child: child,
        ),
      );

      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      // The record's ticks, not the document's task.checked.
      expect(boxes.map((b) => b.value), [true, false]);
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).last);
      expect(toggled, [(0, false), (1, true)]);
      expect(tester.getSemantics(find.byType(Checkbox).last).label, 'open');
      await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
      semantics.dispose();
    });

    testWidgets('an item from a document without indexes stays read-only under a checklist', (tester) async {
      await pumpBlocks(tester, [
        ListBlock(ordered: false, start: null, items: [item('old', checked: true)]),
      ], wrap: (child) => ChecklistScope(ticks: const {}, onToggle: (_, {required ticked}) {}, child: child));
      final box = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(box.value, isTrue);
      expect(box.onChanged, isNull);
    });
  });

  testWidgets('a quote shows its label', (tester) async {
    await pumpBlocks(tester, const [
      QuoteBlock(
        label: 'NOTE',
        blocks: [
          ParagraphBlock(inlines: [TextInline(text: 'Quoted.')], lead: false),
        ],
      ),
    ]);

    final label = tester.widget<Text>(find.text('NOTE'));
    expect(label.style!.fontWeight, FontWeight.w600);
    expect(label.style!.fontSize, BazaarType.item.size);
    expect(label.style!.color, colorsOf(tester).onSurfaceTitle);
    expect(find.text('Quoted.'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Quoted.')).dy, greaterThan(tester.getBottomLeft(find.text('NOTE')).dy));
  });

  testWidgets('a quote without a label shows only its blocks', (tester) async {
    await pumpBlocks(tester, const [
      QuoteBlock(
        label: null,
        blocks: [
          ParagraphBlock(inlines: [TextInline(text: 'Quoted.')], lead: false),
        ],
      ),
    ]);

    expect(find.text('Quoted.'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('a rule is a divider', (tester) async {
    await pumpBlocks(tester, const [RuleBlock()]);

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.color, colorsOf(tester).line);
    expect(divider.height, 68);
  });

  testWidgets('an unknown block offers the web page when there is one', (tester) async {
    final calls = stubOpeningUrlLauncher(canLaunch: true);
    await pumpBlocks(tester, const [UnknownBlock(type: 'poll')]);

    expect(find.text('This part needs a newer version of the app.'), findsOneWidget);
    await tester.tap(find.text('Open on the web'));
    await tester.pump();
    expect(calls.launchedUrls, ['https://content.test/courses/alpha/first/']);
  });

  testWidgets('an unknown block in a level document has no web action', (tester) async {
    await pumpBlocks(tester, const [UnknownBlock(type: 'poll')], levelDocument: true);

    expect(find.text('This part needs a newer version of the app.'), findsOneWidget);
    expect(find.text('Open on the web'), findsNothing);
  });

  testWidgets('blocks follow each other in order', (tester) async {
    await pumpBlocks(tester, const [
      ParagraphBlock(inlines: [TextInline(text: 'First.')], lead: false),
      ParagraphBlock(inlines: [TextInline(text: 'Second.')], lead: false),
    ]);

    // A paragraph keeps 17 below it.
    expect(tester.getTopLeft(find.text('Second.')).dy - tester.getBottomLeft(find.text('First.')).dy, 17);
  });

  for (final brightness in Brightness.values) {
    testWidgets('every block kind meets the platform guidelines in ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(390, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpBlocks(
        tester,
        [
          const ParagraphBlock(inlines: [TextInline(text: 'Lead.')], lead: true),
          const HeadingBlock(
            depth: 2,
            id: 'two',
            mark: null,
            inlines: [TextInline(text: 'Two')],
          ),
          const ParagraphBlock(inlines: [TextInline(text: 'Body.')], lead: false),
          ListBlock(ordered: false, start: null, items: [item('task', checked: true), item('open', checked: false)]),
          const QuoteBlock(
            label: 'NOTE',
            blocks: [
              ParagraphBlock(inlines: [TextInline(text: 'Quoted.')], lead: false),
            ],
          ),
          for (final kind in CalloutKind.values)
            CalloutBlock(
              kind: kind,
              title: const [TextInline(text: 'Title')],
              blocks: const [
                ParagraphBlock(inlines: [TextInline(text: 'Callout body.')], lead: false),
              ],
              action: const CalloutAction(
                target: ExternalTarget(url: 'https://example.com/'),
                inlines: [TextInline(text: 'Read more')],
              ),
            ),
          const CodeBlock(
            language: 'python',
            lines: [
              [CodeToken(text: 'def', role: 'keyword', bold: true)],
            ],
          ),
          const UnknownBlock(type: 'poll'),
        ],
        brightness: brightness,
        platform: defaultTargetPlatform,
      );

      await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
    }, variant: bazaarPlatforms);
  }
}
