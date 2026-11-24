import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:equatable/equatable.dart';

/// Why a stored record is set aside instead of read.
enum QuarantineReason {
  /// Written by a newer schema than this app reads.
  newer,

  /// Not a record envelope this app can read.
  malformed,
}

/// What a record text holds (the web's `ParseResult`).
sealed class EnvelopeResult extends Equatable {
  const EnvelopeResult();
}

/// No record: no text, or only whitespace.
final class EnvelopeEmpty extends EnvelopeResult {
  const EnvelopeEmpty();

  @override
  List<Object?> get props => const [];
}

/// A record envelope this app reads, with its data normalised.
final class EnvelopeOk extends EnvelopeResult {
  const EnvelopeOk({required this.data, required this.schema});

  final RecordData data;
  final int schema;

  @override
  List<Object?> get props => [data, schema];
}

/// A text set aside, with the reason and the text itself.
final class EnvelopeQuarantine extends EnvelopeResult {
  const EnvelopeQuarantine({required this.reason, required this.raw});

  final QuarantineReason reason;

  /// The text as it was given, kept so it can be copied aside unchanged.
  final String raw;

  @override
  List<Object?> get props => [reason, raw];
}

/// The envelope in [raw], read as the web's `parseEnvelope` reads it (`validate.ts:236-271`).
///
/// The launch read calls this alone; an imported file goes through [envelopeTextFrom] first (correction row 3.3.14).
EnvelopeResult parseEnvelope(String? raw) {
  if (raw == null || jsTrim(raw).isEmpty) return const EnvelopeEmpty();
  final malformed = EnvelopeQuarantine(reason: QuarantineReason.malformed, raw: raw);
  final Object? parsed;
  try {
    parsed = jsonDecode(raw);
  } on FormatException {
    return malformed;
  }
  if (parsed is! Map<String, Object?>) return malformed;
  final schema = _schemaOf(parsed['schema']);
  if (schema == null || schema < 1) return malformed;
  if (schema > RecordConstants.schemaVersion) return EnvelopeQuarantine(reason: QuarantineReason.newer, raw: raw);
  final data = parsed['data'];
  if (data is! Map<String, Object?>) return malformed;
  // A record is a few levels deep; a file nested far deeper is no record, and reading or writing it would recurse past
  // the stack, at a depth that differs from one machine to the next (review 7 finding 13, review 8 finding 1). It is
  // counted without recursion and refused, rather than ending the restore without a word.
  if (_deeperThan(data, maxRecordDepth)) return malformed;
  try {
    return EnvelopeOk(data: normaliseRecord(data), schema: schema.toInt());
  } on StackOverflowError {
    return malformed;
  }
}

/// The most levels of maps and lists a record's `data` may nest; the record itself uses about five.
const maxRecordDepth = 64;

/// Whether [value] nests maps and lists more than [limit] levels deep, counted with a list rather than the stack.
bool _deeperThan(Object? value, int limit) {
  final pending = <(Object?, int)>[(value, 1)];
  while (pending.isNotEmpty) {
    final (current, depth) = pending.removeLast();
    final children = switch (current) {
      Map() => current.values,
      List() => current,
      _ => null,
    };
    if (children == null) continue;
    if (depth > limit) return true;
    for (final child in children) {
      if (child is Map || child is List) pending.add((child, depth + 1));
    }
  }
  return false;
}

/// The schema number when it is an integer, as JS `Number.isInteger` decides, else null.
///
/// `jsonDecode('1e400')` is infinity and a large integer decodes as a double, so a finite double equal to its
/// truncation counts.
num? _schemaOf(Object? value) => switch (value) {
  int() => value,
  double() when value.isFinite && value == value.truncateToDouble() => value,
  _ => null,
};

/// The trimmed [input] when it starts like a JSON object, else null (`validate.ts:227-230`).
String? envelopeTextFrom(String input) {
  final text = jsTrim(input);
  return text.startsWith('{') ? text : null;
}
