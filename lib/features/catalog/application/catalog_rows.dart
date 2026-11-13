import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:equatable/equatable.dart';

/// One module of the catalog in a track (web `SheetRow`, `src/lib/content/rows.ts:26-91`).
final class CatalogRow extends Equatable {
  const CatalogRow({
    required this.key,
    required this.level,
    required this.number,
    required this.title,
    required this.drawn,
    required this.signed,
    required this.minutes,
    this.words = const {},
    required this.summary,
    required this.requires,
  });

  /// The module key, `<level>/<module>`.
  final String key;

  /// The level slug.
  final String level;
  final int number;

  /// The For Engineers title, in both tracks (web `src/lib/content/manifest.ts:72`), in the language of the rows: the
  /// English one where the module has none in it (web D139).
  final String title;

  /// Whether the module is written in the row's track.
  final bool drawn;

  /// Whether the module is completed in the row's track.
  final bool signed;
  final int minutes;

  /// Language to the words the module's web page prints in this track (web D128); empty where it is not written.
  final Map<String, int> words;

  /// The track's summary; null when the module is planned in the track.
  final String? summary;

  /// The numbers of the prerequisite modules, in bundle order.
  final List<int> requires;

  @override
  List<Object?> get props => [key, level, number, title, drawn, signed, minutes, words, summary, requires];
}

/// The rows of [index] for [track], in the index's module order. [view] is the record seen through [track]
/// (`trackView`); when it is null (the record is not read yet) nothing is signed. Titles are in [language].
List<CatalogRow> catalogRows(BundleIndex index, Track track, RecordData? view, {String language = 'en'}) {
  final facts = {for (final fact in curriculumFor(index, track).modules) fact.slug: fact};
  return [
    for (final module in index.modules)
      CatalogRow(
        key: module.key,
        level: module.level,
        number: module.number,
        title: module.tracks[Track.engineers]!.titleIn(language),
        drawn: module.tracks[track]!.drawn,
        signed: view != null && isSigned(facts[module.key]!, view),
        minutes: module.minutes,
        words: module.tracks[track]!.words,
        summary: module.tracks[track]!.summary,
        requires: [for (final key in module.prerequisites) index.module(key)!.number],
      ),
  ];
}

/// The rows of [level], in their order; a null [level] keeps every row (web `applyLevel`).
List<CatalogRow> applyLevel(List<CatalogRow> rows, String? level) => level == null
    ? rows
    : [
        for (final row in rows)
          if (row.level == level) row,
      ];

/// The levels of [index] that hold at least one of [rows], in the index's level order (web `levelsOf`,
/// `src/lib/content/rows.ts:182-186`).
List<LevelEntry> levelsOf(BundleIndex index, List<CatalogRow> rows) {
  final present = {for (final row in rows) row.level};
  return [
    for (final level in index.levels)
      if (present.contains(level.slug)) level,
  ];
}
