import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';

/// A module number as the catalog prints it, zero-padded to two digits (web `SheetRow.number`).
String moduleNumber(int number) => number.toString().padLeft(2, '0');

/// A reading time as the web prints it (web `durationLabel`, `src/lib/content/manifest.ts:205-235`): `~45 min`, `~1 h`
/// or `~1 h 15 min`; null at or below zero minutes.
String? durationLabel(S s, int minutes) {
  if (minutes <= 0) return null;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return s.duration_minutes(rest);
  if (rest == 0) return s.duration_hours(hours);
  return s.duration_hours_minutes(hours, rest);
}

/// The level page's lead line (web `categoryCoverage`): the module count, then the reading time of the level's modules
/// when there is one, joined by ` · `.
String levelLeadLine(S s, {required int modules, required int minutes}) =>
    [s.level_module_count(modules), ?durationLabel(s, minutes)].join(' · ');

/// A card's Requires fact (web `SheetRow.requires`): the prerequisite numbers joined by `, `, or `Nothing`.
String requiresLabel(S s, List<int> numbers) =>
    numbers.isEmpty ? s.card_requires_nothing : numbers.map((number) => '$number').join(', ');

/// The 0-based place of the level [slug] in [index], which picks its hue (`levelHue`).
int levelPosition(BundleIndex index, String slug) => index.levels.indexWhere((level) => level.slug == slug);

/// The no-reading form the web prints before the record is read (`ProgressTabs.tsx:10`).
const catalogNoReading = '--';
