import 'dart:convert';

import 'package:equatable/equatable.dart';

/// How a module's quiz went on this device (plan 1W): kept in the app only, never in the record, which stays the web's
/// byte for byte, and never in the backup file, which is the web's too. The site keeps no quiz score (its zero data
/// retention policy), so this is the app's own data.
final class QuizScore extends Equatable {
  const QuizScore({required this.last, required this.best, required this.total, this.previous});

  /// The right answers of the last finished attempt.
  final int last;

  /// The most right answers of any finished attempt of this quiz.
  final int best;

  /// The questions the quiz had; a quiz whose length changed starts afresh.
  final int total;

  /// The right answers of the attempt before the last; null after the first.
  final int? previous;

  /// Whether an attempt answered every question right: the quiz is done, as a completed module is, and stays so after
  /// a worse attempt.
  bool get perfect => best == total;

  /// The share of the last attempt answered right, from 0 to 1.
  double get lastShare => total == 0 ? 0 : last / total;

  /// The score after one more finished attempt with [right] of [total] right; a quiz of another length starts afresh.
  static QuizScore after(QuizScore? before, int right, int total) {
    if (before == null || before.total != total) return QuizScore(last: right, best: right, total: total);
    return QuizScore(last: right, best: right > before.best ? right : before.best, total: total, previous: before.last);
  }

  Map<String, Object?> _toJson() => {'last': last, 'best': best, 'total': total, 'previous': ?previous};

  static QuizScore? _fromJson(Object? json) {
    if (json case {'last': final int last, 'best': final int best, 'total': final int total}
        when total > 0 && last >= 0 && last <= total && best >= last && best <= total) {
      final previous = json['previous'];
      return QuizScore(
        last: last,
        best: best,
        total: total,
        previous: previous is int && previous >= 0 && previous <= total ? previous : null,
      );
    }
    return null;
  }

  @override
  List<Object?> get props => [last, best, total, previous];
}

/// The version of the file's shape; a file of another version reads as empty.
const quizScoresSchema = 1;

/// The scores as the file keeps them: `{"schema":1,"scores":{"<level>/<module>":{"last":3,"best":4,"total":5}}}`.
String encodeQuizScores(Map<String, QuizScore> scores) => jsonEncode({
  'schema': quizScoresSchema,
  'scores': {for (final MapEntry(:key, :value) in scores.entries) key: value._toJson()},
});

/// The scores in [text]; anything that does not read as the file's shape reads as no score, and a score that does not
/// is left out. Scores are a convenience: losing one costs a quiz taken again, never progress.
Map<String, QuizScore> decodeQuizScores(String text) {
  try {
    if (jsonDecode(text) case {'schema': quizScoresSchema, 'scores': final Map<String, Object?> scores}) {
      return {for (final MapEntry(:key, :value) in scores.entries) key: ?QuizScore._fromJson(value)};
    }
  } on FormatException {
    // Falls through to no score.
  }
  return const {};
}
