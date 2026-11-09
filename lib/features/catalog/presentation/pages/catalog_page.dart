import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_filter_bar.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/track/track_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The catalog root of [track] (web `/sheets/` and `/everyone/sheets/`) in the web's default Overview view (A10): the
/// title, the level chips, then the overview.
///
/// The catalog has no bloc of its own: the rows are a pure function, and the Level filter is the route: its chips open
/// a level page.
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
    final view = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => trackView(record, track),
      RecordLoading() => null,
    };
    final rows = catalogRows(index, track, view);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const TrackSwitch(),
        const SizedBox(height: AppSpacing.lg),
        Semantics(header: true, child: Text(l10n.catalog_title, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.lg),
        CatalogFilterBar(index: index, track: track, levels: levelsOf(index, rows), level: null),
        const SizedBox(height: AppSpacing.xl),
        CatalogOverview(track: track, index: index, rows: rows),
      ],
    );
  }
}
