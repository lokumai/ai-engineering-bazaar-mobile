import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// Asks for the study notes of the reader's track and language while [child] is shown, and again when the content,
/// the track or the language changes; the pages that show notes put it above them, so the notes are read only when
/// one of them is open.
class StudyNotesLoader extends StatelessWidget {
  const StudyNotesLoader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentBloc>().state;
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    if (content case ContentReady(:final index)) {
      final notes = context.read<StudyNotesCubit>();
      // Not during the build: a load may change the notes' state, which other widgets build from.
      Future.microtask(() => notes.load(index, track, language));
    }
    return child;
  }
}
