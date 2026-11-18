import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/quiz_waiting.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// Home's Practice (plan 13.2, 13.17), under the day's card with its own heading: Today's review on its card, then the
/// first quiz not yet taken and the glossary as rows. Wrong answers and A module in 2 minutes stay the Practice tab's
/// own (the owner, 2026-11-18). It shows from the first launch, drawing on the first module before any is completed;
/// nothing while the notes are being read.
class HomePractice extends StatelessWidget {
  const HomePractice({super.key, required this.track, required this.language});

  final Track track;
  final String language;

  @override
  Widget build(BuildContext context) {
    final pool = reviewPoolOf(context, track, language);
    final notes = context.watch<StudyNotesCubit>().state;
    if (pool == null || pool.studied.isEmpty || notes is! StudyNotesReady) return const SizedBox.shrink();
    final history = context.watch<ReviewBloc>().state.history;
    final scores = context.watch<QuizScoresBloc>().state;
    final today = dayNumber(clock.now());
    final cards = pool.today(history, today).length;
    final waiting = quizWaiting(
      pool.studied,
      quizLength: (key) => notes.of(key)?.quiz.length ?? 0,
      finished: (key) => scores.of(key) != null,
      history: history,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionRule(title: S.of(context).nav_practice),
          const SizedBox(height: 12),
          _TodayCard(cards: cards, done: history.doneOn(today) > 0),
          const SizedBox(height: AppSpacing.sm),
          // The rest as rows on the page's ground, as Later on's: one card in the section, not a box for each part
          // (the owner, 2026-11-18).
          BazaarRows(
            children: [
              if (waiting != null) _QuizWaitingRow(moduleKey: waiting, track: track, language: language),
              const _GlossaryRow(),
            ],
          ),
        ],
      ),
    );
  }
}

/// A round mark in [hue] with [icon], as Practice draws its tiles'.
class _Disc extends StatelessWidget {
  const _Disc({required this.hue, required this.icon});

  final Color hue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Color.alphaBlend(hue.withValues(alpha: 0.12), colors.surface),
        shape: BoxShape.circle,
        border: Border.all(color: hue, width: 2),
      ),
      child: Icon(icon, size: 18, color: colors.onSurfaceTitle),
    );
  }
}

/// Today's review on a leaf card, the section's one card, with no edge in a hue (the owner, 2026-11-18). With cards left a tap starts them, and
/// the results lead back to Home; once the day's are done, or with none, it says so and stays (plan 13.17).
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.cards, required this.done});

  final int cards;

  /// Whether a card was answered today.
  final bool done;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final open = cards > 0;
    final (title, detail) = open
        ? (s.practice_today, s.practice_today_cards(cards, reviewMinutes(cards)))
        : done
        ? (s.practice_today_done, s.practice_today_done_lede)
        : (s.practice_today_none, s.practice_today_none_lede);
    return BazaarCard(
      key: open ? const Key('home-review') : const Key('home-review-rest'),
      shape: BazaarCardShape.leaf,
      // Its results lead back to Home, where it was opened (the owner, 2026-11-18).
      onTap: open ? () => context.push(BazaarPaths.practiceReviewFromHome) : null,
      semanticLabel: '$title, $detail',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          _Disc(hue: colors.primary, icon: open ? Icons.school_rounded : Icons.check_rounded),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          if (open) Icon(Icons.arrow_forward, size: 20, color: colors.primary),
        ],
      ),
    );
  }
}

/// The glossary as a row on the page's ground, as Later on's (the owner, 2026-11-18: not every part of Home in a box;
/// no terms and no count under it): its purple mark and its name; a tap opens it (plan 13.17).
class _GlossaryRow extends StatelessWidget {
  const _GlossaryRow();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return BazaarRow(
      key: const Key('home-glossary'),
      onTap: () => context.push(BazaarPaths.practiceGlossary),
      semanticLabel: s.practice_glossary,
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(Icons.sort_by_alpha_rounded, size: 22, color: colors.category3),
          Expanded(
            child: Text(
              s.practice_glossary,
              style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
            ),
          ),
          ExcludeSemantics(child: Icon(Icons.chevron_right, color: colors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

/// "Quiz waiting" as a row on the page's ground, drawn as Later on's: the first module studied whose quiz is not taken,
/// the quiz mark in its level's hue in place of a number (the owner, 2026-11-18), its title, and under it "Quiz
/// waiting"; a tap opens its quiz (plan 13.17).
class _QuizWaitingRow extends StatelessWidget {
  const _QuizWaitingRow({required this.moduleKey, required this.track, required this.language});

  final String moduleKey;
  final Track track;
  final String language;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final module = index?.module(moduleKey);
    final position = index?.levels.indexWhere((level) => level.slug == module?.level) ?? -1;
    final hue = position < 0 ? colors.primary : levelHue(context, position);
    final title = module?.tracks[track]?.titleIn(language) ?? moduleKey;
    return BazaarRow(
      key: const Key('home-quiz-waiting'),
      onTap: () => context.push(BazaarPaths.quiz(moduleKey)),
      semanticLabel: '${s.home_quiz_waiting}, $title',
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(Icons.quiz_outlined, size: 22, color: hue),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                Text(s.home_quiz_waiting, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          ExcludeSemantics(child: Icon(Icons.chevron_right, color: colors.onSurfaceMuted)),
        ],
      ),
    );
  }
}
