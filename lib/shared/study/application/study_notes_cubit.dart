import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// The Key Terms, Summary and quiz of every module written in a track, in one language (plan 13.2 to 13.10): Practice,
/// Home's review row, the reader's terms and the search's chips read them. A module not translated lends its English
/// document, as the reader does (plan 1Q).
///
/// A `Cubit` because each load replaces the one before and the event stream adds nothing: a load for the notes already
/// read, or being read, does nothing.
final class StudyNotesCubit extends Cubit<StudyNotesState> {
  StudyNotesCubit({required this._repository}) : super(const StudyNotesLoading());

  static final _log = AppLogger.getLogger('StudyNotesCubit');

  final IContentRepository _repository;

  /// What the last load was for: the index's version, the track and the language.
  (String, Track, String)? _for;

  /// Reads the notes of [track] in [language] from [index], unless they are read or being read already.
  Future<void> load(BundleIndex index, Track track, String language) async {
    final key = (index.contentVersion, track, language);
    if (_for == key) return;
    _for = key;
    if (state is StudyNotesReady) emit(const StudyNotesLoading());
    final positions = {for (final (position, level) in index.levels.indexed) level.slug: position};
    final modules =
        [
          for (final module in index.modules)
            if (positions.containsKey(module.level) && (module.tracks[track]?.drawn ?? false)) module,
        ]..sort(
          (a, b) => positions[a.level] != positions[b.level]
              ? positions[a.level]!.compareTo(positions[b.level]!)
              : a.number.compareTo(b.number),
        );
    final notes = <ModuleNotes>[];
    for (final module in modules) {
      final docs = module.tracks[track]!.docs;
      final path = docs[language] ?? docs['en'];
      if (path == null) continue;
      try {
        notes.add(notesOf(module.key, await _repository.readModuleDoc(path)));
      } on Object catch (error) {
        // A document that cannot be read leaves its module out rather than Practice with an error, as Home's card does.
        _log.warn('notes of {} unreadable: {}', [path, error]);
      }
      // A load for another track, language or content began meanwhile: it owns the state now.
      if (_for != key || isClosed) return;
    }
    emit(StudyNotesReady(track: track, language: language, modules: List.unmodifiable(notes)));
  }
}

sealed class StudyNotesState extends Equatable {
  const StudyNotesState();
}

/// The notes are being read, or no load was asked for yet.
final class StudyNotesLoading extends StudyNotesState {
  const StudyNotesLoading();

  @override
  List<Object?> get props => const [];
}

/// The notes of every module written in [track], read in [language], in the index's order: by level, then number.
final class StudyNotesReady extends StudyNotesState {
  StudyNotesReady({required this.track, required this.language, required this.modules})
    : _byKey = {for (final notes in modules) notes.moduleKey: notes};

  final Track track;
  final String language;
  final List<ModuleNotes> modules;
  final Map<String, ModuleNotes> _byKey;

  /// The notes of the module [key], or null when it is not written in [track] or could not be read.
  ModuleNotes? of(String key) => _byKey[key];

  /// Every term of every module, in the modules' order.
  Iterable<GlossaryTerm> get terms => modules.expand((notes) => notes.terms);

  @override
  List<Object?> get props => [track, language, modules];
}
