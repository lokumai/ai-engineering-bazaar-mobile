import 'dart:async';

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_query_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_legend.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_search.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The catalog root of [track] (web `/sheets/` and `/everyone/sheets/`) in the web's default Overview view (A10), with
/// the reader's progress in it (plan 1AB: the progress page is gone): no heading, as the tab names it (owner,
/// 2026-11-10), then the levels with
/// their dials, each opening its modules with their completion marks, then the legend of the marks. A search field heads
/// it (plan 7.1): while it holds words, the hits take the place of the levels.
///
/// The catalog has no bloc of its own: the rows are a pure function, and which levels are open is [CatalogFoldCubit]'s,
/// starting with the level of the next module to read.
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate mounts the router only once the content is ready.
      final state => throw StateError('The catalog needs ready content, not $state'),
    };
    final record = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => record,
      RecordLoading() => null,
    };
    final view = record == null ? null : trackView(record, track);
    final curriculum = curriculumFor(index, track);
    final language = context.watch<LanguageCubit>().state;
    final rows = catalogRows(index, track, view, language: language);
    final next = view == null ? null : nextUnsigned(view, curriculum);
    return BlocProvider(
      // A new search for another track or language: its index holds one of each.
      key: ValueKey((track, language)),
      // The words kept from the last time the catalog was shown are searched again, so a tab left and come back to
      // finds its search, and a new track or language searches them in its own text.
      create: (context) {
        final cubit = CatalogSearchCubit(
          repository: context.read<IContentRepository>(),
          bundle: index,
          track: track,
          language: language,
        );
        final kept = context.read<CatalogQueryCubit>().state;
        if (kept.trim().isNotEmpty) unawaited(cubit.search(kept));
        return cubit;
      },
      child: BlocSelector<CatalogSearchCubit, CatalogSearchState, bool>(
        selector: (state) => state.active,
        builder: (context, searching) => ListView(
          // A drag through the hits puts the keyboard away, so it does not hide them.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg) + EdgeInsets.only(bottom: FloatingRoom.of(context)),
          children: [
            // The page's name at the head of its content, which scrolls away with it; the bar stays empty on the tabs
            // (review round 4), and without it the catalog and the Quiz tab open alike.
            SectionRule(title: S.of(context).nav_catalog),
            const SizedBox(height: AppSpacing.md),
            const CatalogSearchField(),
            const SizedBox(height: AppSpacing.lg),
            if (searching)
              CatalogSearchResults(track: track)
            else ...[
              CatalogOverview(
                track: track,
                index: index,
                rows: rows,
                counts: view == null ? null : categoryProgress(view, curriculum),
                upNext: next == null ? null : index.module(next)?.level,
              ),
              const SizedBox(height: AppSpacing.xl),
              const CatalogLegend(),
            ],
          ],
        ),
      ),
    );
  }
}
