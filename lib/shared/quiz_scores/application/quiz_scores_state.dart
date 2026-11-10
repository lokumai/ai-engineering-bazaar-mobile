part of 'quiz_scores_bloc.dart';

sealed class QuizScoresState extends Equatable {
  const QuizScoresState();
}

/// The scores are being read.
final class QuizScoresLoading extends QuizScoresState {
  const QuizScoresLoading();

  @override
  List<Object?> get props => const [];
}

/// The scores of this device by module key; a quiz never finished has none.
final class QuizScoresReady extends QuizScoresState {
  const QuizScoresReady(this.scores);

  final Map<String, QuizScore> scores;

  @override
  List<Object?> get props => [scores];
}

/// The score of the module [key]'s quiz, or null when it was never finished or the scores are being read.
extension QuizScoreOf on QuizScoresState {
  QuizScore? of(String key) => switch (this) {
    QuizScoresReady(:final scores) => scores[key],
    QuizScoresLoading() => null,
  };
}
