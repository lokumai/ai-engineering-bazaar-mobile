part of 'review_bloc.dart';

sealed class ReviewState extends Equatable {
  const ReviewState();
}

/// The history is being read.
final class ReviewLoading extends ReviewState {
  const ReviewLoading();

  @override
  List<Object?> get props => const [];
}

/// The history of this device.
final class ReviewReady extends ReviewState {
  const ReviewReady(this.history);

  final ReviewHistory history;

  @override
  List<Object?> get props => [history];
}

/// The history, or an empty one while it is being read.
extension ReviewHistoryOf on ReviewState {
  ReviewHistory get history => switch (this) {
    ReviewReady(:final history) => history,
    ReviewLoading() => ReviewHistory.empty,
  };
}
