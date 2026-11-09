import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The planned parts of a draft as a table (web `ScheduleOfParts.tsx:13-35`): the caption `Schedule of parts`, the
/// heads `Item` and `Description`, and one row per part numbered `01`, `02`, in the frame of a content table.
class ScheduleOfParts extends StatelessWidget {
  const ScheduleOfParts({super.key, required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final rule = BorderSide(color: colors.line);
    final headStyle = TextStyle(
      fontSize: BazaarType.mark.size,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    );
    final bodyStyle = TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface);

    Widget cell(String text, TextStyle style) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      child: Text(text, style: style),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: s.reader_schedule_of_parts,
      child: Container(
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
              // The region carries the caption as its name.
              child: ExcludeSemantics(
                child: Text(
                  s.reader_schedule_of_parts,
                  style: TextStyle(
                    fontSize: BazaarType.meta.size,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
            Table(
              columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    border: parts.isEmpty ? null : Border(bottom: rule),
                  ),
                  children: [cell(s.reader_schedule_item, headStyle), cell(s.reader_schedule_description, headStyle)],
                ),
                for (final (index, part) in parts.indexed)
                  TableRow(
                    decoration: index == parts.length - 1 ? null : BoxDecoration(border: Border(bottom: rule)),
                    children: [cell((index + 1).toString().padLeft(2, '0'), bodyStyle), cell(part, bodyStyle)],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
