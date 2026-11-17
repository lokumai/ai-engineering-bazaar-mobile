import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';

/// Where Practice's history is kept on this device (plan 13.1); `lib/app/di/` fills it with a file under Application
/// Support, beside the quiz scores.
abstract interface class IReviewStore {
  /// The history kept; empty when nothing is kept or it cannot be read.
  Future<ReviewHistory> load();

  /// Keeps [history] in place of what was kept; an empty history removes it.
  Future<void> save(ReviewHistory history);
}

/// A store that keeps the history in memory only, for tests and for a device without storage.
final class MemoryReviewStore implements IReviewStore {
  MemoryReviewStore([this._history = ReviewHistory.empty]);

  ReviewHistory _history;

  @override
  Future<ReviewHistory> load() async => _history;

  @override
  Future<void> save(ReviewHistory history) async => _history = history;
}
