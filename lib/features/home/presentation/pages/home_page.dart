import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_continue_card.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_after_row.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_offline_note.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_path.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_practice_row.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Home page at `/` (the web's front door is `/`; the redesign, plan Phase 1C): the track label, the continue
/// card, the modules after it, the quizzes of the modules completed last to practise again (plan 1AD), the reader's path
/// through the levels at a glance, and the offline note. Home says what to read now (plan 1P); the levels, their modules
/// and their completion in full live on the catalog (plan 1AB).
///
/// Home is a page of neither track, so it shows the remembered track ([TrackCubit]); its switch changes that track
/// only. The app gate mounts the router only once the content and the record are ready.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (index, notice) = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index, :final notice) => (index, notice),
      final state => throw StateError('Home needs ready content, not $state'),
    };
    final record = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => record,
      final state => throw StateError('Home needs a ready record, not $state'),
    };
    final track = context.watch<TrackCubit>().state;
    final scores = switch (context.watch<QuizScoresBloc>().state) {
      QuizScoresReady(:final scores) => scores,
      QuizScoresLoading() => const <String, QuizScore>{},
    };
    final overview = homeOverview(index, track, record, scores);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: context.bazaarColors.onSurfaceMuted);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        if (notice != null) ...[ContentNoticeBanner(notice: notice), const SizedBox(height: 16)],
        // Shown in capitals as the mockup's label; read as written.
        Semantics(
          header: true,
          label: s.home_up_next,
          excludeSemantics: true,
          child: Text(s.home_up_next.toUpperCase(), style: labelStyle),
        ),
        const SizedBox(height: 12),
        HomeContinueCard(track: track, next: overview.next),
        const SizedBox(height: 26),
        if (overview.after.isNotEmpty) ...[
          SectionRule(title: s.home_after),
          const SizedBox(height: 12),
          BazaarRows(
            children: [
              for (final entry in overview.after)
                HomeAfterRow(entry: entry, onTap: () => context.push(BazaarPaths.module(track, entry.module.key))),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (overview.practice.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionRule(title: s.home_practice),
          const SizedBox(height: 8),
          Text(
            s.home_practice_lede,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.bazaarColors.onSurfaceMuted),
          ),
          const SizedBox(height: 12),
          BazaarRows(
            children: [
              for (final entry in overview.practice)
                HomePracticeRow(
                  key: ValueKey('home-practice-${entry.module.key}'),
                  entry: entry,
                  onTap: () => context.push(BazaarPaths.quiz(entry.module.key)),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            // The Catalog tab's page, as the tab opens it.
            onPressed: () => context.go(BazaarPaths.catalog(track)),
            child: Text(s.home_see_catalog),
          ),
        ),
        if (overview.levels.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionRule(title: s.home_path),
          const SizedBox(height: 14),
          HomePath(levels: overview.levels),
        ],
        const SizedBox(height: 22),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: 4),
        const HomeOfflineNote(),
      ],
    );
  }
}
