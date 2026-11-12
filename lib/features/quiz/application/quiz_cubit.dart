import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';

part 'quiz_state.dart';

/// The quiz at the end of a module, on either track (web D137), as the web's `QuickQuiz.tsx` behaves.
///
/// The first answer to a question is final; Next and See results wait for it; Start over clears every answer and shows
/// the first question. Nothing is written to the record (spec 3.3.1), so a new page is a fresh quiz; the score goes to [onFinished].
///
/// A `Cubit` because every call is atomic and the event stream adds nothing.
final class QuizCubit extends Cubit<QuizState> {
  /// Throws an [ArgumentError] when [items] is empty. [onFinished] hears each attempt once, when its results first show,
  /// with the right answers and the questions (plan 1W: the app keeps the score, the record does not).
  QuizCubit(List<QuizItem> items, {this.onFinished})
    : _items = List.unmodifiable(_nonEmpty(items)),
      super(_fresh(items.length));

  final List<QuizItem> _items;

  final void Function(int right, int total)? onFinished;

  /// Whether this attempt's results were shown; Start over begins a new attempt.
  bool _finished = false;

  static List<QuizItem> _nonEmpty(List<QuizItem> items) {
    if (items.isEmpty) throw ArgumentError.value(items, 'items', 'A quiz needs at least one question');
    return items;
  }

  static QuizAsking _fresh(int count) =>
      QuizAsking(index: 0, picks: List<int?>.unmodifiable(List<int?>.filled(count, null)));

  /// The number of questions whose pick is the item's answer.
  int get score {
    var right = 0;
    for (var i = 0; i < _items.length; i++) {
      if (state.picks[i] == _items[i].answer) right++;
    }
    return right;
  }

  /// Answers the current question with [option]; ignored once it is answered or while the results are shown.
  ///
  /// Throws a [RangeError] for an option the question does not have.
  void pick(int option) {
    final current = state;
    if (current is! QuizAsking) return;
    RangeError.checkValueInInterval(option, 0, _items[current.index].options.length - 1, 'option');
    if (current.picks[current.index] != null) return;
    final picks = List<int?>.of(current.picks)..[current.index] = option;
    emit(QuizAsking(index: current.index, picks: List<int?>.unmodifiable(picks)));
  }

  /// Shows the next question once the current one is answered; does nothing on the last question.
  void next() {
    final current = state;
    if (current is! QuizAsking) return;
    if (current.picks[current.index] == null || current.index == _items.length - 1) return;
    emit(QuizAsking(index: current.index + 1, picks: current.picks));
  }

  /// Shows the previous question; does nothing on the first.
  void previous() {
    final current = state;
    if (current is! QuizAsking || current.index == 0) return;
    emit(QuizAsking(index: current.index - 1, picks: current.picks));
  }

  /// Shows question [index], from a question or from the results.
  ///
  /// Throws a [RangeError] for an index the quiz does not have.
  void go(int index) {
    RangeError.checkValidIndex(index, _items, 'index');
    emit(QuizAsking(index: index, picks: state.picks));
  }

  /// Shows the results once the last question is answered.
  void showResults() {
    final current = state;
    if (current is! QuizAsking) return;
    if (current.index != _items.length - 1 || current.picks[current.index] == null) return;
    emit(QuizResults(picks: current.picks));
    if (!_finished) {
      _finished = true;
      onFinished?.call(score, _items.length);
    }
  }

  /// Goes from the results back to the last question.
  void backToQuestions() {
    if (state is! QuizResults) return;
    emit(QuizAsking(index: _items.length - 1, picks: state.picks));
  }

  /// Clears every answer and shows the first question.
  void restart() {
    _finished = false;
    emit(_fresh(_items.length));
  }
}
