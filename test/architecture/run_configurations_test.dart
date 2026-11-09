import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards spec 3.7 and A32 for the committed IDE run configurations: `main_local` needs `CONTENT_BASE_URL`, and an
/// IDE run without it stops on the launch screen, so every `.run/*.xml` that starts `main_local.dart` passes it.
void main() {
  final configurations = [...Directory('.run').listSync().whereType<File>().where((file) => file.path.endsWith('.xml'))]
    ..sort((a, b) => a.path.compareTo(b.path));
  final local = [
    for (final file in configurations)
      if (file.readAsStringSync().contains('lib/main/main_local.dart')) file,
  ];

  test('a committed run configuration starts main_local', () => expect(local, isNotEmpty));

  test('every run configuration of main_local passes CONTENT_BASE_URL', () {
    for (final file in local) {
      expect(
        file.readAsStringSync(),
        contains('<option name="additionalArgs" value="--dart-define=CONTENT_BASE_URL=https://'),
        reason: file.path,
      );
    }
  });
}
