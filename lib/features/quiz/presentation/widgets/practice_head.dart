import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/shared/study/domain/glossary.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/brief_list_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/level_group.dart';
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

/// Practice's head (plan 13.2): the endless review as a deck of cards, its name and Start (the owner,
/// 2026-11-18: Today's review stays Home's); then Wrong answers, A module in 2 minutes and the Glossary side by side,
/// each a card washed in its hue with its mark and its count.
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

/// The endless review as the top card of a deck, two more cards' edges under it, the one card on Practice with an edge
/// of colour along its top (the owner, 2026-11-18): its name, and Start once there are [cards] to draw from; no words on what it does, its name
/// says it.
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Icon(Icons.all_inclusive_rounded, color: colors.primary, size: 26),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.practice_endless,
                    style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurfaceTitle),
                  ),
                ),
              ),
            ],
          ),
          if (ready && cards > 0) ...[
            const SizedBox(height: AppSpacing.xs),
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

/// The tiles side by side, each as tall as the tallest; one under another when the text is large.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.tiles});

  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 13;
    if (stacked) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.md, children: tiles);
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

/// One of Practice's tiles: an arch card washed in [hue], with no edge of colour along its top (the owner, 2026-11-18),
/// its mark, its count large and its name; a tap opens its page.
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

  /// Its wash and the ring of its mark; never its text (spec 3.8).
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
      tint: hue,
      onTap: onTap,
      semanticLabel: '$title, $detail',
      padding: const EdgeInsets.all(AppSpacing.md),
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
