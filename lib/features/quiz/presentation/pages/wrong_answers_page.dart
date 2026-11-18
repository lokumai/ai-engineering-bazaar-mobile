import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/level_group.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
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
/// once leaves the list (the owner, 2026-11-18).
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
        const SizedBox(height: AppSpacing.md),
        if (pool == null || notes is! StudyNotesReady)
          const Center(child: CircularProgressIndicator())
        else if (wrong.isEmpty)
          Text(s.practice_wrong_none, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
        else ...[
          FilledButton.icon(
            key: WrongAnswersPage.allKey,
            onPressed: () => context.push(BazaarPaths.practiceWrongAll),
            icon: const Icon(Icons.replay_rounded),
            label: Text('${s.practice_wrong_all} (${wrong.length})'),
          ),
          for (final MapEntry(key: slug, value: keys) in levels.entries) ...[
            const SizedBox(height: AppSpacing.md),
            PracticeLevelGroup(
              position: index?.levels.indexWhere((level) => level.slug == slug) ?? -1,
              title: index?.level(slug)?.title ?? slug,
              count: s.practice_wrong_count(keys.length),
              rows: [
                for (final key in keys)
                  if (notes.of(moduleOfKey(key))?.quiz.elementAtOrNull(indexOfKey(key)) case final item?)
                    MergeSemantics(
                      key: WrongAnswersPage.rowKey(key),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpacing.md,
                          children: [
                            PracticeDisc(hue: colors.fault, icon: Icons.close_rounded),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    item.question,
                                    style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle),
                                  ),
                                  Text(
                                    _moduleLine(index, moduleOfKey(key), track, language),
                                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

/// The module [key]'s number and title in [track], as Practice's quiz rows print them.
String _moduleLine(BundleIndex? index, String key, Track track, String language) {
  final module = index?.module(key);
  if (module == null) return key;
  return '${module.number.toString().padLeft(2, '0')}  ${module.tracks[track]?.titleIn(language) ?? key}';
}
