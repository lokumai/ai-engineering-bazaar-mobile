import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:equatable/equatable.dart';

/// What the Home page shows for one track, mapped from the index and the record (D111: counts and sums of what they
/// publish, nothing derived).
///
/// Home has no bloc of its own: this is a pure mapping of the two kernels' ready states, as the catalog's rows are.
final class HomeOverview extends Equatable {
  const HomeOverview({required this.next, required this.after});

  /// The first module by number that is written in the track and not completed (the web's `nextUnsigned`); null when
  /// every written module of the track is completed.
  final HomeNext? next;

  /// Up to [afterCount] more modules after [next], by number, written in the track and not completed (plan 1P: Home
  /// says what to read now, and what comes after it).
  final List<HomeNext> after;

  /// How many modules [after] holds at most.
  static const afterCount = 2;

  @override
  List<Object?> get props => [next, after];
}

/// The module the continue card opens.
final class HomeNext extends Equatable {
  const HomeNext({required this.module, required this.level, required this.position, required this.title});

  final ModuleEntry module;
  final LevelEntry level;

  /// The level's 0-based place in the index, which picks its hue.
  final int position;

  /// The module's title in the track.
  final String title;

  @override
  List<Object?> get props => [module, level, position, title];
}

/// The overview of [track] from [index] and [record].
HomeOverview homeOverview(BundleIndex index, Track track, RecordData record) {
  final view = trackView(record, track);
  final curriculum = curriculumFor(index, track);
  final positions = {for (final (position, level) in index.levels.indexed) level.slug: position};

  HomeNext entryOf(String key) {
    final module = index.module(key)!;
    return HomeNext(
      module: module,
      level: index.level(module.level)!,
      position: positions[module.level]!,
      title: module.tracks[track]!.title,
    );
  }

  final first = nextUnsigned(view, curriculum);
  // The written modules not completed, by number as `nextUnsigned` orders them, after the first.
  final open = [
    for (final fact in [...curriculum.modules]..sort((a, b) => a.number.compareTo(b.number)))
      if (fact.drawn && !isSigned(fact, view)) fact.slug,
  ];

  return HomeOverview(
    next: first == null ? null : entryOf(first),
    after: [for (final key in open.skip(1).take(HomeOverview.afterCount)) entryOf(key)],
  );
}
