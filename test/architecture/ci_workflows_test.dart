import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Review 8, finding 18: the CI actions were taken by tag, which their owners can move; the bundle's upload-key guard
/// was only read as text; and CI built the Gradle file without a DSN, so its DSN branch was never built.
void main() {
  final workflows = Directory('.github/workflows').listSync().whereType<File>().where((f) => f.path.endsWith('.yml'));

  test('every action is pinned to a commit', () {
    expect(workflows, isNotEmpty);
    for (final workflow in workflows) {
      for (final use in RegExp(r'uses: (\S+)').allMatches(workflow.readAsStringSync())) {
        expect(use[1], matches(RegExp(r'^[\w.-]+/[\w.-]+@[0-9a-f]{40}$')), reason: '${workflow.path}: ${use[1]}');
      }
    }
  });

  test('CI checks that a bundle without the upload key stops, and builds the bundle with a DSN', () {
    final ci = File('.github/workflows/build_and_test.yml').readAsStringSync();
    expect(ci, contains('CI=false ./gradlew :app:bundleRelease -Ptarget=lib/main/main_prod.dart --dry-run'));
    expect(ci, contains("grep -q 'android/key.properties is missing' guard.log"));
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('"android/key.properties is missing, so this bundle would be signed with the debug key. "'),
    );
    const dsn = 'https://0123abcd@o1.ingest.example.invalid/4567';
    expect(ci, contains('--dart-define=SENTRY_DSN=$dsn'));
    expect(ci, contains('''grep -q 'SENTRY_DSN = "$dsn"\''''));
  });
}
