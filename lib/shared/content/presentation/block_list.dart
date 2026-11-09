import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/callout_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/code_block_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/table_block_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/utils/external_link.dart';
import 'package:flutter/material.dart';

/// What the blocks of one document share: where a link tap goes, the document's web page, the key each heading
/// registers under its id, and the diagram grounds.
final class BlockRenderContext {
  const BlockRenderContext({
    required this.onLink,
    required this.webPage,
    required this.headingKey,
    required this.diagramThemes,
  });

  final LinkHandler onLink;

  /// The document's page on the web, which the reader builds with `WebLinks.webPage` (A37); null in a level document,
  /// which has no web path (A23).
  final Uri? webPage;

  /// The key a heading with this id is drawn under, so the reader can scroll to it.
  final GlobalKey Function(String id) headingKey;
  final DiagramThemes diagramThemes;
}

/// The ink and alignment a container sets for the prose inside it: a callout centres its text and caps its paragraphs
/// at 52 characters, and a filled warning draws every text in on-caution.
class ProseScope extends InheritedWidget {
  const ProseScope({
    super.key,
    this.ink,
    this.textAlign = TextAlign.start,
    this.paragraphMaxWidth,
    required super.child,
  });

  /// The text colour of paragraphs, headings and list markers; null keeps each block's own.
  final Color? ink;
  final TextAlign textAlign;
  final double? paragraphMaxWidth;

  static ProseScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ProseScope>();

  @override
  bool updateShouldNotify(ProseScope oldWidget) =>
      ink != oldWidget.ink || textAlign != oldWidget.textAlign || paragraphMaxWidth != oldWidget.paragraphMaxWidth;
}

/// The blocks of a document, one under another, with the web's spacing (`w3b` F.1): adjacent margins collapse to the
/// larger of the two, as CSS margins do. A [nested] list, inside a quote, a callout or a list item, drops the bottom
/// margin of its last block, as the web's `:last-child` rules do.
class BlockList extends StatelessWidget {
  const BlockList({super.key, required this.blocks, required this.render, this.nested = false});

  final List<Block> blocks;
  final BlockRenderContext render;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var previousBottom = 0.0;
    for (final (index, block) in blocks.indexed) {
      final margin = _marginOf(block);
      final gap = index == 0 ? margin.top : math.max(previousBottom, margin.top);
      if (gap > 0) children.add(SizedBox(height: gap));
      children.add(BlockView(block: block, render: render));
      previousBottom = margin.bottom;
    }
    if (!nested && previousBottom > 0) children.add(SizedBox(height: previousBottom));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// The space above and below a block, before collapsing.
({double top, double bottom}) _marginOf(Block block) => switch (block) {
  ParagraphBlock(lead: true) => (top: 0, bottom: 26),
  ParagraphBlock() => (top: 0, bottom: 17),
  HeadingBlock(depth: 2) => (top: 44, bottom: 14),
  HeadingBlock(depth: 3) => (top: 30, bottom: 8),
  HeadingBlock() => (top: 24, bottom: 8),
  ListBlock() => (top: 0, bottom: 17),
  QuoteBlock() => (top: 0, bottom: 28),
  CalloutBlock() => (top: 36, bottom: 36),
  CodeBlock() => (top: 0, bottom: 24),
  TableBlock() || ImageBlock() || DiagramBlock() => (top: 0, bottom: 26),
  RuleBlock() => (top: 0, bottom: 0), // the divider's own height holds the 34 above and below
  UnknownBlock() => (top: 0, bottom: 17),
};

/// One block, drawn as the web draws it (`w3b` F.1).
class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block, required this.render});

  final Block block;
  final BlockRenderContext render;

  @override
  Widget build(BuildContext context) => switch (block) {
    final ParagraphBlock block => _Paragraph(block: block, render: render),
    final HeadingBlock block => _Heading(block: block, render: render),
    final ListBlock block => _ListView(block: block, render: render),
    final QuoteBlock block => _Quote(block: block, render: render),
    final CalloutBlock block => CalloutView(block: block, render: render),
    final CodeBlock block => CodeBlockView(block: block),
    final TableBlock block => TableBlockView(block: block, render: render),
    final ImageBlock block => FigureView.image(block: block),
    final DiagramBlock block => FigureView.diagram(block: block, themes: render.diagramThemes),
    RuleBlock() => Divider(color: context.bazaarColors.line, height: 68, thickness: 1),
    UnknownBlock() => _Unknown(webPage: render.webPage),
  };
}

/// The body text style in [ink].
TextStyle _bodyStyle(Color ink) =>
    TextStyle(fontSize: BazaarType.body.size, height: BazaarType.body.height, color: ink);

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.block, required this.render});

  final ParagraphBlock block;
  final BlockRenderContext render;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final scope = ProseScope.maybeOf(context);
    final style = block.lead
        ? TextStyle(
            fontSize: BazaarType.lead.size,
            height: BazaarType.lead.height ?? BazaarType.body.height,
            color: scope?.ink ?? colors.onSurfaceMuted,
          )
        : _bodyStyle(scope?.ink ?? colors.onSurface);
    final text = InlineText(
      inlines: block.inlines,
      style: style,
      onLink: render.onLink,
      textAlign: scope?.textAlign ?? TextAlign.start,
    );
    final maxWidth = scope?.paragraphMaxWidth;
    if (maxWidth == null) return text;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: text,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.block, required this.render});

  final HeadingBlock block;
  final BlockRenderContext render;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final scope = ProseScope.maybeOf(context);
    final ink = scope?.ink ?? colors.onSurfaceTitle;
    final style = switch (block.depth) {
      2 => TextStyle(
        fontSize: BazaarType.section.size,
        height: BazaarType.section.height,
        fontWeight: FontWeight.w600,
        letterSpacing: BazaarType.trackingSection * BazaarType.section.size,
        color: ink,
      ),
      3 => TextStyle(
        fontSize: BazaarType.subsection.size,
        height: BazaarType.subsection.height,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      _ => _bodyStyle(ink).copyWith(fontWeight: FontWeight.w600),
    };
    // The mark is never drawn: the web keeps it only for its table of contents (corrections, row 3.6.3).
    final text = InlineText(
      inlines: block.inlines,
      style: style,
      onLink: render.onLink,
      textAlign: scope?.textAlign ?? TextAlign.start,
    );
    return Semantics(
      container: true,
      header: true,
      child: KeyedSubtree(
        key: render.headingKey(block.id),
        child: block.depth == 2 ? _ruled(text, colors.surface) : text,
      ),
    );
  }

  /// The section heading with the web's dashed ornament rule filling the rest of its line: the rule runs full width
  /// behind the text, which sits on a surface box with 12 px after it.
  Widget _ruled(Widget text, Color surface) => Stack(
    alignment: AlignmentDirectional.centerStart,
    children: [
      const Positioned.fill(
        child: CustomPaint(key: Key('heading-rule'), painter: _DashedRule()),
      ),
      DecoratedBox(
        decoration: BoxDecoration(color: surface),
        child: Padding(padding: const EdgeInsetsDirectional.only(end: 12), child: text),
      ),
    ],
  );
}

/// A 2 px dashed line in the ornament colour (6 dash, 6 gap) across the middle of its box.
class _DashedRule extends CustomPainter {
  const _DashedRule();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BazaarFixedColors.ornament
      ..strokeWidth = 2;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 6, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRule oldDelegate) => false;
}

/// The marker column of a list at text scale 1.0 (web prose.css: a 22 px padding), and the gap between a marker and
/// its item text.
const _markerWidth = 22.0;
const _markerGap = 6.0;

/// The marker column of an ordered list whose widest number is [widest]: wide enough for that number at the current
/// text scale and the gap, never narrower than [_markerWidth], so a number never paints over its item's text.
double _orderedMarkerWidth(BuildContext context, String widest, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: widest, style: DefaultTextStyle.of(context).style.merge(style)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return math.max(_markerWidth, (width + _markerGap).ceilToDouble());
}

class _ListView extends StatelessWidget {
  const _ListView({required this.block, required this.render});

  final ListBlock block;
  final BlockRenderContext render;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final markerStyle = _bodyStyle(ProseScope.maybeOf(context)?.ink ?? colors.onSurface);
    final start = block.start ?? 1;
    final markerWidth = block.ordered
        ? _orderedMarkerWidth(context, '${start + block.items.length - 1}.', markerStyle)
        : _markerWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, item) in block.items.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.checked case final checked?)
                  // A16: the box shows the bundle's task.checked and cannot be changed.
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Checkbox(
                      value: checked,
                      onChanged: null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  SizedBox(
                    width: markerWidth,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: _markerGap),
                      child: Text(
                        block.ordered ? '${start + index}.' : '•',
                        style: markerStyle,
                        textAlign: TextAlign.end,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                Expanded(
                  child: BlockList(blocks: item.blocks, render: render, nested: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.block, required this.render});

  final QuoteBlock block;
  final BlockRenderContext render;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final scope = ProseScope.maybeOf(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: BazaarShapes.leaf,
      ),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (block.label case final label?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: BazaarType.item.size,
                  height: BazaarType.item.height,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceTitle,
                ),
              ),
            ),
          // The card draws its own ground, so it takes its own ink; a callout's alignment and width cap still hold.
          ProseScope(
            textAlign: scope?.textAlign ?? TextAlign.start,
            paragraphMaxWidth: scope?.paragraphMaxWidth,
            child: BlockList(blocks: block.blocks, render: render, nested: true),
          ),
        ],
      ),
    );
  }
}

/// A block of a type this app does not know (A23): one line saying so and, when the document has a web page, the way
/// to read it there.
class _Unknown extends StatelessWidget {
  const _Unknown({required this.webPage});

  final Uri? webPage;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final s = S.of(context);
    final webPage = this.webPage;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: const BorderRadius.all(BazaarRadii.lg),
      ),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(s.block_unknown, style: _bodyStyle(colors.onSurface)),
          if (webPage != null)
            TextButton(onPressed: () => unawaited(openExternalLink(context, webPage)), child: Text(s.open_on_the_web)),
        ],
      ),
    );
  }
}
