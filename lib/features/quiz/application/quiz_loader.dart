import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the quiz of one module for the quiz page (plan 1AC), from the module's document in the reader's track and
/// language, or in English when it is not translated, as the reader does (plan 1Q). A module has one quiz file on both
/// tracks (web D137); a module not written in the track lends its For Engineers document, so a link to its quiz still
/// opens.
///
/// A `Cubit` because it loads once and the event stream adds nothing.
final class QuizLoader extends Cubit<QuizLoad> {
  QuizLoader({required this._repository, required this._index}) : super(const QuizLoading());

  static final _log = AppLogger.getLogger('QuizLoader');

  final IContentRepository _repository;
  final BundleIndex _index;

  /// Loads the quiz of the module [key] in [track] and [language].
  Future<void> load(String key, String language, {Track track = Track.engineers}) async {
    final tracks = _index.module(key)?.tracks;
    final own = tracks?[track];
    final version = own != null && own.hasQuiz ? own : tracks?[Track.engineers];
    final path = version == null || !version.hasQuiz ? null : version.docs[language] ?? version.docs['en'];
    if (version == null || path == null) {
      emit(const QuizMissing());
      return;
    }
    QuizLoad loaded;
    try {
      final items = (await _repository.readModuleDoc(path)).quiz;
      loaded = items == null || items.isEmpty
          ? const QuizMissing()
          : QuizReady(title: version.titleIn(language), items: items);
    } on Object catch (error) {
      // Any error, not only the content's own, ends the spinner (review 5, finding 7).
      _log.warn('quiz document {} unreadable: {}', [path, error]);
      loaded = const QuizUnreadable();
    }
    // The page may have been left while the document was read (review 5, finding 7).
    if (!isClosed) emit(loaded);
  }
}

sealed class QuizLoad extends Equatable {
  const QuizLoad();

  @override
  List<Object?> get props => [];
}

final class QuizLoading extends QuizLoad {
  const QuizLoading();
}

/// The quiz of the module titled [title].
final class QuizReady extends QuizLoad {
  const QuizReady({required this.title, required this.items});

  final String title;
  final List<QuizItem> items;

  @override
  List<Object?> get props => [title, items];
}

/// No module of that key carries a quiz.
final class QuizMissing extends QuizLoad {
  const QuizMissing();
}

/// The module's document could not be read.
final class QuizUnreadable extends QuizLoad {
  const QuizUnreadable();
}
