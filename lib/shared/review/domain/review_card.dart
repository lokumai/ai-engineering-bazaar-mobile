import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// The key of question [index] (0-based) of the module [moduleKey]'s quiz. A module has one quiz on both tracks, in
/// every language (web D137), so the key names neither.
String questionKey(String moduleKey, int index) => '$moduleKey#$index';

/// The key of term [index] (0-based) of the module [moduleKey]'s Key Terms in [track]. The terms of a track are the same
/// in every language, in the same order, so the key names no language.
String termKey(Track track, String moduleKey, int index) => 'term:${track.name}/$moduleKey#$index';

/// Whether [key] is a term's, not a question's.
bool isTermKey(String key) => key.startsWith('term:');

/// The module key a question's or a term's [key] names.
String moduleOfKey(String key) {
  final bare = isTermKey(key) ? key.substring(key.indexOf('/') + 1) : key;
  return bare.substring(0, bare.lastIndexOf('#'));
}

/// The 0-based place a question's or a term's [key] names in its module.
int indexOfKey(String key) => int.parse(key.substring(key.lastIndexOf('#') + 1));

/// One answer to a card: the day it was given, as `dayNumber` counts them, and whether it was right.
final class ReviewAnswer extends Equatable {
  const ReviewAnswer({required this.day, required this.right});

  final int day;
  final bool right;

  @override
  List<Object?> get props => [day, right];
}

/// What this device keeps of one card, a quiz question or a term looked up (plan 13.1): its Leitner box, the day it is
/// due, how it was last answered, and its last answers.
///
/// The boxes (plan 13.3): a right answer moves a card up one box, due 1, 3, 7, then 21 days later; a wrong one brings it
/// back to the first box, due tomorrow. A right answer to a card not yet due, as when a module's quiz is taken again the
/// same day, moves it no higher: only a review on its day does.
final class ReviewCard extends Equatable {
  const ReviewCard({required this.box, required this.due, this.run = 0, this.wrong = false, this.answers = const []});

  /// A term looked up on [today] (plan 13.3, 13.8): due tomorrow, in the first box.
  factory ReviewCard.lookedUp(int today) => ReviewCard(box: 0, due: today + 1);

  /// The days a card waits in each box above the first: box 1 waits 1 day, box 4 waits 21.
  static const waits = [1, 3, 7, 21];

  /// The highest box.
  static const top = 4;

  /// How many answers a card keeps, the last ones.
  static const kept = 10;

  /// How many right answers in a row take a question out of Wrong answers (plan 13.4): one (the owner, 2026-11-18).
  static const rightToLeave = 1;

  /// The box, from 0 (new, or answered wrong) to [top].
  final int box;

  /// The day the card is due, as `dayNumber` counts them.
  final int due;

  /// The right answers in a row since the last wrong one.
  final int run;

  /// Whether the card is in Wrong answers: answered wrong, and not right [rightToLeave] times in a row since.
  final bool wrong;

  /// The last [kept] answers, the oldest first.
  final List<ReviewAnswer> answers;

  /// Whether the card is due on [today].
  bool dueOn(int today) => due <= today;

  /// The card after an answer on [today], [right] or not; [before] is null for a card never answered.
  static ReviewCard after(ReviewCard? before, {required bool right, required int today}) {
    final answers = [...?before?.answers, ReviewAnswer(day: today, right: right)];
    final last = answers.length > kept ? answers.sublist(answers.length - kept) : answers;
    if (!right) return ReviewCard(box: 0, due: today + 1, wrong: true, answers: List.unmodifiable(last));
    final run = (before?.run ?? 0) + 1;
    final wrong = (before?.wrong ?? false) && run < rightToLeave;
    if (before != null && !before.dueOn(today)) {
      return ReviewCard(box: before.box, due: before.due, run: run, wrong: wrong, answers: List.unmodifiable(last));
    }
    final box = before == null ? 1 : (before.box + 1).clamp(1, top);
    return ReviewCard(box: box, due: today + waits[box - 1], run: run, wrong: wrong, answers: List.unmodifiable(last));
  }

  @override
  List<Object?> get props => [box, due, run, wrong, answers];
}
