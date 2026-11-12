import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';

/// One level of the Quiz tab (plan 1AC): the level and its modules that carry a quiz, in number order.
final class QuizLevel extends Equatable {
  const QuizLevel({required this.level, required this.position, required this.modules});

  final LevelEntry level;

  /// The level's 0-based place in the index, which picks its hue.
  final int position;
  final List<ModuleEntry> modules;

  @override
  List<Object?> get props => [level, position, modules];
}

/// The levels of [index] that hold a module with a quiz in [track], in the index's order, each with those modules.
///
/// A module has one quiz file, shown on both tracks (web D137), so a module carries a quiz in a track when it is written
/// in that track (`hasQuiz`).
List<QuizLevel> quizLevels(BundleIndex index, Track track) => [
  for (final (position, level) in index.levels.indexed)
    if (_withQuiz(index, level.slug, track) case final modules when modules.isNotEmpty)
      QuizLevel(level: level, position: position, modules: modules),
];

List<ModuleEntry> _withQuiz(BundleIndex index, String level, Track track) => [
  for (final module in index.modules)
    if (module.level == level && (module.tracks[track]?.hasQuiz ?? false)) module,
]..sort((a, b) => a.number.compareTo(b.number));
