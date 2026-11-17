/// The day's card on Home (plan 11.1, the owner, 2026-11-16): one section of one module, its heading and its first
/// sentences, which the Apprentice offers at the head of Home. The same card all day, another the next: it is chosen by
/// the day, not by chance, so every opening of the app that day shows it.
///
/// It is chosen in two steps. [dailyChoice] picks the module from the index and the record, which are at hand; the
/// module's document is then read, and [dailyCardOf] picks the section from it.
library;

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/plain_text.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:equatable/equatable.dart';

/// The day [now] falls on, counted from 1970-01-01 in the reader's own calendar: it turns at local midnight. A UTC
/// moment is read in the local zone first.
int dayNumber(DateTime now) {
  final local = now.toLocal();
  return DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// How long from [now] until a moment past the next local midnight. A UTC moment is read in the local zone first, so
/// the wait is never below zero: east of UTC, a UTC moment's own date can be the day before the local one.
Duration untilLocalMidnight(DateTime now) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + 1).difference(local) + const Duration(seconds: 1);
}

/// The module the day's card is taken from, and how many times the card has come round to it before.
final class DailyChoice extends Equatable {
  const DailyChoice({required this.moduleKey, required this.docPath, required this.turn});

  /// The module key, `<level>/<module>`.
  final String moduleKey;

  /// Its document in the track and the reader's language.
  final String docPath;

  /// How many times the card has come to this module before today: the next of its sections each time.
  final int turn;

  @override
  List<Object?> get props => [moduleKey, docPath, turn];
}

/// How many of the modules not completed yet the card takes from, the first by number: a taste of what is next.
const int dailyOpenCount = 3;

/// The module of [day]'s card in [track]: one of the modules completed, which it recalls, or of the next
/// [dailyOpenCount] not completed, which it teases, all by number, each written in the track and in [language]. The
/// days go round them in turn. Null when there is none, as with a course not written in [language].
///
/// A module completed on [day] itself counts as not completed yet, as it was when the day began: the card the day
/// opened on stays all day, finished or not (the owner, 2026-11-16).
DailyChoice? dailyChoice(
  BundleIndex index,
  Track track,
  RecordData record, {
  required String language,
  required int day,
}) {
  final view = trackView(record, track);
  final facts = [...curriculumFor(index, track).modules]..sort((a, b) => a.number.compareTo(b.number));
  // Completed, and not on [day] itself; a time that cannot be read counts as another day.
  bool doneBefore(CurriculumFact fact) {
    if (!isSigned(fact, view)) return false;
    final at = DateTime.tryParse(view.signedOff(fact.slug, Track.engineers)!);
    return at == null || dayNumber(at.toLocal()) != day;
  }

  final done = [
    for (final fact in facts)
      if (doneBefore(fact)) fact.slug,
  ];
  final open = [
    for (final fact in facts)
      if (fact.drawn && !doneBefore(fact)) fact.slug,
  ].take(dailyOpenCount);
  final pool = [
    for (final key in [...done, ...open])
      if (index.module(key)?.tracks[track]?.docs[language] case final path?) (key: key, path: path),
  ];
  if (pool.isEmpty) return null;
  final picked = pool[day % pool.length];
  return DailyChoice(moduleKey: picked.key, docPath: picked.path, turn: day ~/ pool.length);
}

/// The day's card, read from its module's document.
final class DailyCard extends Equatable {
  const DailyCard({
    required this.moduleKey,
    required this.module,
    required this.heading,
    required this.sectionId,
    required this.lead,
  });

  /// The module key, `<level>/<module>`.
  final String moduleKey;

  /// The module's title in the document's language.
  final String module;

  /// The section's heading; the module's title for a module with no section to show.
  final String heading;

  /// The heading's id, which the reader opens at; null to open the module at its top.
  final String? sectionId;

  /// The section's first sentences.
  final String lead;

  @override
  List<Object?> get props => [moduleKey, module, heading, sectionId, lead];
}

/// The card [doc] gives on its [turn]: its `##` sections in order, one a turn, leaving out a list of links, a recap and
/// a section with no prose; a module with none of those gives its opening. Null for a module not written yet.
DailyCard? dailyCardOf(ModuleDoc doc, {required int turn}) {
  final body = doc.body;
  if (body == null) return null;
  final opening = <Block>[];
  final sections = <(HeadingBlock, List<Block>)>[];
  for (final block in body) {
    if (block is HeadingBlock && block.depth <= 2) {
      sections.add((block, []));
    } else if (sections.isEmpty) {
      opening.add(block);
    } else {
      sections.last.$2.add(block);
    }
  }
  final teaching = [
    for (final (heading, blocks) in sections)
      if (squashSpace(inlineText(heading.inlines)) case final title
          when !recapSections.contains(title.toLowerCase()) && plainOf(blocks).isNotEmpty)
        (title: title, id: heading.id, text: plainOf(blocks)),
  ];
  if (teaching.isEmpty) {
    final text = plainOf(opening);
    if (text.isEmpty) return null;
    return DailyCard(moduleKey: doc.key, module: doc.title, heading: doc.title, sectionId: null, lead: leadOf(text));
  }
  final section = teaching[turn % teaching.length];
  return DailyCard(
    moduleKey: doc.key,
    module: doc.title,
    heading: section.title,
    sectionId: section.id,
    lead: leadOf(section.text),
  );
}

/// The first sentences of [text] that fit in about [length] characters, at least one; one sentence longer than
/// [length] is cut at a word and ends with an ellipsis.
String leadOf(String text, {int length = 200}) {
  final sentences = text.split(RegExp(r'(?<=[.!?؟。])\s+'));
  final lead = StringBuffer(sentences.first);
  for (final sentence in sentences.skip(1)) {
    if (lead.length + 1 + sentence.length > length) break;
    lead.write(' $sentence');
  }
  final out = lead.toString();
  if (out.length <= length * 1.3) return out;
  final cut = out.substring(0, length);
  final space = cut.lastIndexOf(' ');
  return '${(space > length ~/ 2 ? cut.substring(0, space) : cut).trimRight()}…';
}
