import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';

/// [value] as the web's `JSON.stringify(value)` writes it, byte for byte (spec 3.3.8).
///
/// Throws [ArgumentError] on a value that is not JSON (`null`, `bool`, `num`, `String`, `List`, a `Map` with
/// `String` keys).
String encodeCompact(Object? value) => _encode(value, null);

/// [value] as the web's `JSON.stringify(value, null, 2)` writes it: two-space indent, no trailing newline.
///
/// Same key order, number rule and errors as [encodeCompact].
String encodeExport(Object? value) => _encode(value, '');

/// The envelope `{schema, savedAt, data}` of [data], compact for storage or two-space for a backup file.
///
/// Web source: `store.ts:78-81` (`serialise`).
String serialise(RecordData data, String savedAt, {required bool pretty}) {
  final envelope = <String, Object?>{'schema': RecordConstants.schemaVersion, 'savedAt': savedAt, 'data': data.raw};
  return pretty ? encodeExport(envelope) : encodeCompact(envelope);
}

/// The name a backup made at [at] is saved under.
///
/// Web source: `store.ts:442-444` (`exportFilename`).
String exportFilename(String at) => 'hl-record-${at.substring(0, 10)}.json';

/// The largest integer a double holds exactly, 2^53.
const _maxSafe = 9007199254740992;

/// The largest array index plus one, 2^32 - 1: below it a canonical decimal key is an array index in JS.
const _indexLimit = 4294967295;

final _canonicalIndex = RegExp(r'^(?:0|[1-9][0-9]*)$');

String _encode(Object? value, String? indent) {
  final out = StringBuffer();
  out._write(value, indent);
  return out.toString();
}

extension on StringBuffer {
  /// Writes [value]; [indent] is null for the compact form, else the current container's indent.
  void _write(Object? value, String? indent) {
    switch (value) {
      case null:
        write('null');
      case bool():
        write(value);
      case String():
        write(jsonEncode(value));
      case num():
        write(_number(value));
      case List():
        _container('[', ']', [for (final item in value) (null, item)], indent);
      case Map():
        _container('{', '}', _ordered(value), indent);
      default:
        throw ArgumentError.value(value, 'value', 'not JSON');
    }
  }

  /// Writes a list (entries keyed by null) or a map, in the layout of [indent].
  void _container(String open, String close, List<(String?, Object?)> entries, String? indent) {
    if (entries.isEmpty) {
      write('$open$close');
      return;
    }
    final inner = indent == null ? null : '$indent  ';
    write(open);
    for (final (index, (key, item)) in entries.indexed) {
      if (index > 0) write(',');
      if (inner != null) write('\n$inner');
      if (key != null) {
        write(jsonEncode(key));
        write(inner == null ? ':' : ': ');
      }
      _write(item, inner);
    }
    if (indent != null) write('\n$indent');
    write(close);
  }
}

/// The entries of [map] in JS `Object.keys` order: the canonical array-index keys first, in ascending numeric order,
/// then the rest in insertion order.
List<(String?, Object?)> _ordered(Map<Object?, Object?> map) {
  final indexed = <(int, String)>[];
  final named = <String>[];
  for (final key in map.keys) {
    if (key is! String) throw ArgumentError.value(key, 'key', 'not a String');
    final index = _canonicalIndex.hasMatch(key) ? int.tryParse(key) : null;
    if (index != null && index < _indexLimit) {
      indexed.add((index, key));
    } else {
      named.add(key);
    }
  }
  indexed.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (_, key) in indexed) (key, map[key]), for (final key in named) (key, map[key])];
}

/// [value] as JS `JSON.stringify` prints a number (m1-toolchain.md 6.1(e)).
String _number(num value) {
  if (value is int) {
    if (value >= -_maxSafe && value <= _maxSafe) return '$value';
    return _double(value.toDouble());
  }
  return _double(value as double);
}

String _double(double value) {
  if (!value.isFinite) return 'null';
  if (value == 0) return '0';
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
