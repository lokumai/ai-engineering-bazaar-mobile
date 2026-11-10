part of 'quiz_scores_bloc.dart';

sealed class QuizScoresEvent {
  const QuizScoresEvent();
}

/// Reads the scores kept on this device, once at start.
final class QuizScoresStarted extends QuizScoresEvent {
  const QuizScoresStarted();
}

/// An attempt at the quiz of the module [key] finished with [right] of [total] answered right.
final class QuizScoreRecorded extends QuizScoresEvent {
  const QuizScoreRecorded({required this.key, required this.right, required this.total});

  final String key;
  final int right;
  final int total;
}

/// Settings' reset erased the record: the scores go with it, kept aside for its undo.
final class QuizScoresErased extends QuizScoresEvent {
  const QuizScoresErased();
}

/// The reset was undone: the scores it erased come back.
final class QuizScoresEraseUndone extends QuizScoresEvent {
  const QuizScoresEraseUndone();
}
