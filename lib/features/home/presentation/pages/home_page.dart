import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_continue_card.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_level_row.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_offline_note.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Home page at `/` (the web's front door is `/`; the redesign, plan Phase 1C): the track switch, the continue
/// card, the levels with their completion, and the offline note.
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
    final overview = homeOverview(index, track, record);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: context.bazaarColors.onSurfaceMuted);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        if (notice != null) ...[ContentNoticeBanner(notice: notice), const SizedBox(height: 16)],
        const TrackSwitch(),
        const SizedBox(height: 22),
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
        SectionRule(title: s.home_levels),
        const SizedBox(height: 12),
        for (final level in overview.levels) ...[
          HomeLevelRow(
            level: level,
            // Over Home, as a catalog section opens a level page.
            onTap: () => context.push(BazaarPaths.level(track, level.level.slug)),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        const HomeOfflineNote(),
      ],
    );
  }
}
