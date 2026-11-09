import 'dart:io';

import 'src/token_generator.dart';

const _output = 'lib/shared/design_system/bazaar_tokens.g.dart';

/// Writes `lib/shared/design_system/bazaar_tokens.g.dart` from the bundled snapshot's `api/v1/tokens.json`. Run it from
/// the repository root after every snapshot refresh:
///
///     fvm dart run tool/generate_tokens.dart
void main() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() ||
      !RegExp(r'^name: ai_engineering_bazaar\s*$', multiLine: true).hasMatch(pubspec.readAsStringSync())) {
    stderr.writeln('run this from the root of the ai_engineering_bazaar repository');
    exitCode = 64;
    return;
  }
  File(_output).writeAsStringSync(generateTokens(readBundledTokensJson('.')));
  stdout.writeln('Wrote $_output');
}
