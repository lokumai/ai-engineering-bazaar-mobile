import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards that no Dart source writes an invisible or space character as a literal: the no-break space, the Unicode
/// spaces and format characters (U+2000 to U+200F, U+2028 to U+202F, U+205F to U+206F), the ideographic space, the
/// byte order mark and the interlinear and object replacement characters (U+FFF9 to U+FFFC).
///
/// Such a character reads as nothing, or as a plain space, in an editor and in a review diff, and an editor may drop
/// it. Sources write it as an escape such as `'\u2060'` instead. Generated code (`lib/generated/`) and the test
/// fixtures (`test/fixtures/`) are not hand-written and are not read.
final _invisible = RegExp('[\u00A0\u2000-\u200F\u2028-\u202F\u205F-\u206F\u3000\uFEFF\uFFF9-\uFFFC]');

/// Every invisible character of [source], as `<line>: U+XXXX`, in source order.
List<String> _invisibleIn(String source) {
  final lines = source.split('\n');
  return [
    for (var i = 0; i < lines.length; i++)
      for (final match in _invisible.allMatches(lines[i]))
        '${i + 1}: U+${match[0]!.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0')}',
  ];
}

void main() {
  final files = [
    for (final root in const ['lib', 'test', 'integration_test', 'tool'])
      ...Directory(root).listSync(recursive: true).whereType<File>().where((file) {
        final path = file.path.replaceAll(r'\', '/');
        return path.endsWith('.dart') && !path.startsWith('lib/generated/') && !path.startsWith('test/fixtures/');
      }),
  ]..sort((a, b) => a.path.compareTo(b.path));

  test('the matcher reports each invisible character with its line', () {
    final source = "final a = 'x';\nfinal b = '${String.fromCharCode(0x2060)}a${String.fromCharCode(0xFFFC)}';";

    expect(_invisibleIn(source), ['2: U+2060', '2: U+FFFC']);
    expect(_invisibleIn(r"final a = '\u2060 \uFFFC';"), isEmpty);
  });

  test('the guard reads lib/, test/, integration_test/ and tool/', () {
    for (final root in const ['lib/', 'test/', 'integration_test/', 'tool/']) {
      expect(files.any((file) => file.path.replaceAll(r'\', '/').startsWith(root)), isTrue, reason: root);
    }
  });

  test('no Dart source writes an invisible character as a literal', () {
    final violations = [
      for (final file in files)
        for (final found in _invisibleIn(file.readAsStringSync())) '${file.path.replaceAll(r'\', '/')}:$found',
    ];

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
