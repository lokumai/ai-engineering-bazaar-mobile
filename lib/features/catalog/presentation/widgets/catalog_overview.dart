import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The catalog's Overview view (web `CatalogOverview.tsx:59-162`): one section per level that holds a visible row,
/// with the level title as a link to the level page, a bar of the written rows, and the rows.
///
/// Each section carries its level's hue in its key and its bar (the redesign, plan Phase 1D); text stays in the
/// theme's colours.
class CatalogOverview extends StatelessWidget {
  const CatalogOverview({super.key, required this.track, required this.index, required this.rows});

  final Track track;
  final BundleIndex index;

  /// The visible rows.
  final List<CatalogRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [
        for (final level in levelsOf(index, rows))
          _LevelSection(
            track: track,
            level: level,
            hue: levelHue(context, levelPosition(index, level.slug)),
            rows: applyLevel(rows, level.slug),
          ),
      ],
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({required this.track, required this.level, required this.hue, required this.rows});

  final Track track;
  final LevelEntry level;

  /// The level's hue, for its key and its bar.
  final Color hue;

  /// The visible rows of [level].
  final List<CatalogRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minHeight = minTapTarget(theme.platform);
    // Both counts are over the level's visible rows, as the web's.
    final ready = rows.where((row) => row.drawn).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: InkWell(
            onTap: () => context.push(BazaarPaths.level(track, level.slug)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    LevelKey(color: hue),
                    Flexible(child: Text(level.title, style: theme.textTheme.titleMedium)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Semantics(
          label: S.of(context).catalog_written(ready, rows.length),
          image: true,
          child: ExcludeSemantics(
            child: LinearProgressIndicator(
              value: ready / rows.length,
              color: hue,
              backgroundColor: context.bazaarColors.surfaceSunken,
              minHeight: 6,
              borderRadius: const BorderRadius.all(BazaarRadii.hair),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final row in rows) _OverviewRow(track: track, row: row, minHeight: minHeight),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.track, required this.row, required this.minHeight});

  final Track track;
  final CatalogRow row;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push(BazaarPaths.module(track, row.key)),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Text(moduleNumber(row.number), style: textTheme.labelLarge),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(row.title, style: textTheme.bodyLarge),
                    if (!row.drawn)
                      Text(
                        S.of(context).module_planned,
                        style: textTheme.bodyMedium?.copyWith(color: context.bazaarColors.onSurfaceMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
