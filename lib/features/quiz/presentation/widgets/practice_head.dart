import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/glossary.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/brief_list_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/level_group.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// One module of Today's review: its title and its level's hue.
typedef _TodayModule = ({String title, Color hue});

/// Practice's head (plan 13.2): Today's review as a deck of cards, with how far the day has gone, its modules and
/// Start, or why there is none today; then three tiles side by side to Wrong answers, A module in 2 minutes and the
/// Glossary, each in its own hue with its count (the owner, 2026-11-18: the plain card and the grey rows read apart
/// from the rest of the app).
class PracticeHead extends StatelessWidget {
  const PracticeHead({super.key, required this.index, required this.track});

  final BundleIndex index;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final language = context.watch<LanguageCubit>().state;
    final history = context.watch<ReviewBloc>().state.history;
    final pool = reviewPoolOf(context, track, language);
    final notes = context.watch<StudyNotesCubit>().state;
    final briefs = pool != null && notes is StudyNotesReady ? briefModules(pool.completed, notes).length : 0;
    final terms = pool != null && notes is StudyNotesReady ? glossaryOf(notes.modules, language).length : 0;
    final today = dayNumber(clock.now());
    final cards = pool?.today(history, today) ?? const <String>[];
    final wrong = pool?.wrong(history) ?? const <String>[];
    final modules = <String, _TodayModule>{
      for (final key in cards.map(moduleOfKey))
        key: (
          title: index.module(key)?.tracks[track]?.titleIn(language) ?? key,
          hue: levelHue(context, index.levels.indexWhere((level) => level.slug == index.module(key)?.level)),
        ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TodayDeck(
          key: const Key('practice-today'),
          ready: pool != null,
          cards: cards.length,
          done: history.doneOn(today),
          modules: modules.values.toList(),
          wrong: wrong.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        _Tiles(
          tiles: [
            _Tile(
              key: const Key('practice-wrong'),
              icon: Icons.close_rounded,
              hue: colors.fault,
              count: wrong.length,
              title: s.practice_wrong,
              detail: s.practice_wrong_count(wrong.length),
              onTap: () => context.push(BazaarPaths.practiceWrong),
            ),
            _Tile(
              key: const Key('practice-brief'),
              icon: Icons.timer_outlined,
              hue: BazaarFixedColors.caution,
              count: briefs,
              title: s.practice_brief,
              detail: s.practice_brief_count(briefs),
              onTap: () => context.push(BazaarPaths.practiceBrief),
            ),
            _Tile(
              key: const Key('practice-glossary'),
              icon: Icons.sort_by_alpha_rounded,
              hue: colors.category3,
              count: terms,
              title: s.practice_glossary,
              detail: s.practice_glossary_count(terms),
              onTap: () => context.push(BazaarPaths.practiceGlossary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Today's review as the top card of a deck, two more cards' edges under it: its name, the day's cards as a meter, the
/// modules they come from, and Start; or that there is nothing today, or that today's are done.
class _TodayDeck extends StatelessWidget {
  const _TodayDeck({
    super.key,
    required this.ready,
    required this.cards,
    required this.done,
    required this.modules,
    required this.wrong,
  });

  /// Whether the notes are read; until then only the name shows.
  final bool ready;

  /// The cards left today.
  final int cards;

  /// The cards Today's review took today.
  final int done;
  final List<_TodayModule> modules;
  final int wrong;

  /// How far each card under the top one shows below it.
  static const double _edge = 6;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted);
    final total = done + cards;
    final meter = total == 0 ? null : s.practice_today_meter(done, total);
    final top = BazaarCard(
      shape: BazaarCardShape.leaf,
      accent: colors.primary,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.practice_today,
                    style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurfaceTitle),
                  ),
                ),
              ),
              if (ready && total > 0 && cards == 0)
                const Icon(Icons.check_circle, color: BazaarFixedColors.success, size: 26),
            ],
          ),
          if (ready && cards > 0) ...[
            Text(
              s.practice_today_cards(cards, reviewMinutes(cards)),
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
            if (meter != null) _DayMeter(done: done, total: total, label: meter),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                for (final module in modules)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      LevelKey(color: module.hue, size: 8),
                      Flexible(
                        child: Text(
                          module.title,
                          style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            FilledButton.icon(
              key: const Key('practice-today-start'),
              onPressed: () => context.push(BazaarPaths.practiceReview),
              icon: const Icon(Icons.arrow_forward),
              iconAlignment: IconAlignment.end,
              label: Text(s.practice_start),
            ),
          ] else if (ready) ...[
            Text(
              cards == 0 && done > 0 ? s.practice_today_done : s.practice_today_none,
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
            if (meter != null) _DayMeter(done: done, total: total, label: meter),
            Text(done > 0 ? s.practice_today_done_lede : s.practice_today_none_lede, style: muted),
            if (wrong > 0)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('practice-today-wrong'),
                  onPressed: () => context.push(BazaarPaths.practiceWrong),
                  icon: const Icon(Icons.arrow_forward),
                  iconAlignment: IconAlignment.end,
                  label: Text(s.practice_go_wrong),
                ),
              ),
          ],
        ],
      ),
    );
    // The two cards under the top one are only their edges: decoration.
    return Padding(
      padding: const EdgeInsets.only(bottom: _edge * 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final depth in const [2, 1])
            Positioned(
              left: AppSpacing.md * depth,
              right: AppSpacing.md * depth,
              top: _edge * depth,
              bottom: -_edge * depth,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(colors.primary.withValues(alpha: 0.04 * depth), colors.surfaceRaised),
                    border: Border.all(color: colors.line),
                    borderRadius: BazaarCard.radiusOf(BazaarCardShape.leaf),
                  ),
                ),
              ),
            ),
          top,
        ],
      ),
    );
  }
}

/// The day's cards as one segment each, those taken filled.
class _DayMeter extends StatelessWidget {
  const _DayMeter({required this.done, required this.total, required this.label});

  final int done;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: SegmentMeter(
            done: done,
            total: total,
            color: BazaarFixedColors.success,
            semanticLabel: label,
            height: 8,
          ),
        ),
        ExcludeSemantics(
          child: Text('$done/$total', style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted)),
        ),
      ],
    );
  }
}

/// The tiles side by side, each as tall as the tallest; one under another when the text is large.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.tiles});

  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 13;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [for (final tile in tiles) tile],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [for (final tile in tiles) Expanded(child: tile)],
      ),
    );
  }
}

/// One of Practice's tiles: an arch card in [hue] with its mark, its count large and its name; a tap opens its page.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.hue,
    required this.count,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;

  /// Its edge, wash and the ring of its mark; never its text (spec 3.8).
  final Color hue;
  final int count;
  final String title;

  /// The count in words, which a screen reader says in place of the number.
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return BazaarCard(
      shape: BazaarCardShape.arch,
      accent: hue,
      tint: hue,
      onTap: onTap,
      semanticLabel: '$title, $detail',
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PracticeDisc(hue: hue, icon: icon),
              const Spacer(),
              Text('$count', style: displayFace(theme.textTheme.headlineSmall)?.copyWith(color: colors.onSurfaceTitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceTitle, height: 1.25)),
        ],
      ),
    );
  }
}
