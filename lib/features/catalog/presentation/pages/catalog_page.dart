import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_legend.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_stats.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The catalog root of [track] (web `/sheets/` and `/everyone/sheets/`) in the web's default Overview view (A10), with
/// the reader's progress in it (plan 1AB: the progress page is gone): the title, the stats of the track, the levels with
/// their dials, each opening its modules with their completion marks, then the legend of the marks.
///
/// The catalog has no bloc of its own: the rows are a pure function, and which levels are open is [CatalogFoldCubit]'s,
/// starting with the level of the next module to read.
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
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
    final rows = catalogRows(index, track, view);
    final next = view == null ? null : nextUnsigned(view, curriculum);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Semantics(header: true, child: Text(l10n.catalog_title, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.lg),
        if (record != null && view != null) ...[
          CatalogStats(completed: signedCount(view, curriculum).signed, days: record.days.length),
          const SizedBox(height: AppSpacing.lg),
        ],
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
    );
  }
}
