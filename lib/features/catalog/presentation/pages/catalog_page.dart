import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
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
/// title, then the levels, each opening its modules.
///
/// The catalog has no bloc of its own: the rows are a pure function, and which levels are open is the overview's own
/// state.
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
        Semantics(header: true, child: Text(l10n.catalog_title, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.lg),
        CatalogOverview(track: track, index: index, rows: rows),
      ],
    );
  }
}
