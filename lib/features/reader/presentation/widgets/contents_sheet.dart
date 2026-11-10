import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// Shows the module's sections in a bottom sheet (the redesign's contents sheet, plan Phase 1E; web
/// `ContentsDrawer.tsx`, `SheetRail.tsx`) and completes with the id of the heading chosen, or null when the sheet is
/// closed without a choice.
Future<String?> showContentsSheet(BuildContext context, List<TocEntry> entries) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: context.bazaarColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
  builder: (context) => ContentsSheet(entries: entries),
);

/// The sheet's body: `On this page` with a close button, then the depth-2 entries, each with its mark when any entry
/// has one. A tap closes the sheet with the entry's heading id; the reader scrolls to it once the sheet is gone.
class ContentsSheet extends StatelessWidget {
  const ContentsSheet({super.key, required this.entries});

  /// The depth-2 entries of the table of contents.
  final List<TocEntry> entries;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final marked = entries.any((entry) => entry.mark != null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 8, 4),
          child: Row(
            children: [
              Expanded(
                // Shown in capitals as the mockup's label; read as written.
                child: Semantics(
                  header: true,
                  label: s.reader_on_this_page,
                  excludeSemantics: true,
                  child: Text(
                    s.reader_on_this_page.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: s.reader_close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.line),
        Flexible(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: s.reader_sections,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 18),
              children: [
                for (final entry in entries)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: marked ? Text(entry.mark ?? '', style: TextStyle(color: colors.onSurfaceMuted)) : null,
                    title: Text(
                      entry.text,
                      style: TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface),
                    ),
                    onTap: () => Navigator.of(context).pop(entry.id),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
