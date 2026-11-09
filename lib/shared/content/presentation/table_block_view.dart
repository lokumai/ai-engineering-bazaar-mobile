import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/captions.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// A table in its frame (`w3b` F.1): the caption first, inside the frame, then the cells in a region named
/// `Table {number}` that scrolls sideways when the table is wider than the column. Head cells sit on the sunken strip
/// at weight 600; with row headers the first cell of each body row is 600 too. Every cell is left-aligned whatever
/// `align` says, as the web's CSS draws it (A39); the parser still checks `align` as a closed set.
class TableBlockView extends StatelessWidget {
  const TableBlockView({super.key, required this.block, required this.render});

  final TableBlock block;
  final BlockRenderContext render;

  /// The widest a cell's text may run before it wraps.
  static const double cellMaxWidth = 280;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final s = S.of(context);
    final rule = BorderSide(color: colors.line);
    final headStyle = TextStyle(
      fontSize: BazaarType.mark.size,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    );
    final bodyStyle = TextStyle(
      fontSize: BazaarType.control.size,
      fontWeight: FontWeight.w400,
      color: colors.onSurface,
    );
    final rowHeaderStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);

    Widget cell(Cell cell, TextStyle style) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: cellMaxWidth),
        child: InlineText(inlines: cell.inlines, style: style, onLink: render.onLink, textAlign: TextAlign.left),
      ),
    );

    return Semantics(
      key: const Key('table-region'),
      container: true,
      explicitChildNodes: true,
      label: s.block_table_region(block.number),
      child: Container(
        key: const Key('table-frame'),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.fromBorderSide(rule),
          borderRadius: const BorderRadius.all(BazaarRadii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(border: Border(bottom: rule)),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              child: Text(
                tableCaption(s, number: block.number, title: block.title),
                style: TextStyle(fontSize: BazaarType.meta.size, fontWeight: FontWeight.w600, color: colors.onSurface),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: colors.surfaceSunken,
                          border: block.rows.isEmpty ? null : Border(bottom: rule),
                        ),
                        children: [for (final head in block.head) cell(head, headStyle)],
                      ),
                      for (final (index, row) in block.rows.indexed)
                        TableRow(
                          decoration: index == block.rows.length - 1
                              ? null
                              : BoxDecoration(border: Border(bottom: rule)),
                          children: [
                            for (final (column, value) in row.indexed)
                              cell(value, block.rowHeaders && column == 0 ? rowHeaderStyle : bodyStyle),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
