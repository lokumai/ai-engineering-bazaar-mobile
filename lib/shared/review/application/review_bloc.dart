import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

part 'review_event.dart';
part 'review_state.dart';

/// Practice's history on this device (plan 13.1): every quiz answer, in a module's quiz or in Practice, and every term
/// looked up go to it; Practice and Home read Today's review and Wrong answers from it; Settings' reset erases it with
/// the record and brings it back on undo.
///
/// A `Bloc` because it touches storage: every event runs in one queue, so a save never overtakes another.
final class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  ReviewBloc({required this._store}) : super(const ReviewLoading()) {
    on<ReviewEvent>(_onEvent, transformer: EventTransformers.queue());
  }

  final IReviewStore _store;

  /// The history the last reset erased, while its undo may bring it back.
  ReviewHistory? _erased;

  Future<void> _onEvent(ReviewEvent event, Emitter<ReviewState> emit) async {
    final history = state.history;
    final today = dayNumber(clock.now());
    final next = switch (event) {
      ReviewStarted() => await _store.load(),
      ReviewAnswered(:final key, :final right, :final length, :final inReview, :final reviewDay) => history.answered(
        key,
        right: right,
        today: today,
        length: length,
        inReview: inReview,
        reviewDay: reviewDay,
      ),
      ReviewTermLookedUp(:final key) => history.lookedUp(key, today),
      ReviewQuizLengthSeen(:final moduleKey, :final length) => history.seenLength(moduleKey, length),
      ReviewErased(:final again) => _erase(history, again),
      ReviewEraseUndone() => _undo(history),
    };
    if (event is! ReviewStarted && next == history && state is ReviewReady) return;
    emit(ReviewReady(next));
    if (event is! ReviewStarted) await _store.save(next);
  }

  ReviewHistory _erase(ReviewHistory history, bool again) {
    if (!again || _erased == null) _erased = history;
    return ReviewHistory.empty;
  }

  ReviewHistory _undo(ReviewHistory history) {
    final erased = _erased;
    if (erased == null) return history;
    _erased = null;
    return erased.under(history);
  }
}
