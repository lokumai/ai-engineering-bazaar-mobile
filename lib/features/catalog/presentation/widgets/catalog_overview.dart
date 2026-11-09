import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The catalog root's levels (plan 1N, the owner's review): one button per level, in the index's order, with its hue,
/// title, length and whether it is planned; a tap opens the level's modules under it, and a second tap closes them.
/// Several levels may be open at once; a module opens the reader.
class CatalogOverview extends StatefulWidget {
  const CatalogOverview({super.key, required this.track, required this.index, required this.rows});

  final Track track;
  final BundleIndex index;

  /// Every row of [track], in the index's order.
  final List<CatalogRow> rows;

  /// The key of [slug]'s level button.
  static Key levelKey(String slug) => ValueKey('catalog-level-$slug');

  @override
  State<CatalogOverview> createState() => _CatalogOverviewState();
}

class _CatalogOverviewState extends State<CatalogOverview> {
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        for (final level in levelsOf(index, widget.rows))
          _LevelButton(
            key: CatalogOverview.levelKey(level.slug),
            track: widget.track,
            level: level,
            hue: levelHue(context, levelPosition(index, level.slug)),
            minutes: index.modules
                .where((module) => module.level == level.slug)
                .fold(0, (sum, module) => sum + module.minutes),
            rows: applyLevel(widget.rows, level.slug),
            open: _open.contains(level.slug),
            onToggle: () =>
                setState(() => _open.contains(level.slug) ? _open.remove(level.slug) : _open.add(level.slug)),
          ),
      ],
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    super.key,
    required this.track,
    required this.level,
    required this.hue,
    required this.minutes,
    required this.rows,
    required this.open,
    required this.onToggle,
  });

  final Track track;
  final LevelEntry level;
  final Color hue;
  final int minutes;

  /// The rows of [level].
  final List<CatalogRow> rows;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final lead = levelLeadLine(s, modules: rows.length, minutes: minutes);
    final planned = level.status == LevelStatus.draft;
    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BazaarCard.radiusOf(BazaarCardShape.arch),
        side: BorderSide(color: open ? hue : colors.line, width: open ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: [level.title, lead, if (planned) s.module_planned].join(', '),
            excludeSemantics: true,
            onTap: onToggle,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    LevelKey(color: hue, size: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(level.title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                          Text(lead, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                        ],
                      ),
                    ),
                    if (planned) _Tag(text: s.module_planned),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold,
                      child: Icon(Icons.expand_more, color: colors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold,
            curve: BazaarMotion.bazaar,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: 1, color: colors.line),
                      for (final row in rows) _ModuleRow(track: track, row: row),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.track, required this.row});

  final Track track;
  final CatalogRow row;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final length = durationLabel(s, row.minutes);
    return InkWell(
      onTap: () => context.push(BazaarPaths.module(track, row.key)),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minTapTarget(theme.platform)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Text(moduleNumber(row.number), style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(row.title, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle)),
                    if (length != null)
                      Text(length, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                  ],
                ),
              ),
              if (!row.drawn) _Tag(text: s.module_planned),
              if (row.signed)
                Semantics(
                  label: s.catalog_filter_completed,
                  child: Icon(Icons.check_circle_outline, color: colors.category2, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.lineStrong),
        borderRadius: const BorderRadius.all(BazaarRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted)),
      ),
    );
  }
}
