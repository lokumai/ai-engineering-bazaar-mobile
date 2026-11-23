import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Review 7, finding 6: the release scripts rewrote the sources (dart fix, dart format) and then built the store
/// binaries from them, with fewer checks than the gate. A store build now comes from a clean commit, after the gate.
void main() {
  for (final path in ['scripts/run_build.sh', 'scripts/run_fvm_build.sh']) {
    test('$path builds a store binary from a clean commit, after the gate, with the Sentry DSN', () {
      final script = File(path).readAsStringSync();
      expect(script, isNot(contains('dart fix')), reason: 'changes the sources');
      expect(script, isNot(contains('fvm dart format . --line-length=120\n')), reason: 'changes the sources');
      expect(script, contains('git status --porcelain'));
      expect(script, contains('fvm dart format . --line-length=120 --set-exit-if-changed'));
      expect(script, contains('fvm flutter analyze'));
      expect(script, contains('fvm flutter test --coverage'));
      expect(script, contains('scripts/check_coverage.sh coverage/lcov.info 90'));
      final builds = RegExp(r'fvm flutter build (apk|appbundle) .*').allMatches(script).map((match) => match[0]!);
      expect(builds, hasLength(2));
      for (final build in builds) {
        expect(build, contains('--dart-define-from-file=sentry_dsn.json'));
      }
    });
  }
}
