/// The short months of `en-GB`, which writes September as `Sept`.
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];

/// The day of [iso] as `11 Oct 2026`: its first ten characters read as a UTC date, written as the web's `shortDate`
/// writes it (`src/components/record/SignOff.tsx`, `en-GB`, day numeric, month short, year numeric).
///
/// The first ten characters come back unchanged when they are not a real date, as the web's own fallback does.
String shortDate(String iso) {
  final day = iso.length > 10 ? iso.substring(0, 10) : iso;
  final parsed = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ? DateTime.tryParse('${day}T00:00:00Z') : null;
  // DateTime rolls an impossible day over into the next month; the web's Intl does not take it as a date.
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != day) return day;
  return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
}
