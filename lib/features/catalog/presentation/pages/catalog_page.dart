import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_filter_bar.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_no_match.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The catalog root of [track] (web `/sheets/` and `/everyone/sheets/`) in the web's default Overview view (A10): the
/// title, the filter bar, then the overview, or the empty state when the filters keep no module.
///
/// The catalog has no bloc of its own: the rows and filters are pure functions, and the Status filter is local UI
/// state. The Level filter is the route: its chips open a level page.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.track});

  final Track track;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  StatusFilter _status = StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate mounts the router only once the content is ready.
      final state => throw StateError('The catalog needs ready content, not $state'),
    };
    final view = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => trackView(record, widget.track),
      RecordLoading() => null,
    };
    final rows = catalogRows(index, widget.track, view);
    final visible = applyStatus(rows, _status);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Semantics(header: true, child: Text(l10n.catalog_title, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.lg),
        CatalogFilterBar(
          track: widget.track,
          levels: levelsOf(index, rows),
          level: null,
          status: _status,
          onStatus: (status) => setState(() => _status = status),
          visible: visible.length,
          total: rows.length,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (visible.isEmpty)
          CatalogNoMatch(total: rows.length, onShowAll: () => setState(() => _status = StatusFilter.all))
        else
          CatalogOverview(track: widget.track, index: index, rows: visible),
      ],
    );
  }
}
