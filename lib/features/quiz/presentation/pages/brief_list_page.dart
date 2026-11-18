import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/level_group.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// The completed modules that have a Summary or Key Terms, in the course's order, from the [notes] and the review pool.
List<String> briefModules(List<String> completed, StudyNotesReady notes) => [
  for (final key in completed)
    if (notes.of(key) case final module? when module.summary.isNotEmpty || module.terms.isNotEmpty) key,
];

/// A module in 2 minutes at `/practice/brief` (plan 13.7): the completed modules, each opening its cards full screen.
class BriefListPage extends StatelessWidget {
  const BriefListPage({super.key});

  /// The key of the module [key]'s row.
  static Key rowKey(String key) => ValueKey('brief-$key');

  @override
  Widget build(BuildContext context) {
    return const StudyNotesLoader(child: Scaffold(body: _BriefList()));
  }
}

class _BriefList extends StatelessWidget {
  const _BriefList();

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
    final modules = pool == null || notes is! StudyNotesReady ? null : briefModules(pool.completed, notes);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg) + EdgeInsets.only(bottom: FloatingRoom.of(context)),
      children: [
        SectionRule(title: s.practice_brief),
        const SizedBox(height: AppSpacing.sm),
        Text(s.practice_brief_lede, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
        const SizedBox(height: AppSpacing.md),
        if (modules == null)
          const Center(child: CircularProgressIndicator())
        else if (modules.isEmpty)
          Text(s.practice_brief_count(0), style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
        else
          for (final MapEntry(key: slug, value: keys) in _byLevel(modules).entries) ...[
            PracticeLevelGroup(
              position: index?.levels.indexWhere((level) => level.slug == slug) ?? -1,
              title: index?.level(slug)?.title ?? slug,
              count: s.level_module_count(keys.length),
              rows: [
                for (final key in keys)
                  if (index?.module(key) case final module?)
                    Semantics(
                      key: BriefListPage.rowKey(key),
                      button: true,
                      child: InkWell(
                        onTap: () => context.push(BazaarPaths.practiceBriefOf(key)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: Row(
                            spacing: AppSpacing.md,
                            children: [
                              const PracticeDisc(hue: BazaarFixedColors.caution, icon: Icons.timer_outlined),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    Text(
                                      module.tracks[track]?.titleIn(language) ?? key,
                                      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle),
                                    ),
                                    Text(
                                      [
                                        module.number.toString().padLeft(2, '0'),
                                        if ((notes as StudyNotesReady).of(key) case final brief?
                                            when brief.terms.isNotEmpty)
                                          s.practice_glossary_count(brief.terms.length),
                                      ].join('  ·  '),
                                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// [keys] by their level's slug, each level in the order its first module comes.
Map<String, List<String>> _byLevel(List<String> keys) {
  final levels = <String, List<String>>{};
  for (final key in keys) {
    levels.putIfAbsent(key.split('/').first, () => []).add(key);
  }
  return levels;
}
