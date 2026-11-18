import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_pool.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';

/// The review pool of [track] in [language] (plan 13.3), watched from the study notes and the record: null while the
/// notes read are not yet of that track and language. A page that calls it stands under a `StudyNotesLoader`.
ReviewPool? reviewPoolOf(BuildContext context, Track track, String language) {
  final notes = context.watch<StudyNotesCubit>().state;
  final record = switch (context.watch<RecordBloc>().state) {
    RecordReady(:final record) => record,
    RecordLoading() => RecordData.empty,
  };
  return switch (notes) {
    StudyNotesReady(track: final read, language: final readIn, :final modules)
        when read == track && readIn == language =>
      reviewPool(track: track, record: record, modules: modules),
    _ => null,
  };
}
