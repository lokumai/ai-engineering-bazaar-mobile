import 'package:ai_engineering_bazaar/generated/l10n.dart';

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
