import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/instant.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:equatable/equatable.dart';

/// The name of the record map that holds [track]'s modules.
///
/// Web source: `events.ts:78` (in `editSheet`): `everyoneSheets` for For Everyone, `sheets` for For Engineers.
String sheetsKey(Track track) => track == Track.everyone ? 'everyoneSheets' : 'sheets';

/// The record's data: the normalised raw map, deeply unmodifiable, in the key order it will be written.
///
/// Values are kept raw (Decision W9); the getters are the views the web reads through its coercion.
/// Identity is meaningful: a reducer that changes nothing returns the same instance.
final class RecordData extends Equatable {
  /// [raw] as given; callers pass a map [normaliseRecord] built or a reducer derived from one, deeply unmodifiable.
  ///
  /// For the record domain's reducers and `trackView` only.
  const RecordData.unchecked(this.raw);

  /// The record with nothing in it (`RecordConstants.emptyRecord`); the one instance an erase returns.
  static const RecordData empty = RecordData.unchecked(RecordConstants.emptyRecord);

  /// The normalised data, in write order.
  final Map<String, Object?> raw;

  /// The instant [slug] was completed on [track], or null when it is not completed.
  ///
  /// Web source: `coerceSheet` (`validate.ts:140-149`) reads `signedOff` through `asInstant`.
  String? signedOff(String slug, Track track) {
    final sheet = _sheets(track)[slug];
    return sheet is Map ? asInstant(sheet['signedOff']) : null;
  }

  /// Every module completed on [track], in map order, mapped to its completion instant.
  Map<String, String> signedMap(Track track) => {for (final slug in _sheets(track).keys) slug: ?signedOff(slug, track)};

  /// The days with activity, distinct and sorted.
  List<String> get days => (raw['days']! as List).cast<String>();

  Map<String, Object?> _sheets(Track track) => raw[sheetsKey(track)]! as Map<String, Object?>;

  @override
  List<Object?> get props => [raw];
}

final _isoDay = RegExp(RecordConstants.isoDay);

/// [data] normalised as spec 3.3.4 with Decision A21 has it, deeply unmodifiable.
///
/// The order is `sheets`, `everyoneSheets`, `days`, `prefs`, `meta` (the web's `coerceRecordData`,
/// `validate.ts:180-224`), then every other key of [data] in its order, its value untouched.
/// Each object the web rebuilds from a template is re-keyed by it (Decision A21): the template's keys first, in its
/// order, each with the raw value when the raw map has the key and the template's value when it does not, then the
/// raw keys the template lacks, in their order.
/// Values are never coerced (Decision W9); the views of [RecordData] read them as the web does.
RecordData normaliseRecord(Map<String, Object?> data) {
  final prefs = RecordConstants.emptyRecord['prefs']! as Map<String, Object?>;
  final meta = RecordConstants.emptyRecord['meta']! as Map<String, Object?>;
  final built = <String, Object?>{
    'sheets': _sheetMap(data['sheets']),
    'everyoneSheets': _sheetMap(data['everyoneSheets']),
    'days': _days(data['days']),
    'prefs': _rekey(data['prefs'], prefs),
    'meta': _rekey(data['meta'], meta),
    for (final MapEntry(:key, :value) in data.entries)
      if (!RecordConstants.emptyRecord.containsKey(key)) key: value,
  };
  return RecordData.unchecked(_freeze(built)! as Map<String, Object?>);
}

/// Whether [sheet] records nothing: no completion instant, and every other template field absent or at its empty
/// value; unknown keys do not count.
///
/// Web source: `schema.ts:207-215` (`isEmptySheetRecord`).
bool isEmptySheetEntry(Map<String, Object?> sheet) {
  if (asInstant(sheet['signedOff']) != null) return false;
  for (final field in const ['signedRevision', 'reachedEnd', 'dwellSeconds']) {
    if (sheet.containsKey(field) && sheet[field] != RecordConstants.emptySheet[field]) return false;
  }
  if (sheet.containsKey('checklist')) {
    final checklist = sheet['checklist'];
    if (checklist is! Map || checklist.isNotEmpty) return false;
  }
  return true;
}

/// A sheet map (`sheets` or `everyoneSheets`): safe keys only, object entries only, re-keyed by the sheet template,
/// empty entries dropped (`coerceSheets`, `validate.ts:151-163`).
Map<String, Object?> _sheetMap(Object? value) {
  if (value is! Map) return const {};
  final sheets = <String, Object?>{};
  for (final MapEntry(:key, :value) in value.entries) {
    if (key is! String || !isSafeKey(key) || value is! Map) continue;
    final sheet = _rekey(value, RecordConstants.emptySheet);
    if (!isEmptySheetEntry(sheet)) sheets[key] = sheet;
  }
  return sheets;
}

/// The distinct real days of [value], sorted in code-unit order as JS `sort()` (`coerceDays`, `validate.ts:165-173`).
List<Object?> _days(Object? value) {
  if (value is! List) return const [];
  final days = <String>{
    for (final day in value)
      if (day is String && _isoDay.hasMatch(day) && isRealDay(day)) day,
  }.toList()..sort();
  return days;
}

/// [value] re-keyed by [template] (Decision A21); a value that is not a map reads as the template.
Map<String, Object?> _rekey(Object? value, Map<String, Object?> template) {
  if (value is! Map) return template;
  return {
    for (final MapEntry(:key, value: fallback) in template.entries) key: value.containsKey(key) ? value[key] : fallback,
    for (final MapEntry(:key, :value) in value.entries)
      if (!template.containsKey(key)) key as String: value,
  };
}

/// [value] with every map and list in it made unmodifiable, insertion order kept.
Object? _freeze(Object? value) => switch (value) {
  Map() => Map<String, Object?>.unmodifiable({
    for (final MapEntry(:key, :value) in value.entries) key as String: _freeze(value),
  }),
  List() => List<Object?>.unmodifiable([for (final item in value) _freeze(item)]),
  _ => value,
};
