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
          BazaarRows(
            children: [
              for (final key in modules)
                if (index?.module(key) case final module?)
                  BazaarRow(
                    key: BriefListPage.rowKey(key),
                    onTap: () => context.push(BazaarPaths.practiceBriefOf(key)),
                    child: Row(
                      spacing: AppSpacing.md,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: levelHue(context, index!.levels.indexWhere((level) => level.slug == module.level)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            module.tracks[track]?.titleIn(language) ?? key,
                            style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
                      ],
                    ),
                  ),
            ],
          ),
      ],
    );
  }
}
