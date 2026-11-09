import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:equatable/equatable.dart';

/// One module as the selectors see it (the web's `SheetFact`, `derive.ts:32-48`): its record key, its number, its
/// level and whether it is written in the track the curriculum was built for.
final class CurriculumFact extends Equatable {
  const CurriculumFact({required this.slug, required this.number, required this.level, required this.drawn});

  final String slug;
  final int number;
  final String level;
  final bool drawn;

  @override
  List<Object?> get props => [slug, number, level, drawn];
}

/// One level and the number of modules it declares (the web's `categories` entry).
final class LevelTotal extends Equatable {
  const LevelTotal({required this.slug, required this.total});

  final String slug;
  final int total;

  @override
  List<Object?> get props => [slug, total];
}

/// The facts the selectors read, for one track (the web's `CurriculumFacts`).
final class Curriculum extends Equatable {
  const Curriculum({required this.levels, required this.modules});

  /// In curriculum order.
  final List<LevelTotal> levels;

  /// In index order.
  final List<CurriculumFact> modules;

  @override
  List<Object?> get props => [levels, modules];
}

/// The completed modules, the modules left and the whole set.
final class SignedCount extends Equatable {
  const SignedCount({required this.signed, required this.toGo, required this.of});

  final int signed;
  final int toGo;
  final int of;

  @override
  List<Object?> get props => [signed, toGo, of];
}

/// One level's completed modules and its total.
final class LevelCount extends Equatable {
  const LevelCount({required this.approved, required this.total});

  final int approved;
  final int total;

  @override
  List<Object?> get props => [approved, total];
}

/// What an erase removes: the module entries of both tracks that record something.
final class Tally extends Equatable {
  const Tally({required this.sheets});

  final int sheets;

  @override
  List<Object?> get props => [sheets];
}

/// The record seen through [track]: [data] itself for For Engineers; for For Everyone a copy whose `sheets` holds
/// `everyoneSheets`, every key at its position (JS `{...data, sheets: data.everyoneSheets}`).
///
/// Every selector reads `sheets`, so a view lets each answer for either track.
/// Web source: `schema.ts:196-201` (`trackView`).
RecordData trackView(RecordData data, Track track) {
  if (track == Track.engineers) return data;
  return RecordData.unchecked(
    Map<String, Object?>.unmodifiable({
      for (final MapEntry(:key, :value) in data.raw.entries)
        key: key == sheetsKey(Track.engineers) ? data.raw[sheetsKey(Track.everyone)] : value,
    }),
  );
}

/// Whether [fact] is drawn and completed in [view] (a [trackView], so its `sheets` is the track's map).
///
/// Web source: `derive.ts:54-56` (`isSigned`).
bool isSigned(CurriculumFact fact, RecordData view) => fact.drawn && view.signedOff(fact.slug, Track.engineers) != null;

/// The completed modules of [curriculum] in [view]; `of` counts every module, drawn or not.
///
/// Web source: `derive.ts:64-71` (`signedCount`).
SignedCount signedCount(RecordData view, Curriculum curriculum) {
  final of = curriculum.modules.length;
  final signed = curriculum.modules.where((fact) => isSigned(fact, view)).length;
  return SignedCount(signed: signed, toGo: of - signed, of: of);
}

/// Each level's completed modules and total, keyed by level slug in the web's insertion order: every declared level
/// first, in [Curriculum.levels] order, with its declared total; then each level a module names but no level
/// declares, on first sight, its total counted from its modules.
///
/// Web source: `derive.ts:118-140` (`categoryProgress`).
Map<String, LevelCount> categoryProgress(RecordData view, Curriculum curriculum) {
  // A Dart map literal is a LinkedHashMap: it keeps insertion order, as a JS object does for these keys.
  final approved = <String, int>{};
  final totals = <String, int>{};
  final declared = <String>{};
  for (final level in curriculum.levels) {
    declared.add(level.slug);
    approved[level.slug] = 0;
    totals[level.slug] = level.total;
  }
  for (final fact in curriculum.modules) {
    approved.putIfAbsent(fact.level, () => 0);
    totals.putIfAbsent(fact.level, () => 0);
    if (!declared.contains(fact.level)) totals[fact.level] = totals[fact.level]! + 1;
    if (isSigned(fact, view)) approved[fact.level] = approved[fact.level]! + 1;
  }
  return {for (final MapEntry(:key, :value) in approved.entries) key: LevelCount(approved: value, total: totals[key]!)};
}

/// The slug of the first module by number that is drawn and not completed, or null when none is left.
///
/// The sort is stable, as JS `Array.prototype.sort`: modules with the same number keep their listed order.
/// Web source: `derive.ts:290-294` (`nextUnsigned`).
String? nextUnsigned(RecordData view, Curriculum curriculum) {
  final modules = curriculum.modules;
  final order = List<int>.generate(modules.length, (index) => index)
    ..sort((a, b) {
      final byNumber = modules[a].number.compareTo(modules[b].number);
      return byNumber != 0 ? byNumber : a.compareTo(b);
    });
  for (final index in order) {
    final fact = modules[index];
    if (fact.drawn && !isSigned(fact, view)) return fact.slug;
  }
  return null;
}

/// Whether [data] carries nothing the reader made: no day, no backup instant, and no entry of either track that
/// records something; `prefs` is not consulted.
///
/// A completion under a key the curriculum no longer lists counts here (and in [tally]) only.
/// Web source: `schema.ts:182-187` (`carriesNothing`).
bool carriesNothing(RecordData data) {
  if (data.days.isNotEmpty) return false;
  if ((data.raw['meta']! as Map)['lastExport'] != null) return false;
  return _entries(data).every(isEmptySheetEntry);
}

/// The entries of both tracks that record something, which an erase removes.
///
/// Web source: `derive.ts:303-309` (`tally`).
Tally tally(RecordData data) => Tally(sheets: _entries(data).where((sheet) => !isEmptySheetEntry(sheet)).length);

/// Every entry of `sheets`, then of `everyoneSheets`.
Iterable<Map<String, Object?>> _entries(RecordData data) => [
  for (final track in Track.values) ...(data.raw[sheetsKey(track)]! as Map).values.cast<Map<String, Object?>>(),
];
