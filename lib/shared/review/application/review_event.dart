part of 'review_bloc.dart';

sealed class ReviewEvent {
  const ReviewEvent();
}

/// Reads the history kept on this device, once at start.
final class ReviewStarted extends ReviewEvent {
  const ReviewStarted();
}

/// The card [key] was answered, [right] or not: in a module's quiz, in Today's review ([inReview]), or in Wrong
/// answers. [length] is the module quiz's length for a question.
final class ReviewAnswered extends ReviewEvent {
  const ReviewAnswered({required this.key, required this.right, this.length, this.inReview = false});

  final String key;
  final bool right;
  final int? length;
  final bool inReview;
}

/// The term [key] was looked up, in the glossary or in a module's text (plan 13.3).
final class ReviewTermLookedUp extends ReviewEvent {
  const ReviewTermLookedUp(this.key);

  final String key;
}

/// The quiz of the module [moduleKey] was seen with [length] questions: the questions kept for a quiz of another
/// length, from before a content update changed it, are dropped.
final class ReviewQuizLengthSeen extends ReviewEvent {
  const ReviewQuizLengthSeen({required this.moduleKey, required this.length});

  final String moduleKey;
  final int length;
}

/// Settings' reset erased the record: the history goes with it, kept aside for its undo. A reset made [again] while the
/// undo of the one before is open keeps the history that one set aside.
final class ReviewErased extends ReviewEvent {
  const ReviewErased({this.again = false});

  final bool again;
}

/// The reset was undone: the history it erased comes back, under what was answered since.
final class ReviewEraseUndone extends ReviewEvent {
  const ReviewEraseUndone();
}
