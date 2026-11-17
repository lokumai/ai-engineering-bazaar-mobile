import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:equatable/equatable.dart';

/// What the Home page shows for one track, mapped from the index and the record (D111: counts and sums of what they
/// publish, nothing derived).
///
/// Home has no bloc of its own: this is a pure mapping of the two kernels' ready states, as the catalog's rows are.
final class HomeOverview extends Equatable {
  const HomeOverview({required this.next, required this.after, this.levels = const []});

  /// The module left half read most recently on this device, written in the track and not completed, with how far it
  /// was read (plan 1BA); else the first module by number that is written in the track and not completed (the web's
  /// `nextUnsigned`); null when every written module of the track is completed.
  final HomeNext? next;

  /// Up to [afterCount] more modules, by number, written in the track and not completed, leaving out [next] (plan 1P:
  /// Home says what to read now, and what comes after it).
  final List<HomeNext> after;

  /// How many modules [after] holds at most.
  static const afterCount = 2;

  /// Each level that holds a module written in the track, in the index's order, with how many of those are completed:
  /// the reader's path at a glance (the user, 2026-11-10). The catalog keeps the modules themselves.
  final List<HomeLevel> levels;

  @override
  List<Object?> get props => [next, after, levels];
}

/// One level on the reader's path: its written modules in the track and how many of them are completed.
final class HomeLevel extends Equatable {
  const HomeLevel({required this.level, required this.position, required this.done, required this.total});

  final LevelEntry level;

  /// The level's 0-based place in the index, which picks its hue.
  final int position;
  final int done;
  final int total;

  @override
  List<Object?> get props => [level, position, done, total];
}

/// The module the continue card opens.
final class HomeNext extends Equatable {
  const HomeNext({
    required this.module,
    required this.level,
    required this.position,
    required this.title,
    this.words = const {},
    this.share,
  });

  final ModuleEntry module;
  final LevelEntry level;

  /// The level's 0-based place in the index, which picks its hue.
  final int position;

  /// The module's title in the track, in the overview's language: the English one where it has none (web D139).
  final String title;

  /// The words of the module's document in the track, per language (web D128); empty where the content has no count.
  final Map<String, int> words;

  /// How far down the module the reader left it, from 0 to 1, when the continue card goes on with a module left half
  /// read (plan 1BA); null otherwise.
  final double? share;

  @override
  List<Object?> get props => [module, level, position, title, words, share];
}

/// The overview of [track] from [index], [record], and the reading [places] of this device, with
/// titles in [language].
HomeOverview homeOverview(
  BundleIndex index,
  Track track,
  RecordData record, {
  Map<String, ReadingPlace> places = const {},
  String language = 'en',
}) {
  final view = trackView(record, track);
  final curriculum = curriculumFor(index, track);
  final positions = {for (final (position, level) in index.levels.indexed) level.slug: position};

  HomeNext entryOf(String key, [Track titled = Track.engineers, double? share]) {
    final module = index.module(key)!;
    return HomeNext(
      module: module,
      level: index.level(module.level)!,
      position: positions[module.level]!,
      title: module.tracks[titled]!.titleIn(language),
      words: module.tracks[titled]!.words,
      share: share,
    );
  }

  final first = nextUnsigned(view, curriculum);
  // The written modules not completed, by number as `nextUnsigned` orders them, after the first.
  final open = [
    for (final fact in [...curriculum.modules]..sort((a, b) => a.number.compareTo(b.number)))
      if (fact.drawn && !isSigned(fact, view)) fact.slug,
  ];

  // The module left half read last, among the open ones: the card goes on with it.
  final reading = _lastLeft(places, track, open.toSet());
  final shown = reading?.key ?? first;

  return HomeOverview(
    next: reading != null
        ? entryOf(reading.key, track, reading.place.share)
        : first == null
        ? null
        : entryOf(first, track),
    after: [for (final key in open.where((key) => key != shown).take(HomeOverview.afterCount)) entryOf(key, track)],
    levels: [
      for (final (position, level) in index.levels.indexed)
        if (_written(curriculum, level.slug) case final written when written.isNotEmpty)
          HomeLevel(
            level: level,
            position: position,
            done: written.where((fact) => isSigned(fact, view)).length,
            total: written.length,
          ),
    ],
  );
}

/// The module of [open] in [track] that has the most recent place in [places], with that place; null when none has.
({String key, ReadingPlace place})? _lastLeft(Map<String, ReadingPlace> places, Track track, Set<String> open) {
  ({String key, ReadingPlace place})? last;
  for (final key in open) {
    final place = places[readingPlaceKey(track, key)];
    if (place != null && (last == null || place.at.isAfter(last.place.at))) last = (key: key, place: place);
  }
  return last;
}

/// The modules of [curriculum] in the level [slug] that are written in its track.
List<CurriculumFact> _written(Curriculum curriculum, String slug) => [
  for (final fact in curriculum.modules)
    if (fact.level == slug && fact.drawn) fact,
];
