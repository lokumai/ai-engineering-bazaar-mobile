import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/material.dart';

/// The stats the record carries, at the top of the catalog (moved from the progress page, plan 1AB): the modules
/// completed in the track and the days on which anything was written (the record's `days`), each a number over its
/// label, read as one line.
class CatalogStats extends StatelessWidget {
  const CatalogStats({super.key, required this.completed, required this.days});

  final int completed;
  final int days;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Expanded(
          child: _Stat(value: completed, label: s.catalog_stat_completed(completed)),
        ),
        Expanded(
          child: _Stat(value: days, label: s.catalog_stat_days(days)),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    // A node of its own, so the two stats are read apart inside the catalog's list.
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: BazaarCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text('$value', style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}
