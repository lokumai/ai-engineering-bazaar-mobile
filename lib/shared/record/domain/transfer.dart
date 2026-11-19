/// The progress a transfer link carries between the website and the app (plan 17.1), and how it is added to a record.
///
/// The link is `<site>/transfer/#t=<payload>`; the payload is this file's compact text, deflated and in base64url
/// (the app's packer, `TransferPacker`). The website implements the same format (its `lib/record/transfer.ts`), so
/// the two never talk to each other: the progress travels in the fragment, which no browser sends to a server.
///
/// What is carried: per track, each module completed or with a checklist tick, its completion instant and revision
/// and its ticks; and the days. What is not: `reachedEnd` and `dwellSeconds` (observed, they gate nothing), `prefs`
/// (a fact about one browser or phone) and `meta`.
///
/// A transfer only adds (Merge): nothing on the receiving side is removed or replaced.
library;

import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/instant.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:equatable/equatable.dart';

/// The format version a link carries as `v`.
const transferVersion = 1;

/// The longest `t` value read; a longer one is refused before it is unpacked.
const transferMaxPayload = 16384;

/// The longest compact text read once unpacked.
const transferMaxText = 262144;

final _base36 = RegExp(r'^[0-9a-z]{1,11}$');
final _shortHash = RegExp(RecordConstants.shortHash);

/// One module's progress in a transfer.
final class TransferSheet extends Equatable {
  const TransferSheet({required this.signedOff, required this.signedRevision, required this.ticks});

  /// The completion instant, or null when the module is not completed.
  final String? signedOff;

  /// The revision at completion; null when [signedOff] is.
  final String? signedRevision;

  /// The checklist items ticked, ascending.
  final List<int> ticks;

  @override
  List<Object?> get props => [signedOff, signedRevision, ticks];
}

/// The progress a transfer link carries.
final class TransferProgress extends Equatable {
  const TransferProgress({required this.engineers, required this.everyone, required this.days});

  /// For Engineers, by module slug.
  final Map<String, TransferSheet> engineers;

  /// For Everyone, by module slug.
  final Map<String, TransferSheet> everyone;

  /// The days with activity, ascending.
  final List<String> days;

  /// The modules of [track] completed in this transfer.
  int completed(Track track) => _of(track).values.where((sheet) => sheet.signedOff != null).length;

  /// The checklist items ticked in [track], over every module (the owner, 2026-11-19: a link of ticks alone must not
  /// read as empty).
  int ticked(Track track) => _of(track).values.fold(0, (sum, sheet) => sum + sheet.ticks.length);

  /// Whether the transfer carries no progress at all.
  bool get isEmpty => engineers.isEmpty && everyone.isEmpty && days.isEmpty;

  Map<String, TransferSheet> _of(Track track) => track == Track.everyone ? everyone : engineers;

  @override
  List<Object?> get props => [engineers, everyone, days];
}

/// [data]'s progress as the compact text of a transfer: one JSON object, no whitespace, keys `v`, `e`, `y`, `d`.
///
/// Slugs are in ascending code-unit order; a module neither completed nor ticked is left out. A completion instant is
/// written as the base36 of its epoch milliseconds when it is the canonical `toISOString` form, else as it is.
String encodeTransfer(RecordData data) {
  List<Object> entry(String slug, Track track) {
    final signedOff = data.signedOff(slug, track);
    final sheet = (data.raw[sheetsKey(track)]! as Map<String, Object?>)[slug];
    final revision = sheet is Map ? sheet['signedRevision'] : null;
    return [
      signedOff == null ? '' : _packInstant(signedOff),
      signedOff != null && revision is String && _shortHash.hasMatch(revision) ? revision : '',
      data.ticks(slug, track).toList()..sort(),
    ];
  }

  Map<String, Object> track(Track track) {
    final slugs = (data.raw[sheetsKey(track)]! as Map<String, Object?>).keys.toList()..sort();
    return {
      for (final slug in slugs)
        if (data.signedOff(slug, track) != null || data.ticks(slug, track).isNotEmpty) slug: entry(slug, track),
    };
  }

  return jsonEncode({'v': transferVersion, 'e': track(Track.engineers), 'y': track(Track.everyone), 'd': data.days});
}

/// The progress in [text], or null when it is not a transfer this app reads: the whole text is refused when any part
/// of it fails, so nothing is ever partly applied.
TransferProgress? decodeTransfer(String text) {
  if (text.length > transferMaxText) return null;
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (json is! Map || json['v'] != transferVersion) return null;
  final engineers = _sheets(json['e']);
  final everyone = _sheets(json['y']);
  final days = _days(json['d']);
  if (engineers == null || everyone == null || days == null) return null;
  return TransferProgress(engineers: engineers, everyone: everyone, days: days);
}

/// [local] with [incoming] added: a module not here is added, a completion fills one that is not here (one already
/// here is kept with its own instant and revision), the ticks become the union, and the days the union.
/// `reachedEnd`, `dwellSeconds`, `prefs` and `meta` stay as they are. Returns [local] itself when nothing changes.
RecordData mergeTransfer(RecordData local, TransferProgress incoming) {
  var raw = local.raw;
  for (final track in Track.values) {
    final key = sheetsKey(track);
    final sheets = raw[key]! as Map<String, Object?>;
    final next = Map<String, Object?>.of(sheets);
    var changed = false;
    final sheetsIn = track == Track.everyone ? incoming.everyone : incoming.engineers;
    for (final MapEntry(key: slug, value: sheetIn) in sheetsIn.entries) {
      final here = sheets[slug];
      final merged = _mergeSheet(here is Map ? Map<String, Object?>.from(here) : null, sheetIn);
      if (merged == null) continue;
      next[slug] = merged;
      changed = true;
    }
    if (changed) raw = {...raw, key: Map<String, Object?>.unmodifiable(next)};
  }
  final days = {...local.days, ...incoming.days}.toList()..sort();
  if (days.length != local.days.length) raw = {...raw, 'days': List<Object?>.unmodifiable(days)};
  return identical(raw, local.raw) ? local : RecordData.unchecked(Map<String, Object?>.unmodifiable(raw));
}

/// The merged sheet, or null when [sheetIn] adds nothing to [here].
Map<String, Object?>? _mergeSheet(Map<String, Object?>? here, TransferSheet sheetIn) {
  if (sheetIn.signedOff == null && sheetIn.ticks.isEmpty) return null;
  final base = here ?? Map<String, Object?>.of(RecordConstants.emptySheet);
  var changed = here == null;
  if (asInstant(base['signedOff']) == null && sheetIn.signedOff != null) {
    base['signedOff'] = sheetIn.signedOff;
    base['signedRevision'] = sheetIn.signedRevision;
    changed = true;
  }
  final raw = base['checklist'];
  final checklist = raw is Map ? Map<String, Object?>.from(raw) : <String, Object?>{};
  for (final tick in sheetIn.ticks) {
    if (checklist['$tick'] == true) continue;
    checklist['$tick'] = true;
    changed = true;
  }
  if (!changed) return null;
  base['checklist'] = Map<String, Object?>.unmodifiable(checklist);
  return Map<String, Object?>.unmodifiable(base);
}

String _packInstant(String instant) {
  final ms = DateTime.tryParse(instant)?.millisecondsSinceEpoch;
  if (ms == null || ms < 0) return instant;
  return _isoOf(ms) == instant ? ms.toRadixString(36) : instant;
}

String _isoOf(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

Map<String, TransferSheet>? _sheets(Object? value) {
  if (value is! Map) return null;
  final sheets = <String, TransferSheet>{};
  for (final MapEntry(:key, :value) in value.entries) {
    if (key is! String || !isSafeKey(key) || value is! List || value.length != 3) return null;
    final [packed, revision, ticks] = value;
    if (packed is! String || revision is! String || ticks is! List) return null;
    final signedOff = _unpackInstant(packed);
    if (packed.isNotEmpty && signedOff == null) return null;
    if (revision.isNotEmpty && !_shortHash.hasMatch(revision)) return null;
    final picked = <int>{};
    for (final tick in ticks) {
      if (tick is! int || tick < 0 || tick > 9999) return null;
      picked.add(tick);
    }
    sheets[key] = TransferSheet(
      signedOff: signedOff,
      signedRevision: signedOff == null || revision.isEmpty ? null : revision,
      ticks: picked.toList()..sort(),
    );
  }
  return sheets;
}

String? _unpackInstant(String packed) {
  if (packed.isEmpty) return null;
  if (packed.contains('-')) return asInstant(packed);
  if (!_base36.hasMatch(packed)) return null;
  final ms = int.tryParse(packed, radix: 36);
  if (ms == null || ms > 8640000000000000) return null;
  return _isoOf(ms);
}

List<String>? _days(Object? value) {
  if (value is! List) return null;
  final days = <String>{};
  for (final day in value) {
    if (day is! String || !isRealDay(day)) return null;
    days.add(day);
  }
  return days.toList()..sort();
}

/// Packs a transfer's compact text into the link's payload and back: raw DEFLATE (RFC 1951) in base64url without
/// padding, as the website's `CompressionStream('deflate-raw')` makes it.
abstract interface class ITransferPacker {
  /// [text] as a link's payload.
  String pack(String text);

  /// The compact text in [payload], or null when it is longer than [transferMaxPayload], is not base64url, does not
  /// inflate, or inflates to more than [transferMaxText] bytes.
  String? unpack(String payload);
}
