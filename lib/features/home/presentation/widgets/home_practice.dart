import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/quiz_waiting.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_plan.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/glossary.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// Home's Practice (plan 13.2, 13.17), under the day's card with its own heading: Today's review, the glossary, and the
/// first quiz not yet taken. Wrong answers and A module in 2 minutes stay the Practice tab's own (the owner,
/// 2026-11-18). Nothing shows before a module is completed, or while the notes are being read.
class HomePractice extends StatelessWidget {
  const HomePractice({super.key, required this.track, required this.language});

  /// How many terms of the last module completed the glossary card names.
  static const termsShown = 3;

  final Track track;
  final String language;

  @override
  Widget build(BuildContext context) {
    final pool = reviewPoolOf(context, track, language);
    final notes = context.watch<StudyNotesCubit>().state;
    if (pool == null || pool.completed.isEmpty || notes is! StudyNotesReady) return const SizedBox.shrink();
    final history = context.watch<ReviewBloc>().state.history;
    final scores = context.watch<QuizScoresBloc>().state;
    final today = dayNumber(clock.now());
    final cards = pool.today(history, today).length;
    final waiting = quizWaiting(
      pool.completed,
      quizLength: (key) => notes.of(key)?.quiz.length ?? 0,
      finished: (key) => scores.of(key) != null,
      history: history,
    );
    final last = notes.of(pool.completed.last);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionRule(title: S.of(context).nav_practice),
          const SizedBox(height: 12),
          _TodayCard(cards: cards, done: history.doneOn(today) > 0),
          const SizedBox(height: AppSpacing.md),
          _GlossaryCard(
            count: glossaryOf(notes.modules, language).length,
            terms: [for (final term in last?.terms.take(termsShown) ?? const <GlossaryTerm>[]) term.name],
          ),
          if (waiting != null) ...[
            const SizedBox(height: AppSpacing.md),
            _QuizWaiting(moduleKey: waiting, track: track, language: language),
          ],
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

/// Today's review as Practice's deck in small: a leaf card with the primary edge. With cards left a tap starts them, and
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
      accent: colors.primary,
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

/// The glossary on an arch card in its Practice hue: its mark, its name, how many terms, and a few terms of the last
/// module completed as small labels, the words a reader met last; a tap opens it (plan 13.17).
class _GlossaryCard extends StatelessWidget {
  const _GlossaryCard({required this.count, required this.terms});

  final int count;
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final hue = colors.category3;
    final detail = s.practice_glossary_count(count);
    return BazaarCard(
      key: const Key('home-glossary'),
      shape: BazaarCardShape.arch,
      accent: hue,
      tint: hue,
      onTap: () => context.push(BazaarPaths.practiceGlossary),
      semanticLabel: [s.practice_glossary, detail, ...terms].join(', '),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              _Disc(hue: hue, icon: Icons.sort_by_alpha_rounded),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      s.practice_glossary,
                      style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                    ),
                    Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 20, color: colors.primary),
            ],
          ),
          if (terms.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final term in terms) _TermLabel(term: term, hue: hue)],
            ),
        ],
      ),
    );
  }
}

/// A term's name on a small raised label, its first letter in the display face, as the glossary heads its letters.
class _TermLabel extends StatelessWidget {
  const _TermLabel({required this.term, required this.hue});

  final String term;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.all(BazaarRadii.md),
        border: Border.all(color: colors.lineStrong),
      ),
      child: Text(
        term,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: displayFace(theme.textTheme.labelLarge)?.copyWith(color: colors.onSurfaceTitle),
      ),
    );
  }
}

/// "Quiz waiting": the first completed module whose quiz is not taken, after its level's key, its number and title; a
/// tap opens its quiz (plan 13.17).
class _QuizWaiting extends StatelessWidget {
  const _QuizWaiting({required this.moduleKey, required this.track, required this.language});

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
    final number = module == null ? '' : '${module.number.toString().padLeft(2, '0')}  ';
    return BazaarCard(
      key: const Key('home-quiz-waiting'),
      accent: hue,
      onTap: () => context.push(BazaarPaths.quiz(moduleKey)),
      semanticLabel: '${s.home_quiz_waiting}, $title',
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minTapTarget(theme.platform)),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            _Disc(hue: hue, icon: Icons.quiz_outlined),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      LevelKey(color: hue, size: 8),
                      Text(
                        s.home_quiz_waiting,
                        style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                      ),
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: number,
                          style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
                        ),
                        TextSpan(text: title),
                      ],
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, size: 20, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
