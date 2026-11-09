import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The catalog's Cards view (web `CatalogCards.tsx:226-320`): per level that holds a visible row, a heading with the
/// level title (no count), then one card per row with the level and number, the title as a link to the module, the
/// Description disclosure, and the Length and Requires facts.
///
/// One Description is open at a time (the web's `<details name>` group); the page holds which one.
/// Length shows minutes only (A10, A15), and a planned card has no Description, because the index carries neither the
/// word count nor a planned module's parts (D111).
class CatalogCards extends StatelessWidget {
  const CatalogCards({
    super.key,
    required this.track,
    required this.index,
    required this.rows,
    required this.openDescription,
    required this.onDescription,
  });

  final Track track;
  final BundleIndex index;

  /// The visible rows.
  final List<CatalogRow> rows;

  /// The key of the row whose Description is open; null when every one is closed.
  final String? openDescription;

  /// Called with the key of the row whose Description should be open, or null to close it.
  final ValueChanged<String?> onDescription;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        for (final level in levelsOf(index, rows)) ...[
          Semantics(header: true, child: Text(level.title, style: textTheme.titleMedium)),
          for (final row in applyLevel(rows, level.slug))
            _ModuleCard(
              track: track,
              level: level,
              row: row,
              open: openDescription == row.key,
              onDescription: () => onDescription(openDescription == row.key ? null : row.key),
            ),
        ],
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.track,
    required this.level,
    required this.row,
    required this.open,
    required this.onDescription,
  });

  final Track track;
  final LevelEntry level;
  final CatalogRow row;
  final bool open;
  final VoidCallback onDescription;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final muted = context.bazaarColors.onSurfaceMuted;
    final minHeight = minTapTarget(theme.platform);
    final summary = row.summary;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${level.title} ${moduleNumber(row.number)}', style: textTheme.labelMedium?.copyWith(color: muted)),
            InkWell(
              onTap: () => context.push(BazaarPaths.module(track, row.key)),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(row.title, style: textTheme.titleMedium),
                ),
              ),
            ),
            if (summary != null) ...[
              Semantics(
                container: true,
                button: true,
                expanded: open,
                child: InkWell(
                  onTap: onDescription,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Row(
                      spacing: AppSpacing.xs,
                      children: [
                        Flexible(child: Text(l10n.card_description, style: textTheme.labelLarge)),
                        ExcludeSemantics(child: Icon(open ? Icons.expand_less : Icons.expand_more, size: 20)),
                      ],
                    ),
                  ),
                ),
              ),
              if (open)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(summary, style: textTheme.bodyMedium),
                ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.sm,
              children: [
                _Fact(
                  label: l10n.card_length,
                  value: row.drawn ? l10n.card_length_minutes(row.minutes) : l10n.module_planned,
                ),
                _Fact(label: l10n.card_requires, value: requiresLabel(l10n, row.requires)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(color: context.bazaarColors.onSurfaceMuted)),
        Text(value, style: textTheme.bodyMedium),
      ],
    );
  }
}
