import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/utils/grouped_number.dart';

// The catalog prints the same labels; Home keeps its own copy, since a feature imports no other feature (R80).

/// A module number as the web prints it, zero-padded to two digits (web `SheetRow.number`).
String homeModuleNumber(int number) => number.toString().padLeft(2, '0');

/// A reading time as the web prints it (web `durationLabel`, `src/lib/content/manifest.ts:205-235`): `~45 min`, `~1 h`
/// or `~1 h 15 min`; null at or below zero minutes.
String? homeDurationLabel(S s, int minutes) {
  if (minutes <= 0) return null;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return s.duration_minutes(rest);
  if (rest == 0) return s.duration_hours(hours);
  return s.duration_hours_minutes(hours, rest);
}

/// A module's length as its web page prints it under the title (web D128), as the catalog's rows print it: its minutes
/// and the words of the document the reader opens, in [language] or in English where it is not written in it; null
/// when the content has no word count for it.
String? homeModuleLength(S s, HomeNext entry, String language) {
  final lang = entry.words.containsKey(language) ? language : 'en';
  final words = entry.words[lang];
  return words == null ? null : s.length_minutes_words(entry.module.minutes, groupedNumber(words, lang));
}
