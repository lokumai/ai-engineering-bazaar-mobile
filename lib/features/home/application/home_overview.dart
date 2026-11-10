import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:equatable/equatable.dart';

/// What the Home page shows for one track, mapped from the index and the record (D111: counts and sums of what they
/// publish, nothing derived).
///
/// Home has no bloc of its own: this is a pure mapping of the two kernels' ready states, as the catalog's rows are.
final class HomeOverview extends Equatable {
  const HomeOverview({required this.next, required this.after, this.practice = const []});

  /// The first module by number that is written in the track and not completed (the web's `nextUnsigned`); null when
  /// every written module of the track is completed.
  final HomeNext? next;

  /// Up to [afterCount] more modules after [next], by number, written in the track and not completed (plan 1P: Home
  /// says what to read now, and what comes after it).
  final List<HomeNext> after;

  /// How many modules [after] holds at most.
  static const afterCount = 2;

  /// Up to [practiceCount] completed modules whose quiz the reader can take again (plan 1AD): a quiz never finished
  /// first, then the lowest last score, then the most recently completed (plan 1W). Only For Engineers documents carry
  /// a quiz, so each entry is titled as For Engineers.
  final List<HomeNext> practice;

  /// How many modules [practice] holds at most.
  static const practiceCount = 3;

  @override
  List<Object?> get props => [next, after, practice];
}

/// The module the continue card opens.
final class HomeNext extends Equatable {
  const HomeNext({required this.module, required this.level, required this.position, required this.title, this.score});

  final ModuleEntry module;
  final LevelEntry level;

  /// The level's 0-based place in the index, which picks its hue.
  final int position;

  /// The module's title in the track.
  final String title;

  /// The quiz's score kept on this device, on a practice entry whose quiz was finished; null otherwise.
  final QuizScore? score;

  @override
  List<Object?> get props => [module, level, position, title, score];
}

/// The overview of [track] from [index], [record] and the quiz [scores] of this device.
HomeOverview homeOverview(
  BundleIndex index,
  Track track,
  RecordData record, [
  Map<String, QuizScore> scores = const {},
]) {
  final view = trackView(record, track);
  final curriculum = curriculumFor(index, track);
  final positions = {for (final (position, level) in index.levels.indexed) level.slug: position};

  HomeNext entryOf(String key, [Track titled = Track.engineers, QuizScore? score]) {
    final module = index.module(key)!;
    return HomeNext(
      module: module,
      level: index.level(module.level)!,
      position: positions[module.level]!,
      title: module.tracks[titled]!.title,
      score: score,
    );
  }

  final first = nextUnsigned(view, curriculum);
  // The written modules not completed, by number as `nextUnsigned` orders them, after the first.
  final open = [
    for (final fact in [...curriculum.modules]..sort((a, b) => a.number.compareTo(b.number)))
      if (fact.drawn && !isSigned(fact, view)) fact.slug,
  ];

  return HomeOverview(
    next: first == null ? null : entryOf(first, track),
    after: [for (final key in open.skip(1).take(HomeOverview.afterCount)) entryOf(key, track)],
    practice: [
      for (final key in _toPractise(_recentlyCompletedWithQuiz(index, curriculum, view), scores))
        entryOf(key, Track.engineers, scores[key]),
    ],
  );
}

/// The first [HomeOverview.practiceCount] of [recent], the most recently completed first, leaving out a quiz once
/// answered all right: a quiz never finished comes first, then the lowest share of the last attempt; the order of
/// [recent] breaks ties.
List<String> _toPractise(List<String> recent, Map<String, QuizScore> scores) {
  recent = [
    for (final key in recent)
      if (!(scores[key]?.perfect ?? false)) key,
  ];
  final order = {for (final (position, key) in recent.indexed) key: position};
  double share(String key) => scores[key]?.lastShare ?? -1;
  return ([...recent]..sort((a, b) {
        final byScore = share(a).compareTo(share(b));
        return byScore != 0 ? byScore : order[a]!.compareTo(order[b]!);
      }))
      .take(HomeOverview.practiceCount)
      .toList();
}

/// The completed modules of [curriculum] in [view] whose For Engineers version carries a quiz, the most recently
/// completed first; two completed at the same instant keep their number order. The record keeps when each module was
/// completed (`signedOff`), so this is the record's own order, nothing derived (D111).
List<String> _recentlyCompletedWithQuiz(BundleIndex index, Curriculum curriculum, RecordData view) {
  final done = [
    for (final fact in [...curriculum.modules]..sort((a, b) => a.number.compareTo(b.number)))
      if (isSigned(fact, view) && (index.module(fact.slug)?.tracks[Track.engineers]?.hasQuiz ?? false))
        (key: fact.slug, at: DateTime.parse(view.signedOff(fact.slug, Track.engineers)!)),
  ];
  // A stable sort: List.sort is not, so the number order breaks ties explicitly.
  final order = {for (final (position, entry) in done.indexed) entry.key: position};
  done.sort((a, b) {
    final byTime = b.at.compareTo(a.at);
    return byTime != 0 ? byTime : order[a.key]!.compareTo(order[b.key]!);
  });
  return [for (final entry in done) entry.key];
}
