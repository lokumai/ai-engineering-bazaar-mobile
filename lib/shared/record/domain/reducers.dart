import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/instant.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';

final _shortHash = RegExp(RecordConstants.shortHash);

/// [data] with [slug] completed on [track] at [now] against [revision], and the day of [now] stamped.
///
/// Web source: `events.ts:95-107` (`signOff`).
/// A module already completed (its `signedOff` read through `asInstant`) is a no-op, not a re-stamp; so is an
/// unsafe [slug].
RecordData signOff(RecordData data, String slug, String? revision, String now, {Track track = Track.engineers}) =>
    _editSheet(
      data,
      slug,
      now,
      (sheet) =>
          asInstant(sheet['signedOff']) != null ? null : {...sheet, 'signedOff': now, 'signedRevision': revision},
      track,
    );

/// [data] with [slug]'s completion on [track] cleared; no day is stamped and the emptied entry stays in the map.
///
/// Web source: `events.ts:114-120` (`unsign`).
/// The no-op test reads the views as the web reads coerced values: `signedOff` through `asInstant`, and
/// `signedRevision` through `SHORT_HASH` (`validate.ts:143-144`).
RecordData unsign(RecordData data, String slug, {Track track = Track.engineers}) => _editSheet(
  data,
  slug,
  null,
  (sheet) => asInstant(sheet['signedOff']) == null && !_isRevision(sheet['signedRevision'])
      ? null
      : {...sheet, 'signedOff': null, 'signedRevision': null},
  track,
);

/// [data] with the day of [now] stamped.
///
/// Web source: `events.ts:223-225` (`markActivity`).
RecordData markActivity(RecordData data, String now) => _stampDay(data, now);

/// [data] with `meta.lastExport` set to [now] in its place and the day of [now] stamped; a no-op when it already
/// reads [now].
///
/// Web source: `events.ts:235-238` (`markExported`).
RecordData markExported(RecordData data, String now) {
  final meta = data.raw['meta']! as Map<String, Object?>;
  if (asInstant(meta['lastExport']) == now) return data;
  return _stampDay(_replace(data, 'meta', Map<String, Object?>.unmodifiable({...meta, 'lastExport': now})), now);
}

/// The record an erase leaves behind: the empty one, the same instance every time.
///
/// Web source: `erase.ts:235-237` (`erasedRecord`).
RecordData erasedRecord(RecordData data) => RecordData.empty;

/// Whether [typed] confirms an erase: the erase word, trimmed with the JS whitespace set and in any case.
///
/// Web source: `erase.ts:59-61` (`confirmsErase`).
bool confirmsErase(String typed) => jsTrim(typed).toUpperCase() == RecordConstants.eraseWord;

bool _isRevision(Object? value) => value is String && _shortHash.hasMatch(value);

/// [data] with the day of [now] added to `days`, which stays distinct and sorted; a no-op when [now] has no real day
/// or the day is already there.
///
/// Web source: `events.ts:59-63` (`stampDay`).
RecordData _stampDay(RecordData data, String now) {
  final day = dayOf(now);
  if (day == null || data.days.contains(day)) return data;
  return _replace(data, 'days', List<Object?>.unmodifiable([...data.days, day]..sort()));
}

/// [data] with [slug]'s entry on [track] replaced by what [edit] returns for it (the empty sheet when there is no
/// entry), then the day of [now] stamped unless [now] is null.
///
/// Web source: `events.ts:70-83` (`editSheet`).
/// An unsafe [slug], or [edit] returning null, is a no-op that returns [data] itself.
/// An existing entry keeps its place in the map; a new one is appended last.
RecordData _editSheet(
  RecordData data,
  String slug,
  String? now,
  Map<String, Object?>? Function(Map<String, Object?> sheet) edit,
  Track track,
) {
  if (!isSafeKey(slug)) return data;
  final key = sheetsKey(track);
  final sheets = data.raw[key]! as Map<String, Object?>;
  final next = edit((sheets[slug] as Map<String, Object?>?) ?? RecordConstants.emptySheet);
  if (next == null) return data;
  final written = _replace(
    data,
    key,
    Map<String, Object?>.unmodifiable({...sheets, slug: Map<String, Object?>.unmodifiable(next)}),
  );
  return now == null ? written : _stampDay(written, now);
}

/// [data] with the top-level [key] set to [value] in its place; [value] must already be deeply unmodifiable.
RecordData _replace(RecordData data, String key, Object? value) =>
    RecordData.unchecked(Map<String, Object?>.unmodifiable({...data.raw, key: value}));
