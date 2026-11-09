import 'package:flutter_test/flutter_test.dart';

import 'dart_code.dart';

void main() {
  group('stringLiterals', () {
    test('lists every literal with its line, outside comments', () {
      const source = '''
// 'in a line comment'
final a = 'one'; /* "in a block
comment" */ final b = "two";
final c = r'raw \\';
''';
      expect(stringLiterals(source), [(line: 2, text: 'one'), (line: 3, text: 'two'), (line: 4, text: r'raw \')]);
    });

    test('keeps escapes and interpolations as written and splits adjacent literals', () {
      const source = r"""final a = 'it\'s ${b('x')} $c' "next";""";
      expect(stringLiterals(source), [(line: 1, text: r"it\'s ${b('x')} $c"), (line: 1, text: 'next')]);
    });

    test('reads a triple-quoted literal across lines and counts the lines after it', () {
      const source = "final a = '''\nfirst\nsecond''';\nfinal b = '';\n";
      expect(stringLiterals(source), [(line: 1, text: '\nfirst\nsecond'), (line: 4, text: '')]);
    });

    test('an unterminated literal runs to the end of the source', () {
      expect(stringLiterals("final a = 'open"), [(line: 1, text: 'open')]);
    });
  });
}
