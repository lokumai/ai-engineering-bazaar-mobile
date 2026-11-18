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
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/quiz_disc.dart';
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
/// head Today's review and Wrong answers, then every module's quiz, grouped by level, each opening the quiz full screen
/// without the reader. The current track's modules are listed, each under its title in that track: a module has one
/// quiz on both tracks (web D137).
///
/// Each level is an arch card in its hue, as in the catalog (owner, 2026-11-10): a tap opens its quizzes under it and a
/// second tap closes them; several levels may be open at once. The level of the next module to read in the current
/// track starts open, and what the reader opens or closes stays while the app runs ([QuizFoldCubit]).
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
          TourTarget(
            spot: TourSpots.practiceToday,
            child: PracticeHead(index: index, track: track),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionRule(title: s.practice_quizzes),
          const SizedBox(height: AppSpacing.md),
          for (final (position, level) in quizLevels(index, track).indexed) ...[
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
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// One level: its number, title and count of quizzes on an arch card in its hue, and its quizzes under it when open.
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
    return BazaarCard(
      shape: BazaarCardShape.arch,
      accent: hue,
      tint: hue,
      padding: EdgeInsets.zero,
      child: Column(
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
                                  text: '${_number(level.position + 1)}  ',
                                  style: TextStyle(color: colors.onSurfaceMuted),
                                ),
                                TextSpan(text: level.level.title),
                              ],
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                          ),
                          Text(count, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                        ],
                      ),
                    ),
                    // The catalog's dial: how many of the level's quizzes were taken on this device.
                    CompletionDial(
                      done: taken,
                      total: total,
                      color: hue,
                      center: '$taken/$total',
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
                      for (final module in level.modules)
                        _QuizRow(
                          key: PracticePage.rowKey(module.key),
                          module: module,
                          track: track,
                          hue: hue,
                          score: scores.of(module.key),
                          latest: latestAnswers(history, module.key),
                        ),
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

/// One module's quiz in an open level: the question disc in the level's hue, or the catalog's check once every
/// question's latest answer is right; the number and title, with one segment per question once any is answered, green
/// for right and red for wrong as last answered, in the module's quiz or in Practice (the owner, 2026-11-18); and an
/// arrow. One button as a whole. A quiz finished before Practice kept answers shows its last score instead.
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

  /// The level's hue, which rings the question disc.
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
    final number = _number(module.number);
    final title = module.tracks[track]!.titleIn(context.watch<LanguageCubit>().state);
    final score = this.score;
    final answers = latest ?? (score == null ? null : [for (var i = 0; i < score.total; i++) i < score.last]);
    final right = answers?.where((answer) => answer ?? false).length ?? 0;
    final perfect = answers != null && right == answers.length;
    final line = answers == null ? null : s.practice_latest(right, answers.length);
    return Semantics(
      button: true,
      label: [('$number $title'), if (perfect) s.quiz_all_right, ?line].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(BazaarPaths.quiz(module.key)),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTapTarget(theme.platform)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                if (perfect)
                  // The catalog's completed disc: every question right as last answered.
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: BazaarFixedColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 18, color: Colors.white),
                  )
                else
                  QuizDisc(hue: hue),
                Text(number, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
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
                Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Each question's latest answer as one segment: green when right, red when wrong, the sunken track when never
/// answered. Decoration: the row says it in words.
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
          for (final (index, answer) in answers.indexed)
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

/// A level's or a module's number in two digits, as the catalog prints it.
String _number(int number) => number.toString().padLeft(2, '0');
