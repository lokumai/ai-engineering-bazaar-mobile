import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/shared/study/domain/glossary.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/brief_list_page.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';

/// Practice's head (plan 13.2): the endless review as a deck of cards, its name, a line and Start (the owner,
/// 2026-11-18: Today's review stays Home's); then Wrong answers, Recap and the Glossary as tiles to tap.
class PracticeHead extends StatelessWidget {
  const PracticeHead({super.key, required this.track});

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
    final wrong = pool?.wrong(history) ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The tour's first stop on Practice: the endless review alone, so the Apprentice stands clear of the tiles.
        TourTarget(
          spot: TourSpots.practiceToday,
          child: _EndlessDeck(
            key: const Key('practice-endless'),
            ready: pool != null,
            cards: pool == null ? 0 : pool.questions.length + pool.newTerms.length,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Tiles(
          wrong: _Tile(
            key: const Key('practice-wrong'),
            icon: Icons.close_rounded,
            hue: colors.fault,
            count: wrong.length,
            title: s.practice_wrong,
            detail: s.practice_wrong_count(wrong.length),
            onTap: () => context.push(BazaarPaths.practiceWrong),
          ),
          brief: _Tile(
            key: const Key('practice-brief'),
            icon: Icons.timer_outlined,
            hue: BazaarFixedColors.caution,
            title: s.practice_brief,
            detail: s.practice_brief_count(briefs),
            onTap: () => context.push(BazaarPaths.practiceBrief),
          ),
          glossary: _Tile(
            key: const Key('practice-glossary'),
            icon: Icons.sort_by_alpha_rounded,
            hue: colors.category3,
            title: s.practice_glossary,
            detail: s.practice_glossary_count(terms),
            onTap: () => context.push(BazaarPaths.practiceGlossary),
          ),
        ),
      ],
    );
  }
}

/// The endless review as the top card of a deck, two more cards' edges under it, the one card on Practice with an edge
/// of colour along its top (the owner, 2026-11-18): its name, a short line on what it is, and Start once there are [cards] to
/// draw from.
class _EndlessDeck extends StatelessWidget {
  const _EndlessDeck({super.key, required this.ready, required this.cards});

  /// Whether the notes are read; until then only the name shows.
  final bool ready;

  /// The questions and terms it draws from.
  final int cards;

  /// How far each card under the top one shows below it.
  static const double _edge = 6;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final top = BazaarCard(
      shape: BazaarCardShape.leaf,
      accent: colors.primary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Icon(Icons.all_inclusive_rounded, color: colors.primary, size: 36),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.practice_endless,
                    style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle),
                  ),
                ),
              ),
            ],
          ),
          // A short line on what it is, never that a card may come again (the owner, 2026-11-18).
          if (ready)
            Text(s.practice_endless_lede, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
          if (ready && cards > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('practice-endless-start'),
              onPressed: () => context.push(BazaarPaths.practiceEndless),
              icon: const Icon(Icons.arrow_forward),
              iconAlignment: IconAlignment.end,
              label: Text(s.practice_start),
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

/// Wrong answers across the width, then Recap and the Glossary side by side (the owner, 2026-11-18); all one under
/// another when the text is large.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.wrong, required this.brief, required this.glossary});

  final _Tile wrong;
  final _Tile brief;
  final _Tile glossary;

  @override
  Widget build(BuildContext context) {
    final stacked = _stacked(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        wrong,
        if (stacked) ...[
          brief,
          glossary,
        ] else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Expanded(child: brief),
                Expanded(child: glossary),
              ],
            ),
          ),
      ],
    );
  }
}

/// Whether the text is large enough that the tiles stand one under another.
bool _stacked(BuildContext context) => MediaQuery.textScalerOf(context).scale(10) > 13;

/// One of Practice's tiles, drawn to be tapped (the owner, 2026-11-18): an arch card washed and edged in [hue], its mark
/// a disc filled with it, its name beside it, a count in a pill when it has one, and an arrow, all in one line; every
/// tile as tall as the others, their marks of one size (the owner, 2026-11-18).
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.hue,
    this.count,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;

  /// Its wash, its edge and its disc; never its text (spec 3.8).
  final Color hue;

  /// The number shown in a pill; none when null (the owner, 2026-11-18: Recap's and the Glossary's said nothing).
  final int? count;
  final String title;

  /// What it holds in words, which a screen reader says after its name.
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final name = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurfaceTitle,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
    final arrow = Icon(Icons.arrow_forward_rounded, size: 20, color: colors.onSurfaceTitle);
    final disc = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: hue, shape: BoxShape.circle),
      child: Icon(icon, size: 21, color: colors.surface),
    );
    return Semantics(
      container: true,
      button: true,
      label: '$title, $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Color.alphaBlend(hue.withValues(alpha: 0.2), colors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BazaarShapes.arch,
          side: BorderSide(color: hue.withValues(alpha: 0.7), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                disc,
                Expanded(child: name),
                if (count case final count?) _Count(count: count, hue: hue),
                arrow,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile's count in a pill edged in its hue.
class _Count extends StatelessWidget {
  const _Count({required this.count, required this.hue});

  final int count;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(99)),
        border: Border.all(color: hue),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: colors.onSurfaceTitle, fontWeight: FontWeight.w700),
      ),
    );
  }
}
