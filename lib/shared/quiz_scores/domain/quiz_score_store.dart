import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';

/// Where the quiz scores are kept on this device (plan 1W); `lib/app/di/` fills it with a file under Application
/// Support.
abstract interface class IQuizScoreStore {
  /// Every score kept, by module key; none when nothing is kept or it cannot be read.
  Future<Map<String, QuizScore>> load();

  /// Keeps [scores] in place of what was kept; an empty map removes them.
  Future<void> save(Map<String, QuizScore> scores);
}

/// A store that keeps the scores in memory only, for tests and for a device without storage.
final class MemoryQuizScoreStore implements IQuizScoreStore {
  MemoryQuizScoreStore([Map<String, QuizScore> scores = const {}]) : _scores = scores;

  Map<String, QuizScore> _scores;

  @override
  Future<Map<String, QuizScore>> load() async => _scores;

  @override
  Future<void> save(Map<String, QuizScore> scores) async => _scores = scores;
}
