import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/level_card.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/progress_legend.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The body of the progress page (web `/profile/`, A8): the title, the [aboveTabs] slot, the stats and the panel of
/// level cards and legend of the current track (web `CourseCompletion.tsx:140-294`), then the [belowCards] slot.
///
/// The web shows a tab per track; the app shows the current track only, since the track is chosen once and changed in
/// Settings (plan 1U).
class ProgressView extends StatelessWidget {
  const ProgressView({super.key, required this.index, this.aboveTabs, this.belowCards});

  final BundleIndex index;

  /// Drawn under the title (the quarantine notice, Task 13.3).
  final Widget? aboveTabs;

  /// Drawn under the panel (the data line, Task 13.3).
  final Widget? belowCards;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final shown = context.watch<TrackCubit>().state;
    final info = index.tracks.firstWhere((info) => info.track == shown, orElse: () => index.tracks.first);
    final record = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => record,
      RecordLoading() => null,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(s.progress_title, style: theme.textTheme.headlineSmall)),
          const SizedBox(height: AppSpacing.lg),
          if (aboveTabs case final aboveTabs?) ...[aboveTabs, const SizedBox(height: AppSpacing.lg)],
          if (record != null) ...[
            _Stats(
              completed: signedCount(trackView(record, info.track), curriculumFor(index, info.track)).signed,
              days: record.days.length,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _Panel(key: Key('progress_panel_${info.track.id}'), info: info, index: index, record: record),
          if (belowCards case final belowCards?) ...[const SizedBox(height: AppSpacing.xl), belowCards],
        ],
      ),
    );
  }
}

/// The stats the record carries (the redesign, plan Phase 1G): the modules completed in the shown track and the days
/// on which anything was written (the record's `days`), each a number over its label, read as one line.
class _Stats extends StatelessWidget {
  const _Stats({required this.completed, required this.days});

  final int completed;
  final int days;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Expanded(
          child: _Stat(value: completed, label: s.progress_stat_completed(completed)),
        ),
        Expanded(
          child: _Stat(value: days, label: s.progress_stat_days(days)),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: BazaarCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text('$value', style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

/// One track's panel: a heading for assistive technology only, one card per level in index order, then the legend.
class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.info, required this.index, required this.record});

  final TrackInfo info;
  final BundleIndex index;

  /// Null while the record loads.
  final RecordData? record;

  @override
  Widget build(BuildContext context) {
    final track = info.track;
    final curriculum = curriculumFor(index, track);
    final counts = switch (record) {
      final record? => categoryProgress(trackView(record, track), curriculum),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        // The web's screen-reader-only `h2` (`page.tsx:71-73`).
        Semantics(
          header: true,
          label: S.of(context).progress_every_module(trackName(S.of(context), info.track)),
          child: const SizedBox(height: 1, width: double.infinity),
        ),
        for (final (position, level) in index.levels.indexed)
          LevelCard(
            position: position,
            level: level,
            track: track,
            index: index,
            facts: [
              for (final fact in curriculum.modules)
                if (fact.level == level.slug) fact,
            ]..sort((a, b) => a.number.compareTo(b.number)),
            count: counts?[level.slug],
            record: record,
          ),
        const ProgressLegend(),
      ],
    );
  }
}
