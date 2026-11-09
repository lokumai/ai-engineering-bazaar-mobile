import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jsTrim strips the JS whitespace set and keeps U+0085', () {
    const set = [
      0x09,
      0x0A,
      0x0B,
      0x0C,
      0x0D,
      0x20,
      0xA0,
      0x1680,
      0x2000,
      0x2001,
      0x2002,
      0x2003,
      0x2004,
      0x2005,
      0x2006,
      0x2007,
      0x2008,
      0x2009,
      0x200A,
      0x2028,
      0x2029,
      0x202F,
      0x205F,
      0x3000,
      0xFEFF,
    ];
    for (final unit in set) {
      expect(jsTrim('${String.fromCharCode(unit)}x${String.fromCharCode(unit)}'), 'x', reason: '$unit');
    }
    expect(jsTrim('\u0085x\u0085'), '\u0085x\u0085');
    expect(jsTrim(' a b '), 'a b');
  });

  test('decodeRecordBytes drops one BOM, keeps a second and replaces a bad byte', () {
    expect(decodeRecordBytes([0xEF, 0xBB, 0xBF, 0x7B, 0xFF, 0x7D]), '{\uFFFD}');
    expect(decodeRecordBytes([0xEF, 0xBB, 0xBF, 0xEF, 0xBB, 0xBF, 0x7B, 0x7D]), '\uFEFF{}');
  });

  test('isSafeKey', () {
    for (final key in ['42', 'alpha/first', 'a' * 200]) {
      expect(isSafeKey(key), isTrue, reason: key);
    }
    for (final key in ['', 'a' * 201, '__proto__', 'constructor', 'prototype']) {
      expect(isSafeKey(key), isFalse, reason: key);
    }
  });
}
