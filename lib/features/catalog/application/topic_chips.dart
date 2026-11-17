import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// How many chips the empty search field offers.
const topicChipCount = 6;

/// How many of the modules completed last give their terms.
const _lastCompleted = 3;

/// The terms the empty search field offers as chips (plan 13.10, the owner, 2026-11-17): the terms of the module being
/// read and of the modules completed last, a few at a time, another few each day; a reader who has read nothing yet
/// gets the first module's. Each name comes once.
///
/// [modules] are the notes of [track] in the course's order; [places] where modules were left; [today] the day.
List<GlossaryTerm> topicChips({
  required List<ModuleNotes> modules,
  required Track track,
  required RecordData record,
  required Map<String, ReadingPlace> places,
  required int today,
}) {
  final view = trackView(record, track);
  bool done(String key) => view.signedOff(key, Track.engineers) != null;
  final reading =
      [
        for (final notes in modules)
          if (!done(notes.moduleKey) && places[readingPlaceKey(track, notes.moduleKey)] != null) notes,
      ]..sort(
        (a, b) =>
            places[readingPlaceKey(track, b.moduleKey)]!.at.compareTo(places[readingPlaceKey(track, a.moduleKey)]!.at),
      );
  final completed = [
    for (final notes in modules)
      if (view.signedOff(notes.moduleKey, Track.engineers) case final at?) (notes: notes, at: at),
  ]..sort((a, b) => b.at.compareTo(a.at));
  final sources = [...reading.take(1), for (final entry in completed.take(_lastCompleted)) entry.notes];
  final names = <String>{};
  final pool = [
    for (final notes in sources.isEmpty ? modules.take(1) : sources)
      for (final term in notes.terms)
        if (names.add(term.name.toLowerCase())) term,
  ];
  if (pool.length <= topicChipCount) return pool;
  final start = (today * topicChipCount) % pool.length;
  return [for (var i = 0; i < topicChipCount; i++) pool[(start + i) % pool.length]];
}
