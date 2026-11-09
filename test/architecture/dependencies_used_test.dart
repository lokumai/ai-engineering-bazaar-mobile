import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Spec 3.5: a dependency without an importer goes. Every package pubspec.yaml lists is referenced as `package:<name>/`
/// from a Dart file under lib/, test/, tool/ or integration_test/, or from analysis_options.yaml, except the entries
/// below, each with its reason. An entry of _unusedOnPurpose that gains an importer fails, so it is deleted then.
const _usedWithoutImport = {'intl_utils': 'the ARB generator, run as fvm dart run intl_utils:generate'};
const _unusedOnPurpose = {
  'clock': 'the record clock, imported from Task 8.1',
  'bloc_test': 'the ContentBloc tests, imported from Task 7.5',
};

List<String> _section(String pubspec, String name) {
  final lines = pubspec.split('\n');
  final start = lines.indexOf('$name:');
  if (start == -1) throw StateError('pubspec.yaml has no $name section');
  return [
    for (final line in lines.skip(start + 1).takeWhile((line) => line.isEmpty || line.startsWith(' ')))
      if (RegExp(r'^  ([a-z0-9_]+):').firstMatch(line) case final match?) match.group(1)!,
  ];
}

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final packages = [..._section(pubspec, 'dependencies'), ..._section(pubspec, 'dev_dependencies')];
  final sources = [
    for (final root in const ['lib', 'test', 'tool', 'integration_test'])
      if (Directory(root).existsSync())
        for (final file in Directory(root).listSync(recursive: true).whereType<File>())
          if (file.path.endsWith('.dart')) file.readAsStringSync(),
    File('analysis_options.yaml').readAsStringSync(),
  ];
  bool imported(String name) => sources.any((source) => source.contains('package:$name/'));

  test('reads both dependency sections of pubspec.yaml', () {
    expect(packages, containsAll(['flutter', 'flutter_test', 'flutter_bloc', 'flutter_lints']));
  });

  test('every dependency has an importer', () {
    final unused = [
      for (final name in packages)
        if (!_usedWithoutImport.containsKey(name) && !_unusedOnPurpose.containsKey(name) && !imported(name)) name,
    ];
    expect(unused, isEmpty, reason: 'remove these from pubspec.yaml, or import them');
  });

  test('every package kept on purpose is still listed and still has no importer', () {
    for (final name in _unusedOnPurpose.keys) {
      expect(packages, contains(name), reason: '$name is gone from pubspec.yaml; delete its entry');
      expect(imported(name), isFalse, reason: '$name has an importer now; delete its entry');
    }
  });
}
