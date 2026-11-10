import 'package:ai_engineering_bazaar/features/quiz/application/quiz_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/quiz/application/quiz_list.dart';
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
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Quiz tab at `/quiz` (plan 1AC, in place of the progress page): every module's quiz, grouped by level, each
/// opening the quiz full screen without the reader. Only For Engineers modules carry a quiz, so a For Everyone reader
/// is told where the questions come from.
///
/// Each level is an arch card in its hue, as in the catalog (owner, 2026-11-10): a tap opens its quizzes under it and a
/// second tap closes them; several levels may be open at once. The level of the next module to read in the current
/// track starts open, and what the reader opens or closes stays while the app runs ([QuizFoldCubit]).
class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  /// The key of [slug]'s level button.
  static Key levelKey(String slug) => ValueKey('quiz-level-$slug');

  /// The key of the row that opens the quiz of the module [key].
  static Key rowKey(String key) => ValueKey('quiz-row-$key');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
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
    final fold = context.watch<QuizFoldCubit>();
    final open = fold.openWith(upNext);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // No heading: the tab names the page (owner, 2026-11-10). A For Everyone reader still learns why the quizzes
        // are For Engineers ones.
        if (track != Track.engineers) ...[
          Text(s.quiz_list_engineers_only(trackName(s, Track.engineers)), style: muted),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (final level in quizLevels(index)) ...[
          _LevelCard(
            key: QuizListPage.levelKey(level.level.slug),
            level: level,
            scores: scores,
            open: open.contains(level.level.slug),
            onToggle: () => fold.toggle(level.level.slug, upNext),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// One level: its number, title and count of quizzes on an arch card in its hue, and its quizzes under it when open.
class _LevelCard extends StatelessWidget {
  const _LevelCard({super.key, required this.level, required this.scores, required this.open, required this.onToggle});

  final QuizLevel level;
  final QuizScoresState scores;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final total = level.modules.length;
    final taken = level.modules.where((module) => scores.of(module.key) != null).length;
    final count = s.quiz_list_count(total);
    final meter = s.quiz_list_taken(taken, total);
    final hue = levelHue(context, level.position);
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
                        _QuizRow(key: QuizListPage.rowKey(module.key), module: module, score: scores.of(module.key)),
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

/// One module's quiz in an open level: the question disc, the number and title with the last score as one segment
/// per question once taken, and an arrow; one button as a whole. The best score is spoken with the row and shown on
/// the results.
class _QuizRow extends StatelessWidget {
  const _QuizRow({super.key, required this.module, required this.score});

  final ModuleEntry module;

  /// The score kept on this device; null for a quiz never finished.
  final QuizScore? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final number = _number(module.number);
    final title = module.tracks[Track.engineers]!.title;
    final score = this.score;
    final line = score == null ? null : S.of(context).quiz_score_line(score.last, score.best, score.total);
    return Semantics(
      button: true,
      label: [('$number $title'), ?line].join(', '),
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
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                  child: Text(
                    '?',
                    style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(number, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle)),
                      if (score != null) _ScoreMeter(score: score, label: line!),
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

/// The last score of a quiz as one segment per question, the right ones filled: a meter, not the level's dial, and
/// no words (owner, 2026-11-10).
class _ScoreMeter extends StatelessWidget {
  const _ScoreMeter({required this.score, required this.label});

  final QuizScore score;
  final String label;

  /// The width of one segment at text scale 1.
  static const double _segment = 14;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return SizedBox(
      width: scale.scale(_segment * score.total + 4 * (score.total - 1)),
      child: SegmentMeter(done: score.last, total: score.total, color: BazaarFixedColors.success, semanticLabel: label),
    );
  }
}

/// A level's or a module's number in two digits, as the catalog prints it.
String _number(int number) => number.toString().padLeft(2, '0');
