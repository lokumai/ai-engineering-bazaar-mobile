import 'dart:convert';

/// Whether [unit] is in the whitespace set of JS `String.prototype.trim`.
///
/// Dart's `String.trim` also strips U+0085 (NEL), which JS keeps (`m1-toolchain.md` 3.3.4), so the record code
/// trims with this set instead.
bool _isJsWhitespace(int unit) =>
    (unit >= 0x09 && unit <= 0x0D) ||
    unit == 0x20 ||
    unit == 0xA0 ||
    unit == 0x1680 ||
    (unit >= 0x2000 && unit <= 0x200A) ||
    unit == 0x2028 ||
    unit == 0x2029 ||
    unit == 0x202F ||
    unit == 0x205F ||
    unit == 0x3000 ||
    unit == 0xFEFF;

/// [text] without its leading and trailing whitespace, as JS `String.prototype.trim` removes it.
///
/// It keeps U+0085, which Dart's `String.trim` would remove.
String jsTrim(String text) {
  var start = 0;
  var end = text.length;
  while (start < end && _isJsWhitespace(text.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _isJsWhitespace(text.codeUnitAt(end - 1))) {
    end--;
  }
  return text.substring(start, end);
}

/// [bytes] decoded as the web's `new TextDecoder().decode` does: one leading BOM dropped, a second kept, a malformed
/// sequence replaced by U+FFFD; it never fails.
String decodeRecordBytes(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

/// Whether [key] may name a module in the record.
///
/// Web source: `schema.ts:140-148` (`isSafeKey`); both count UTF-16 code units.
bool isSafeKey(String key) =>
    key.isNotEmpty && key.length <= 200 && key != '__proto__' && key != 'constructor' && key != 'prototype';
