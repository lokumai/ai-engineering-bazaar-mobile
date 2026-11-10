import 'package:ai_engineering_bazaar/features/quiz/application/quiz_list.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
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
/// second tap closes them; several levels may be open at once.
class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  /// The key of [slug]'s level button.
  static Key levelKey(String slug) => ValueKey('quiz-level-$slug');

  /// The key of the row that opens the quiz of the module [key].
  static Key rowKey(String key) => ValueKey('quiz-row-$key');

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  final _open = <String>{};

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
        const SizedBox(height: AppSpacing.lg),
        for (final level in quizLevels(index)) ...[
          _LevelCard(
            key: QuizListPage.levelKey(level.level.slug),
            level: level,
            open: _open.contains(level.level.slug),
            onToggle: () => setState(
              () => _open.contains(level.level.slug) ? _open.remove(level.level.slug) : _open.add(level.level.slug),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// One level: its number, title and count of quizzes on an arch card in its hue, and its quizzes under it when open.
class _LevelCard extends StatelessWidget {
  const _LevelCard({super.key, required this.level, required this.open, required this.onToggle});

  final QuizLevel level;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final count = s.quiz_list_count(level.modules.length);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold;
    return BazaarCard(
      shape: BazaarCardShape.arch,
      accent: levelHue(context, level.position),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: '${level.level.title}, $count',
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
                        _QuizRow(key: QuizListPage.rowKey(module.key), module: module),
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

/// One module's quiz in an open level: the question disc, the number and title, and an arrow; one button as a whole.
class _QuizRow extends StatelessWidget {
  const _QuizRow({super.key, required this.module});

  final ModuleEntry module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final number = _number(module.number);
    final title = module.tracks[Track.engineers]!.title;
    return Semantics(
      button: true,
      label: '$number $title',
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
                  child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle)),
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

/// A level's or a module's number in two digits, as the catalog prints it.
String _number(int number) => number.toString().padLeft(2, '0');
