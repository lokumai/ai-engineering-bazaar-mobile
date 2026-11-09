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
  const HomeOverview({required this.next, required this.levels});

  /// The first module by number that is written in the track and not completed (the web's `nextUnsigned`); null when
  /// every written module of the track is completed.
  final HomeNext? next;

  /// Every level of the index, in its order.
  final List<HomeLevel> levels;

  @override
  List<Object?> get props => [next, levels];
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

/// One level row: its completed modules of its total in the track, and the reading time of its modules.
final class HomeLevel extends Equatable {
  const HomeLevel({
    required this.level,
    required this.position,
    required this.completed,
    required this.total,
    required this.minutes,
  });

  final LevelEntry level;

  /// The level's 0-based place in the index, which picks its hue.
  final int position;
  final int completed;
  final int total;

  /// The sum of the level's modules' `minutes`.
  final int minutes;

  @override
  List<Object?> get props => [level, position, completed, total, minutes];
}

/// The overview of [track] from [index] and [record].
HomeOverview homeOverview(BundleIndex index, Track track, RecordData record) {
  final view = trackView(record, track);
  final curriculum = curriculumFor(index, track);
  final counts = categoryProgress(view, curriculum);
  final positions = {for (final (position, level) in index.levels.indexed) level.slug: position};

  HomeNext? next;
  if (nextUnsigned(view, curriculum) case final key?) {
    final module = index.module(key)!;
    next = HomeNext(
      module: module,
      level: index.level(module.level)!,
      position: positions[module.level]!,
      title: module.tracks[track]!.title,
    );
  }

  return HomeOverview(
    next: next,
    levels: [
      for (final (position, level) in index.levels.indexed)
        HomeLevel(
          level: level,
          position: position,
          completed: counts[level.slug]?.approved ?? 0,
          total: counts[level.slug]?.total ?? level.total,
          minutes: index.modules
              .where((module) => module.level == level.slug)
              .fold(0, (sum, module) => sum + module.minutes),
        ),
    ],
  );
}
