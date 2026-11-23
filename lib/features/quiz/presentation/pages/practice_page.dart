import 'package:ai_engineering_bazaar/features/quiz/application/quiz_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/quiz/application/quiz_list.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/practice_head.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/quiz_waiting.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Practice tab at `/practice` (plan 13.2), once the Quiz tab (plan 1AC): one place to go over what was read. At its
/// head the endless review and three tiles (PracticeHead), then every module's quiz, grouped by level, each opening the
/// quiz full screen without the reader. The current track's modules are listed, each under its title in that track: a
/// module has one quiz on both tracks (web D137).
///
/// Each level is a row on the page's ground with its key in its hue, as Later on's rows are, not a card (the owner,
/// 2026-11-18): a tap opens its quizzes under it and a second tap closes them; several levels may be open at once. The
/// level of the next module to read in the current track starts open, and what the reader opens or closes stays while
/// the app runs ([QuizFoldCubit]).
class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  /// The key of [slug]'s level button.
  static Key levelKey(String slug) => ValueKey('quiz-level-$slug');

  /// The key of the row that opens the quiz of the module [key].
  static Key rowKey(String key) => ValueKey('quiz-row-$key');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate mounts the router only once the content is ready.
      final state => throw StateError('The quiz list needs ready content, not $state'),
    };
    final track = context.watch<TrackCubit>().state;
    final next = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => nextUnsigned(trackView(record, track), curriculumFor(index, track)),
      RecordLoading() => null,
    };
    final upNext = next == null ? null : index.module(next)?.level;
    final scores = context.watch<QuizScoresBloc>().state;
    final history = context.watch<ReviewBloc>().state.history;
    final fold = context.watch<QuizFoldCubit>();
    final open = fold.openWith(upNext);
    return StudyNotesLoader(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg) + EdgeInsets.only(bottom: FloatingRoom.of(context)),
        children: [
          // The page's name at the head of its content, which scrolls away with it; the bar stays empty on the tabs
          // (review round 4), and without it Practice and the catalog open alike.
          SectionRule(title: s.nav_practice),
          const SizedBox(height: AppSpacing.md),
          // The tour's first stop rings the endless review alone (PracticeHead).
          PracticeHead(track: track),
          const SizedBox(height: AppSpacing.xl),
          SectionRule(title: s.practice_quizzes),
          const SizedBox(height: AppSpacing.md),
          for (final (position, level) in quizLevels(index, track).indexed) ...[
            // A hairline between each two levels, rows on the page's ground (the owner, 2026-11-18).
            if (position > 0) const Divider(height: 1, thickness: 0.5),
            // The Apprentice's tour points at the first level (plan 11.3).
            TourTarget(
              spot: position == 0 ? TourSpots.quizLevel : '${TourSpots.quizLevel}.$position',
              child: _LevelCard(
                key: PracticePage.levelKey(level.level.slug),
                level: level,
                track: track,
                scores: scores,
                history: history,
                open: open.contains(level.level.slug),
                onToggle: () => fold.toggle(level.level.slug, upNext),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One level as a row: its key in its hue, title and count of quizzes, the dial of quizzes taken and the fold's
/// chevron; its quizzes under it when open.
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    super.key,
    required this.level,
    required this.track,
    required this.scores,
    required this.history,
    required this.open,
    required this.onToggle,
  });

  final QuizLevel level;

  /// The track whose titles the rows show.
  final Track track;
  final QuizScoresState scores;

  /// Practice's history, which holds each question's latest answer.
  final ReviewHistory history;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final total = level.modules.length;
    // A quiz finished here, or one answered in Practice: its row shows segments, so the dial counts it.
    final taken = level.modules
        .where((module) => scores.of(module.key) != null || latestAnswers(history, module.key) != null)
        .length;
    final count = s.quiz_list_count(total);
    final meter = s.quiz_list_taken(taken, total);
    final hue = levelHue(context, level.position);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: '${level.level.title}, $count, $meter',
          excludeSemantics: true,
          onTap: onToggle,
          child: InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.all(BazaarRadii.md),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, AppSpacing.md, 0, AppSpacing.md),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  LevelKey(color: hue, size: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          level.level.title,
                          style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                        ),
                        Text(count, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  // The catalog's dial: how many of the level's quizzes were taken on this device.
                  CompletionDial(done: taken, total: total, color: hue, center: '$taken/$total', semanticLabel: meter),
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
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final module in level.modules)
                        _QuizRow(
                          key: PracticePage.rowKey(module.key),
                          module: module,
                          track: track,
                          hue: hue,
                          score: scores.of(module.key),
                          latest: latestAnswers(history, module.key),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// One module's quiz in an open level, with no mark before it (the owner, 2026-11-18): the title, with no number, with
/// one segment per question once any is answered, green for right and red for wrong as last answered, in the module's
/// quiz or in Practice (the owner, 2026-11-18); where it stands at its end; and an arrow. One button as a whole. A quiz finished before Practice kept answers shows its last score instead.
class _QuizRow extends StatelessWidget {
  const _QuizRow({
    super.key,
    required this.module,
    required this.track,
    required this.hue,
    required this.score,
    required this.latest,
  });

  final ModuleEntry module;
  final Track track;

  /// The level's hue, which rings a quiz not yet taken.
  final Color hue;

  /// The score kept on this device; null for a quiz never finished.
  final QuizScore? score;

  /// Each question's latest answer, null for one never answered; null when none is answered.
  final List<bool?>? latest;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final title = module.tracks[track]!.titleIn(context.watch<LanguageCubit>().state);
    final score = this.score;
    final answers = latest ?? (score == null ? null : [for (var i = 0; i < score.total; i++) i < score.last]);
    final right = answers?.where((answer) => answer ?? false).length ?? 0;
    final perfect = answers != null && right == answers.length;
    final line = answers == null ? null : s.practice_latest(right, answers.length);
    void open() => context.push(BazaarPaths.quiz(module.key));
    // The tap is the node's own: excludeSemantics drops the InkWell's (review 8, finding 4).
    return Semantics(
      button: true,
      label: [title, if (perfect) s.quiz_all_right, ?line].join(', '),
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        onTap: open,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTapTarget(theme.platform)),
          child: Padding(
            // Under the level's title, past its key.
            padding: const EdgeInsetsDirectional.fromSTEB(20, AppSpacing.sm, 0, AppSpacing.sm),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle)),
                      if (answers != null) _AnswerMeter(answers: answers),
                    ],
                  ),
                ),
                _QuizStatus(answers: answers, right: right, hue: hue),
                Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a quiz stands, at its row's end (the owner, 2026-11-18): an empty ring in the level's [hue] while none of its
/// questions is answered, the right ones out of all once any is, and the catalog's green check once every one is right.
/// Decoration: the row says it in words.
class _QuizStatus extends StatelessWidget {
  const _QuizStatus({required this.answers, required this.right, required this.hue});

  final List<bool?>? answers;
  final int right;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final answers = this.answers;
    return ExcludeSemantics(
      child: switch (answers) {
        null => Container(
          key: const Key('quiz-status-new'),
          width: 20,
          height: 20,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: hue, width: 2),
          ),
        ),
        _ when right == answers.length => const Icon(
          Icons.check_circle,
          key: Key('quiz-status-perfect'),
          size: 24,
          color: BazaarFixedColors.success,
        ),
        _ => Text(
          '$right/${answers.length}',
          key: const Key('quiz-status-count'),
          style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceTitle, fontWeight: FontWeight.w700),
        ),
      },
    );
  }
}

/// The latest answers counted from the start, as a meter: a green segment for each right, then a red one for each
/// wrong, then the sunken track for each never answered, whichever questions they were (the owner, 2026-11-18: a
/// question answered in a review lit its own place, in the middle). Decoration: the row says it in words.
class _AnswerMeter extends StatelessWidget {
  const _AnswerMeter({required this.answers});

  final List<bool?> answers;

  /// The width of one segment at text scale 1.
  static const double _segment = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final scale = MediaQuery.textScalerOf(context);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final (index, answer) in [
            ...answers.where((answer) => answer == true),
            ...answers.where((answer) => answer == false),
            ...answers.where((answer) => answer == null),
          ].indexed)
            Container(
              // One key per question, which says its answer: answer-<index>-right, -wrong or -none.
              key: ValueKey(
                'answer-$index-${switch (answer) {
                  true => 'right',
                  false => 'wrong',
                  null => 'none',
                }}',
              ),
              width: scale.scale(_segment),
              height: 6,
              decoration: BoxDecoration(
                color: switch (answer) {
                  true => BazaarFixedColors.success,
                  false => colors.fault,
                  null => colors.surfaceSunken,
                },
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
            ),
        ],
      ),
    );
  }
}
