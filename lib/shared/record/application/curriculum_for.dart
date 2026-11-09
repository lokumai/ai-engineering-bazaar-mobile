import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';

/// The facts the record selectors read for [track], mapped from [index] in its order: each level with its declared
/// total, each module with its number, its level and whether it is written in [track].
///
/// Every index module carries both tracks (Decision A23), so `tracks[track]` is always present.
/// Web source: the conformance driver's `factsOf` (`tests/unit/record/conformance.test.ts:439-451`).
Curriculum curriculumFor(BundleIndex index, Track track) => Curriculum(
  levels: [for (final level in index.levels) LevelTotal(slug: level.slug, total: level.total)],
  modules: [
    for (final module in index.modules)
      CurriculumFact(slug: module.key, number: module.number, level: module.level, drawn: module.tracks[track]!.drawn),
  ],
);
