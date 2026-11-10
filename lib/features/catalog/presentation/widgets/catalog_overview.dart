import 'package:ai_engineering_bazaar/features/catalog/application/catalog_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/progress_mark.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/completion_toggled.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The catalog root's levels with the reader's progress in them (plan 1N, and 1AB: the progress page's cards moved
/// here). One arch card per level, in the index's order, with its hue, number, title, length, whether it is planned and
/// the dial of its completed modules; a tap opens the level's modules under it, and a second tap closes them. Several
/// levels may be open at once. The level of the next module to read starts open, and what the reader opens or closes
/// stays while the app runs ([CatalogFoldCubit]).
///
/// Each module row carries the progress page's mark: a toggle that completes the module when it is written, a dashed
/// ring that says Planned when it is not. The rest of the row opens the reader.
class CatalogOverview extends StatelessWidget {
  const CatalogOverview({
    super.key,
    required this.track,
    required this.index,
    required this.rows,
    required this.counts,
    this.upNext,
  });

  final Track track;
  final BundleIndex index;

  /// Every row of [track], in the index's order.
  final List<CatalogRow> rows;

  /// Each level's completed count in [track] by level slug; null while the record loads.
  final Map<String, LevelCount>? counts;

  /// The level of the next module to read in [track]; null while the record loads or when every module is complete.
  final String? upNext;

  /// The key of [slug]'s level button.
  static Key levelKey(String slug) => ValueKey('catalog-level-$slug');

  /// The key of the row of the module [key].
  static Key rowKey(String key) => ValueKey('catalog-row-$key');

  @override
  Widget build(BuildContext context) {
    final fold = context.watch<CatalogFoldCubit>();
    final open = fold.openIn(track, upNext);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        for (final level in levelsOf(index, rows))
          _LevelCard(
            key: CatalogOverview.levelKey(level.slug),
            track: track,
            index: index,
            level: level,
            position: levelPosition(index, level.slug),
            minutes: index.modules
                .where((module) => module.level == level.slug)
                .fold(0, (sum, module) => sum + module.minutes),
            rows: applyLevel(rows, level.slug),
            count: counts?[level.slug],
            open: open.contains(level.slug),
            onToggle: () => fold.toggle(track, level.slug, upNext),
          ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    super.key,
    required this.track,
    required this.index,
    required this.level,
    required this.position,
    required this.minutes,
    required this.rows,
    required this.count,
    required this.open,
    required this.onToggle,
  });

  final Track track;
  final BundleIndex index;
  final LevelEntry level;

  /// The 0-based place of [level] in the index, which picks its hue and its number.
  final int position;
  final int minutes;

  /// The rows of [level].
  final List<CatalogRow> rows;

  /// Null while the record loads.
  final LevelCount? count;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final hue = levelHue(context, position);
    final lead = levelLeadLine(s, modules: rows.length, minutes: minutes);
    final planned = level.status == LevelStatus.draft;
    final count = this.count;
    final meter = count == null
        ? s.level_completed_pending(level.total)
        : s.level_completed(count.approved, count.total);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold;
    return BazaarCard(
      shape: BazaarCardShape.arch,
      accent: hue,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: [level.title, lead, meter, if (planned) s.module_planned].join(', '),
            excludeSemantics: true,
            onTap: onToggle,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${moduleNumber(position + 1)}  ',
                                  style: TextStyle(color: colors.onSurfaceMuted),
                                ),
                                TextSpan(text: level.title),
                              ],
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                          ),
                          Text(lead, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                          if (planned) ...[const SizedBox(height: AppSpacing.xs), _Tag(text: s.module_planned)],
                        ],
                      ),
                    ),
                    CompletionDial(
                      done: count?.approved ?? 0,
                      total: count?.total ?? level.total,
                      color: hue,
                      center: count == null
                          ? s.catalog_level_dial(catalogNoReading, level.total)
                          : s.catalog_level_dial(count.approved.toString(), count.total),
                      semanticLabel: meter,
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: duration,
                      child: Icon(Icons.expand_more, color: colors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: BazaarMotion.bazaar,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: 1, color: colors.line),
                      const SizedBox(height: AppSpacing.xs),
                      for (final row in rows)
                        _ModuleRow(key: CatalogOverview.rowKey(row.key), track: track, index: index, row: row),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// One module of an open level (web `CourseCompletion.tsx:187-276`, the progress page's row, plan 1AB): the completion
/// toggle when the module is written in [track], a dashed ring that says Planned when it is not, then the number, the
/// title and the length, which open the module in [track].
class _ModuleRow extends StatelessWidget {
  const _ModuleRow({super.key, required this.track, required this.index, required this.row});

  final Track track;

  /// The index the toggle reads the module's For Everyone version from (plan 1V).
  final BundleIndex index;
  final CatalogRow row;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final minHeight = minTapTarget(theme.platform);
    final length = durationLabel(s, row.minutes);
    final Widget leading;
    if (row.drawn) {
      void toggle() => context.read<RecordBloc>().add(completionToggled(index, row.key, track, revision: null));
      // The name says which module and what a tap does; the checked state says whether it is complete.
      leading = Semantics(
        container: true,
        checked: row.signed,
        label: s.catalog_complete_module(row.title),
        onTap: toggle,
        excludeSemantics: true,
        child: InkResponse(
          onTap: toggle,
          child: SizedBox.square(
            dimension: minHeight,
            child: Center(child: ProgressMark(row.signed ? ProgressMarkKind.complete : ProgressMarkKind.notYet)),
          ),
        ),
      );
    } else {
      // Absent, not disabled: no control, and the mark says why (web `CourseCompletion.tsx:244-247`).
      leading = Semantics(
        container: true,
        label: s.module_planned,
        child: SizedBox.square(
          dimension: minHeight,
          child: const Center(child: ProgressMark(ProgressMarkKind.planned)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs, end: AppSpacing.md),
      child: Row(
        children: [
          leading,
          Expanded(
            child: InkWell(
              onTap: () => context.push(BazaarPaths.module(track, row.key)),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      Text(
                        moduleNumber(row.number),
                        style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            // The web's faint ink fails the text contrast guideline, so a planned row reads muted.
                            Text(
                              row.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: row.drawn ? colors.onSurfaceTitle : colors.onSurfaceMuted,
                              ),
                            ),
                            if (length != null && row.drawn)
                              Text(length, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
