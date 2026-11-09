import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the package rename of commit 5 (spec 3.13): the app is `ai_engineering_bazaar`, and no file still imports
/// the template's package, which would stop resolving the moment the old name is gone from `pubspec.yaml`.
///
/// The old name is split so that this file does not carry it and stays out of `git grep`.
const _templatePackage =
    'flutter_bloc'
    '_advance';

void main() {
  test('pubspec.yaml names the package ai_engineering_bazaar', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^name: (\S+)$', multiLine: true).firstMatch(pubspec)?.group(1), 'ai_engineering_bazaar');
  });

  test('no file under lib/, test/, tool/ or integration_test/ names the template package', () {
    final offenders = <String>[
      for (final root in const ['lib', 'test', 'tool', 'integration_test'])
        if (Directory(root).existsSync())
          for (final file in Directory(root).listSync(recursive: true).whereType<File>())
            if (latin1.decode(file.readAsBytesSync()).contains('package:$_templatePackage/')) file.path,
    ];
    expect(offenders, isEmpty, reason: 'Import these through package:ai_engineering_bazaar/ instead.');
  });
}
