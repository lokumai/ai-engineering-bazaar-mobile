import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/token_generator.dart';

/// Guards spec 3.8: the committed tokens are what the generator makes from the snapshot's tokens.json, so a snapshot
/// refresh that changes a token cannot land without regenerating, and nobody edits the generated file.
void main() {
  test('bazaar_tokens.g.dart equals generateTokens over the bundled tokens.json', () {
    expect(
      File('lib/shared/design_system/bazaar_tokens.g.dart').readAsStringSync(),
      generateTokens(readBundledTokensJson('.')),
      reason: 'Run: fvm dart run tool/generate_tokens.dart',
    );
  });
}
