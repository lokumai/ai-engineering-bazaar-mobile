part of 'quiz_cubit.dart';

/// The quiz of one module: [picks] holds the option chosen for each question, or null while it is unanswered.
///
/// [QuizCubit] always passes an unmodifiable list, so a widget cannot change an answer behind the cubit's back.
sealed class QuizState extends Equatable {
  const QuizState({required this.picks});

  final List<int?> picks;

  @override
  List<Object?> get props => [picks];
}

/// Question [index] is shown.
final class QuizAsking extends QuizState {
  const QuizAsking({required this.index, required super.picks});

  final int index;

  @override
  List<Object?> get props => [picks, index];
}

/// The score and the recap of every question are shown.
final class QuizResults extends QuizState {
  const QuizResults({required super.picks});
}
