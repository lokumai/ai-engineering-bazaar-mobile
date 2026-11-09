import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:clock/clock.dart';

final _isoDay = RegExp(RecordConstants.isoDay);
final _isoTime = RegExp(RecordConstants.isoTime);
final _instantDay = RegExp(RecordConstants.instantDay);

// The strict instant grammar of Decision A20, measured against V8 (m1-toolchain.md section 6.1(f)).
final _instant = RegExp(
  r'^\d{4}-\d{2}-\d{2}(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d+))?)?(Z|[+-](\d{2}):?(\d{2}))?)?$',
);
final _nonZero = RegExp('[1-9]');

/// Whether [day] is an ISO day (`YYYY-MM-DD`) that exists in the calendar.
///
/// Web source: `validate.ts:94-111` (`isRealDay`).
bool isRealDay(String day) {
  if (!_isoDay.hasMatch(day)) return false;
  final year = int.parse(day.substring(0, 4));
  final month = int.parse(day.substring(5, 7));
  final date = int.parse(day.substring(8, 10));
  final built = DateTime.utc(year, month, date);
  return built.year == year && built.month == month && built.day == date;
}

/// [value] unchanged when it is an instant the web accepts, else null.
///
/// Web source: `validate.ts:94-111` (`asInstant`), which asks V8's `Date.parse`.
/// Decision A20: this is a strict grammar, not `DateTime.tryParse`; it matches V8 on every `T` string, and the
/// space-separated strings only V8's legacy parser accepts are a recorded divergence.
String? asInstant(Object? value) {
  if (value is! String || value.isEmpty) return null;
  if (!_isoTime.hasMatch(value) || !isRealDay(value.substring(0, 10))) return null;
  final match = _instant.firstMatch(value);
  if (match == null) return null;
  final hourText = match.group(1);
  if (hourText == null) return value;
  final hour = int.parse(hourText);
  final minute = int.parse(match.group(2)!);
  final second = int.parse(match.group(3) ?? '0');
  final fraction = match.group(4) ?? '0';
  if (hour > 24 || minute > 59 || second > 59) return null;
  if (hour == 24 && (minute != 0 || second != 0 || _nonZero.hasMatch(fraction))) return null;
  final offsetHour = match.group(6);
  if (offsetHour != null && (int.parse(offsetHour) > 23 || int.parse(match.group(7)!) > 59)) return null;
  return value;
}

/// The day an instant falls on, as written at its start, or null when it has none or the day does not exist.
///
/// Web source: `events.ts:49-56` (`dayOf`).
String? dayOf(String now) {
  final match = _instantDay.firstMatch(now);
  if (match == null) return null;
  final day = match.group(1)!;
  return isRealDay(day) ? day : null;
}

/// The current instant in UTC, truncated to milliseconds, as the web's `new Date().toISOString()` writes it.
///
/// Web source: `store.ts:74-76`.
/// Truncated, never rounded: rounding could move an instant into the next day.
String nowIso() {
  final utc = clock.now().toUtc();
  return DateTime.fromMillisecondsSinceEpoch(utc.millisecondsSinceEpoch, isUtc: true).toIso8601String();
}
