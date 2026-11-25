@TestOn('linux || mac-os')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Review 7, finding 6: the release scripts rewrote the sources (dart fix, dart format) and then built the store
/// binaries from them, with fewer checks than the gate. A store build now comes from a clean commit, after the gate.
/// Review 8, finding 8: the DSN was checked for existence only, untracked files in the folders a build takes whole went
/// into it, nothing checked CI, and iOS had no script. The checks live in scripts/release_checks.sh, run here for real.
const _checks = 'scripts/release_checks.sh';

/// Runs [call] after sourcing the checks, in [dir], and gives the exit code with what it printed.
Future<(int, String)> _run(String call, Directory dir, {Map<String, String>? env}) async {
  final checks = File(_checks).absolute.path;
  final result = await Process.run(
    'bash',
    ['-c', 'set -euo pipefail; source "$checks"; $call'],
    workingDirectory: dir.path,
    environment: env,
  );
  return (result.exitCode, '${result.stdout}${result.stderr}');
}

Future<Directory> _repo() async {
  final dir = await Directory.systemTemp.createTemp('release_checks');
  addTearDown(() => dir.delete(recursive: true));
  Future<void> git(List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: dir.path);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }

  await git(['init', '-q']);
  await git(['config', 'user.email', 'test@example.test']);
  await git(['config', 'user.name', 'Test']);
  File('${dir.path}/assets/content/index.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{}');
  await git(['add', '.']);
  await git(['commit', '-q', '-m', 'start']);
  return dir;
}

void main() {
  for (final path in ['scripts/run_build.sh', 'scripts/run_fvm_build.sh', 'scripts/run_ios_build.sh']) {
    test('$path stops on the first failure, runs the checks and the gate, then builds with the Sentry DSN', () {
      final script = File(path).readAsStringSync();
      expect(script, contains('set -euo pipefail'));
      expect(script, isNot(contains('dart fix')), reason: 'changes the sources');
      expect(script, contains('source scripts/release_checks.sh'));
      final builds = RegExp(r'fvm flutter build (apk|appbundle|ipa) .*').allMatches(script).toList();
      expect(builds, hasLength(path.contains('ios') ? 1 : 2));
      final checks = script.indexOf('\nrelease_checks\n');
      final gate = script.indexOf('\nrelease_gate\n');
      expect(checks, isNonNegative);
      expect(gate, greaterThan(checks));
      for (final build in builds) {
        expect(build.start, greaterThan(gate));
        expect(build[0], contains('--dart-define-from-file=sentry_dsn.json'));
      }
    });
  }

  test('the checks are the DSN, a clean tree and CI, and the gate is the gate of CLAUDE.md', () {
    final checks = File(_checks).readAsStringSync();
    expect(checks, contains('release_dsn_check sentry_dsn.json\n  release_tree_check\n  release_ci_check'));
    expect(checks, isNot(contains('fvm dart format . --line-length=120\n')), reason: 'changes the sources');
    for (final step in [
      'fvm flutter pub get --enforce-lockfile',
      'fvm dart format . --line-length=120 --set-exit-if-changed',
      'fvm flutter analyze',
      'fvm flutter test --coverage',
      'scripts/check_coverage.sh coverage/lcov.info 90',
    ]) {
      expect(checks, contains(step));
    }
  });

  test('only the Mac leaves out the golden tests, and only them', () {
    final checks = File(_checks).readAsStringSync();
    final tests = RegExp(r'fvm flutter test .*').allMatches(checks).map((m) => m[0]).toList();
    expect(tests, ['fvm flutter test --coverage --exclude-tags golden', 'fvm flutter test --coverage']);
    expect(
      checks,
      contains(
        'if [ "\$(uname)" = "Darwin" ]; then\n    fvm flutter test --coverage --exclude-tags golden\n  else\n'
        '    fvm flutter test --coverage\n  fi',
      ),
    );
  });

  group('the DSN check', () {
    for (final (name, json, passes) in [
      ('a real DSN', '{"SENTRY_DSN": "https://0123abcd@o1.ingest.example.test/4567"}', true),
      ("the README's placeholder", '{"SENTRY_DSN": "<the project DSN>"}', false),
      ('an empty object', '{}', false),
      ('an http DSN', '{"SENTRY_DSN": "http://0123abcd@o1.ingest.example.test/4567"}', false),
      ('a DSN with no project', '{"SENTRY_DSN": "https://0123abcd@o1.ingest.example.test/"}', false),
    ]) {
      test('${passes ? 'takes' : 'refuses'} $name', () async {
        final dir = await Directory.systemTemp.createTemp('release_dsn');
        addTearDown(() => dir.delete(recursive: true));
        File('${dir.path}/sentry_dsn.json').writeAsStringSync(json);
        final (code, output) = await _run('release_dsn_check sentry_dsn.json', dir);
        expect(code, passes ? 0 : 1, reason: output);
      });
    }

    test('refuses a missing file', () async {
      final dir = await Directory.systemTemp.createTemp('release_dsn');
      addTearDown(() => dir.delete(recursive: true));
      final (code, output) = await _run('release_dsn_check sentry_dsn.json', dir);
      expect(code, 1);
      expect(output, contains('missing'));
    });
  });

  group('the tree check', () {
    test('takes a clean commit, and untracked files outside the folders a build takes', () async {
      final dir = await _repo();
      File('${dir.path}/linux/x').createSync(recursive: true);
      final (code, output) = await _run('release_tree_check', dir);
      expect(code, 0, reason: output);
    });

    test('refuses a changed file', () async {
      final dir = await _repo();
      File('${dir.path}/assets/content/index.json').writeAsStringSync('{"changed": true}');
      final (code, _) = await _run('release_tree_check', dir);
      expect(code, 1);
    });

    for (final folder in ['assets/content/objects', 'android/app/src/main/res/raw', 'ios/Runner', 'lib']) {
      test('refuses an untracked file under $folder', () async {
        final dir = await _repo();
        File('${dir.path}/$folder/stray').createSync(recursive: true);
        final (code, output) = await _run('release_tree_check', dir);
        expect(code, 1);
        expect(output, contains('$folder/stray'));
      });
    }
  });

  group('the CI check', () {
    test('refuses a commit on no remote branch', () async {
      final dir = await _repo();
      final (code, output) = await _run('release_ci_check', dir);
      expect(code, 1);
      expect(output, contains('no remote branch'));
    });

    test('takes a pushed commit checked by hand', () async {
      final dir = await _repo();
      final remote = await Directory.systemTemp.createTemp('release_remote');
      addTearDown(() => remote.delete(recursive: true));
      await Process.run('git', ['init', '-q', '--bare', remote.path]);
      await Process.run('git', ['remote', 'add', 'origin', remote.path], workingDirectory: dir.path);
      final push = await Process.run('git', ['push', '-q', 'origin', 'HEAD:main'], workingDirectory: dir.path);
      expect(push.exitCode, 0, reason: '${push.stderr}');
      await Process.run('git', ['fetch', '-q', 'origin'], workingDirectory: dir.path);
      final head = (await Process.run('git', ['rev-parse', 'HEAD'], workingDirectory: dir.path)).stdout.toString();
      final (code, output) = await _run('release_ci_check', dir, env: {'CI_CHECKED': head.trim()});
      expect(code, 0, reason: output);
    });
  });
}
