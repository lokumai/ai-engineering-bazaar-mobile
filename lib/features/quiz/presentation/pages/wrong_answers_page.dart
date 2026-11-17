import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// Wrong answers at `/practice/wrong` (plan 13.4): every question answered wrong, in a module's quiz or in Practice,
/// grouped by level, each under its module's title; Answer them all asks them full screen. A question answered right
/// twice in a row leaves the list.
class WrongAnswersPage extends StatelessWidget {
  const WrongAnswersPage({super.key});

  /// The key of Answer them all.
  static const allKey = ValueKey('wrong-answer-all');

  /// The key of the row of the question [key].
  static Key rowKey(String key) => ValueKey('wrong-$key');

  @override
  Widget build(BuildContext context) {
    return const StudyNotesLoader(child: Scaffold(body: _WrongAnswers()));
  }
}

class _WrongAnswers extends StatelessWidget {
  const _WrongAnswers();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final pool = reviewPoolOf(context, track, language);
    final notes = context.watch<StudyNotesCubit>().state;
    final wrong = pool?.wrong(context.watch<ReviewBloc>().state.history) ?? const <String>[];
    final levels = <String, List<String>>{};
    for (final key in wrong) {
      levels.putIfAbsent(moduleOfKey(key).split('/').first, () => []).add(key);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg) + EdgeInsets.only(bottom: FloatingRoom.of(context)),
      children: [
        SectionRule(title: s.practice_wrong),
        const SizedBox(height: AppSpacing.sm),
        Text(s.practice_wrong_lede, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
        const SizedBox(height: AppSpacing.md),
        if (pool == null || notes is! StudyNotesReady)
          const Center(child: CircularProgressIndicator())
        else if (wrong.isEmpty)
          Text(s.practice_wrong_none, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
        else ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              key: WrongAnswersPage.allKey,
              onPressed: () => context.push(BazaarPaths.practiceWrongAll),
              child: Text(s.practice_wrong_all),
            ),
          ),
          for (final MapEntry(key: slug, value: keys) in levels.entries) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              spacing: AppSpacing.sm,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: levelHue(context, index?.levels.indexWhere((level) => level.slug == slug) ?? 0),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    index?.level(slug)?.title ?? slug,
                    style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            BazaarRows(
              children: [
                for (final key in keys)
                  if (notes.of(moduleOfKey(key))?.quiz.elementAtOrNull(indexOfKey(key)) case final item?)
                    BazaarRow(
                      key: WrongAnswersPage.rowKey(key),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(item.question, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface)),
                          Text(
                            index?.module(moduleOfKey(key))?.tracks[track]?.titleIn(language) ?? moduleOfKey(key),
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
