import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'quiz_scores_event.dart';
part 'quiz_scores_state.dart';

/// The quiz scores of this device (plan 1W): the quiz records a finished attempt, the Quiz tab and Home show them, and
/// Settings' reset erases them with the record and brings them back on undo.
///
/// A `Bloc` because it touches storage: every event runs in one queue, so a save never overtakes another.
final class QuizScoresBloc extends Bloc<QuizScoresEvent, QuizScoresState> {
  QuizScoresBloc({required this._store}) : super(const QuizScoresLoading()) {
    on<QuizScoresEvent>(_onEvent, transformer: EventTransformers.queue());
  }

  final IQuizScoreStore _store;

  /// The scores the last reset erased, while its undo may bring them back.
  Map<String, QuizScore>? _erased;

  Map<String, QuizScore> get _scores => switch (state) {
    QuizScoresReady(:final scores) => scores,
    QuizScoresLoading() => const {},
  };

  Future<void> _onEvent(QuizScoresEvent event, Emitter<QuizScoresState> emit) async {
    switch (event) {
      case QuizScoresStarted():
        emit(QuizScoresReady(await _store.load()));
      case QuizScoreRecorded(:final key, :final right, :final total):
        final scores = {..._scores, key: QuizScore.after(_scores[key], right, total)};
        _erased = null;
        emit(QuizScoresReady(scores));
        await _store.save(scores);
      case QuizScoresErased():
        _erased = _scores;
        emit(const QuizScoresReady({}));
        await _store.save(const {});
      case QuizScoresEraseUndone():
        final erased = _erased;
        if (erased == null) return;
        _erased = null;
        emit(QuizScoresReady(erased));
        await _store.save(erased);
    }
  }
}
