import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_complete_card.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_after_row.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_daily_card.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_path.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_review_row.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Home page at `/` (the web's front door is `/`; the redesign, plan Phase 1C): the day's card (plan 11.1), the modules later in the track, the
/// row to Practice's review of the day (plan 13.2), the reader's path through the levels at a
/// glance (the offline note went to Settings, plan 12.6). The module to read now (Continue reading or Up next, plan 1BA) is in the band over the
/// navigation, under the thumb (plan 10.4), so Home has no card at its head unless every module is completed. Home says what to read now (plan 1P); the levels, their modules
/// and their completion in full live on the catalog (plan 1AB).
///
/// Home is a page of neither track, so it shows the remembered track ([TrackCubit]); its switch changes that track
/// only. The app gate mounts the router only once the content and the record are ready.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.dailyFrame});

  /// What presents the day's card at the page's head, which the app fills with the Apprentice (plan 11.2); the card
  /// alone when null.
  final DailyCardFrame? dailyFrame;

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
    final places = switch (context.watch<ReadingPlacesBloc>().state) {
      ReadingPlacesReady(:final places) => places,
      ReadingPlacesLoading() => const <String, ReadingPlace>{},
    };
    final language = context.watch<LanguageCubit>().state;
    final overview = homeOverview(index, track, record, places: places, language: language);

    // The notes give the review row its cards; they are read once Home opens.
    return StudyNotesLoader(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + FloatingRoom.of(context)),
        children: [
          if (notice != null) ...[ContentNoticeBanner(notice: notice), const SizedBox(height: 16)],
          // The day's card, a section of a module to read today (plan 11.1).
          HomeDailyCard(frame: dailyFrame),
          // Practice's review of the day under its own heading, after the day's card (plan 13.2, the owner 2026-11-18);
          // none when it has no card today.
          HomeReviewRow(track: track, language: language),
          // The module to read now is in the band over the navigation, under the thumb (plan 10.4); with none left, the
          // card says the track is completed.
          if (overview.next == null) ...[HomeCompleteCard(track: track), const SizedBox(height: 26)],
          if (overview.after.isNotEmpty) ...[
            TourTarget(
              spot: TourSpots.homeAfter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionRule(title: s.home_after),
                  const SizedBox(height: 12),
                  BazaarRows(
                    children: [
                      for (final entry in overview.after)
                        HomeAfterRow(
                          entry: entry,
                          onTap: () => context.push(BazaarPaths.module(track, entry.module.key)),
                        ),
                    ],
                  ),
                ],
              ),
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
        ],
      ),
    );
  }
}
