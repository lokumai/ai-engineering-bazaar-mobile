import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The module's sections in a drawer (web `ContentsDrawer.tsx`, `SheetRail.tsx`): `On this page` with a close button,
/// then the depth-2 entries, each with its mark when any entry has one. A tap calls [onSelect] with the heading id; the
/// reader closes the drawer and scrolls once it is closed.
class ContentsDrawer extends StatelessWidget {
  const ContentsDrawer({super.key, required this.entries, required this.onSelect});

  /// The depth-2 entries of the table of contents.
  final List<TocEntry> entries;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final marked = entries.any((entry) => entry.mark != null);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        s.reader_on_this_page,
                        style: TextStyle(
                          fontSize: BazaarType.item.size,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceTitle,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: s.reader_close,
                    onPressed: () => Scaffold.of(context).closeEndDrawer(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            Expanded(
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: s.reader_sections,
                child: ListView(
                  children: [
                    for (final entry in entries)
                      ListTile(
                        leading: marked ? Text(entry.mark ?? '', style: TextStyle(color: colors.onSurfaceMuted)) : null,
                        title: Text(entry.text, style: TextStyle(color: colors.onSurface)),
                        onTap: () => onSelect(entry.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
