import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/catalog/application/topic_chips.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// A few terms as chips under the empty search field (plan 13.10): a chip opens the term in Practice's glossary, not a
/// search. Nothing shows while the notes are being read, or when the track has no terms.
class TopicChipsRow extends StatelessWidget {
  const TopicChipsRow({super.key, required this.track});

  final Track track;

  /// The key of the chip of the term [termKey].
  static Key chipKey(String termKey) => ValueKey('topic-$termKey');

  @override
  Widget build(BuildContext context) => StudyNotesLoader(child: _Chips(track: track));
}

class _Chips extends StatelessWidget {
  const _Chips({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final notes = switch (context.watch<StudyNotesCubit>().state) {
      final StudyNotesReady ready when ready.track == track && ready.language == language => ready,
      _ => null,
    };
    if (notes == null) return const SizedBox.shrink();
    final record = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => record,
      RecordLoading() => RecordData.empty,
    };
    final places = switch (context.watch<ReadingPlacesBloc>().state) {
      ReadingPlacesReady(:final places) => places,
      _ => const <String, Never>{},
    };
    final chips = topicChips(
      modules: notes.modules,
      track: track,
      record: record,
      places: places,
      today: dayNumber(clock.now()),
    );
    if (chips.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(
            S.of(context).catalog_topics,
            style: theme.textTheme.labelLarge?.copyWith(color: context.bazaarColors.onSurfaceMuted),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final term in chips)
                ActionChip(
                  key: TopicChipsRow.chipKey(termKey(track, term.moduleKey, term.index)),
                  label: Text(term.name),
                  onPressed: () => context.push(BazaarPaths.glossaryTerm(termKey(track, term.moduleKey, term.index))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
