import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The arguments of every `Semantics(` call in [source], up to its `child:`.
Iterable<String> _semanticsArguments(String source) sync* {
  for (final match in RegExp(r'\bSemantics\(').allMatches(source)) {
    var depth = 1;
    var i = match.end;
    while (i < source.length && depth > 0) {
      final char = source[i];
      if (char == '(') depth++;
      if (char == ')') depth--;
      if (depth == 1 && source.startsWith('child:', i)) break;
      i++;
    }
    yield source.substring(match.end, i);
  }
}

/// Review 8, finding 4: a `Semantics` that says button or link and excludes its children's semantics drops the
/// InkWell's tap with them, so TalkBack, Switch Access and Voice Access announce a control they cannot activate. The
/// node must carry the tap itself.
void main() {
  test('a button or link that excludes its children carries its own tap', () {
    final silent = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.contains('/generated/')) continue;
      for (final arguments in _semanticsArguments(file.readAsStringSync())) {
        final control = arguments.contains('button: true') || arguments.contains('link: true');
        if (control && arguments.contains('excludeSemantics: true') && !arguments.contains('onTap:')) {
          silent.add('${file.path}: ${arguments.replaceAll(RegExp(r'\s+'), ' ').trim()}');
        }
      }
    }
    expect(silent, isEmpty, reason: silent.join('\n'));
  });
}
