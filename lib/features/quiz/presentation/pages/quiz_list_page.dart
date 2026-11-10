import 'package:ai_engineering_bazaar/features/quiz/application/quiz_list.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Quiz tab at `/quiz` (plan 1AC, in place of the progress page): every module's quiz, grouped by level, each
/// opening the quiz full screen without the reader. Only For Engineers modules carry a quiz, so a For Everyone reader
/// is told where the questions come from.
class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

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
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Semantics(header: true, child: Text(s.quiz_list_title, style: theme.textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.sm),
        Text(s.quiz_list_lede, style: muted),
        if (track != Track.engineers) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(s.quiz_list_engineers_only(trackName(s, Track.engineers)), style: muted),
        ],
        for (final level in quizLevels(index)) ...[
          const SizedBox(height: AppSpacing.xl),
          _LevelHeading(level: level),
          const SizedBox(height: AppSpacing.sm),
          for (final module in level.modules) ...[
            _QuizRow(key: rowKey(module.key), module: module),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _LevelHeading extends StatelessWidget {
  const _LevelHeading({required this.level});

  final QuizLevel level;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        LevelKey(color: levelHue(context, level.position)),
        Flexible(
          child: Semantics(
            header: true,
            child: Text(level.level.title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ],
    );
  }
}

/// One module's quiz: the question disc, the number and title, and an arrow; one button as a whole.
class _QuizRow extends StatelessWidget {
  const _QuizRow({super.key, required this.module});

  final ModuleEntry module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final number = module.number.toString().padLeft(2, '0');
    final title = module.tracks[Track.engineers]!.title;
    return BazaarCard(
      onTap: () => context.push(BazaarPaths.quiz(module.key)),
      semanticLabel: '$number $title',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}
