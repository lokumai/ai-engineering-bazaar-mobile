import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// What the catalog shows when the filters keep no module (web `NoMatch`, `Catalog.tsx:164-201`): the status line,
/// the cue, and one control that shows the whole catalog again.
class CatalogNoMatch extends StatelessWidget {
  const CatalogNoMatch({super.key, required this.total, required this.onShowAll});

  /// The number of rows before filtering.
  final int total;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Text(l10n.catalog_no_match(total), style: textTheme.titleMedium),
        Text(l10n.catalog_no_match_cue, style: textTheme.bodyMedium),
        OutlinedButton(onPressed: onShowAll, child: Text(l10n.catalog_show_all)),
      ],
    );
  }
}
