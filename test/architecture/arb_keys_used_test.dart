import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every message in the template ARB is shown somewhere: some file under lib/ (outside the generated code) reads it as
/// `.<key>`. A key no code reads is copy no reader sees, and it is held to the copy register for nothing. The match is
/// a plain `.key` word, so it errs towards "read" (`ApplicationRoutesConstants.home` also matches `home`).
void main() {
  test('every message in intl_en.arb is read by lib/', () {
    final arb = jsonDecode(File('lib/l10n/intl_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = [
      for (final key in arb.keys)
        if (!key.startsWith('@')) key,
    ];
    final source = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.contains('/generated/')) file.readAsStringSync(),
    ].join('\n');

    expect(keys, contains('app_title'), reason: 'the guard read no message');
    final unread = [
      for (final key in keys)
        if (!RegExp('\\.$key\\b').hasMatch(source)) key,
    ];
    expect(unread, isEmpty, reason: 'remove these from intl_en.arb, or show them');
  });
}
