import 'dart:io';

import 'src/content_fixture.dart';

const _source = 'test/fixtures/content/src';
const _output = 'test/fixtures/content/bundle';

/// Writes the synthetic content bundle `test/fixtures/content/bundle/` from its sources in `test/fixtures/content/src/`.
/// Run it from the repository root after every change to a source:
///
///     fvm dart run tool/build_content_fixture.dart
void main() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() ||
      !RegExp(r'^name: ai_engineering_bazaar\s*$', multiLine: true).hasMatch(pubspec.readAsStringSync())) {
    stderr.writeln('run this from the root of the ai_engineering_bazaar repository');
    exitCode = 64;
    return;
  }
  buildContentFixture(source: Directory(_source), output: Directory(_output));
  final objects = Directory('$_output/objects').listSync().length;
  stdout.writeln('wrote $objects objects to $_output');
}
