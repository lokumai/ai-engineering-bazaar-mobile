import 'package:ai_engineering_bazaar/features/catalog/application/catalog_rows.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_cards.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/level_notes.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The level page of [track] (web `LevelCatalog`, `src/components/catalog/LevelCatalog.tsx:20-97`) in the web's default
/// Cards view (A10): the level title, the lead line, the meter text, then the catalog with this level chosen (the
/// level chips, A45, and the cards), then the level's `General notes` when it has a document.
///
/// The meter's segment gauge is drawn in the level's hue under its text, which carries it for assistive technology
/// (the gauge is `aria-hidden` on the web). The open Description is local UI state. An unknown level shows [NotFoundView].
class LevelPage extends StatefulWidget {
  const LevelPage({super.key, required this.track, required this.level});

  final Track track;

  /// The level slug from the route.
  final String level;

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  String? _openDescription;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final track = widget.track;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate mounts the router only once the content is ready.
      final state => throw StateError('The level page needs ready content, not $state'),
    };
    final entry = index.level(widget.level);
    if (entry == null) return const NotFoundView();

    final recordState = context.watch<RecordBloc>().state;
    final view = switch (recordState) {
      RecordReady(:final record) => trackView(record, track),
      RecordLoading() => null,
    };
    // `--/{total}` until the record is read, as the web's server render.
    final count = view == null ? null : categoryProgress(view, curriculumFor(index, track))[entry.slug]!;
    final meter = count == null
        ? l10n.level_completed_pending(entry.total)
        : l10n.level_completed(count.approved, count.total);
    final minutes = index.modules
        .where((module) => module.level == entry.slug)
        .fold(0, (sum, module) => sum + module.minutes);

    final rows = catalogRows(index, track, view);
    final visible = applyLevel(rows, entry.slug);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Semantics(header: true, child: Text(entry.title, style: textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          levelLeadLine(l10n, modules: entry.total, minutes: minutes),
          style: textTheme.bodyMedium,
        ),
        Text(meter, style: textTheme.bodyMedium),
        // The gauge of the meter, in the level's hue; the text above carries it, as the web's gauge is `aria-hidden`.
        if (count case final count?) ...[
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: SegmentMeter(
              done: count.approved,
              total: count.total,
              color: levelHue(context, levelPosition(index, entry.slug)),
              semanticLabel: meter,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        CatalogCards(
          track: track,
          index: index,
          rows: visible,
          openDescription: _openDescription,
          onDescription: (key) => setState(() => _openDescription = key),
        ),
        if (entry.readme case final readme?) LevelNotes(readme: readme, diagramThemes: index.diagramThemes),
      ],
    );
  }
}
