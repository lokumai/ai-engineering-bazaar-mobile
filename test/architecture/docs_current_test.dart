import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the docs against drifting back to the template this app started from (Decisions A30 and A31).
///
/// - The written docs carry no em dash and no en dash (the repo's writing rule).
/// - The docs that describe the app name none of the template code the reader removed: an agent that reads
///   `CLAUDE.md` or the testing doc would otherwise reach for a class or a folder that no longer exists.
/// - The docs that only described removed template code (sign-in, the mock API, the template's screenshots and
///   diagrams) stay deleted.
/// - `README.md`, `CLAUDE.md` and `CHANGELOG.md` describe the reader: its content base URL, its two tools, its two
///   shared kernels and the heavy rule.
/// - `docs/testing-architecture.md` names every guard under `test/architecture/` and the device, conformance,
///   contract and smoke tests, so a new guard without a line in the doc fails here.
void main() {
  const written = [
    'README.md',
    'CLAUDE.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'docs/testing-architecture.md',
    'docs/feature-first-clean-boundaries.md',
    '.github/ISSUE_TEMPLATE/config.yml',
    '.github/ISSUE_TEMPLATE/bug_report.yml',
    '.github/ISSUE_TEMPLATE/tech_debt.yml',
  ];
  const describeTheApp = [
    'README.md',
    'CLAUDE.md',
    'CONTRIBUTING.md',
    'docs/testing-architecture.md',
    'docs/feature-first-clean-boundaries.md',
    '.github/ISSUE_TEMPLATE/config.yml',
    '.github/ISSUE_TEMPLATE/bug_report.yml',
    '.github/ISSUE_TEMPLATE/tech_debt.yml',
  ];
  const staleTerms = [
    'flutter_bloc_advance',
    'flutter-bloc-advanced',
    'Flutter BLoC Advance',
    'BLOC Template',
    'TestEnv.authenticate',
    'TestEnv.apiClient',
    'assets/mock',
    'AUTH_PROVIDER',
    'OIDC_',
    'browser_only',
    'LoginBloc',
    'UserListBloc',
    'LocaleCubit',
    'mock_asset_coverage_test',
    'shared_preferences',
  ];
  const removed = [
    'wiki.md',
    'docs/oidc.md',
    'docs/mock-architecture.md',
    'docs/REAL_API_INFO.md',
    'docs/screenshots',
    'docs/high-level-architecture.svg',
    'docs/dev-prod-usecase.svg',
    'docs/dev-prod-usecase.excalidraw',
    'docs/bloc-use-case.excalidraw',
    'docs/unittest.excalidraw',
    'docs/superpowers',
    'docs/archived',
  ];

  test('the docs carry no em dash and no en dash', () {
    final hits = [
      for (final path in written)
        for (final (i, line) in File(path).readAsLinesSync().indexed)
          if (line.contains(RegExp('[\u2013\u2014]'))) '$path:${i + 1}',
    ];
    expect(hits, isEmpty, reason: 'replace each with a comma, colon, full stop or hyphen:\n${hits.join('\n')}');
  });

  test('the docs that describe the app name no removed template code', () {
    final hits = [
      for (final path in describeTheApp)
        for (final term in staleTerms)
          if (File(path).readAsStringSync().contains(term)) '$path: $term',
    ];
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the docs that describe removed template code are gone', () {
    final left = [
      for (final path in removed)
        if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) path,
    ];
    expect(left, isEmpty, reason: left.join('\n'));
  });

  test('README, CLAUDE.md and CHANGELOG.md describe the reader', () {
    final readme = File('README.md').readAsStringSync();
    final claude = File('CLAUDE.md').readAsStringSync();
    final changelog = File('CHANGELOG.md').readAsStringSync();
    for (final s in ['CONTENT_BASE_URL', 'tool/refresh_content_snapshot.dart', 'tool/generate_tokens.dart', 'heavy ']) {
      expect(readme, contains(s), reason: 'README.md lacks $s');
    }
    for (final s in [
      'lib/shared/content',
      'lib/shared/record',
      'record.json.tmp',
      'assets/content/objects',
      'heavy',
      'Planned',
    ]) {
      expect(claude, contains(s), reason: 'CLAUDE.md lacks $s');
    }
    expect(changelog, contains('## [Unreleased]'));
    expect(changelog, contains('dev.lokumai.bazaar'));
  });

  test('docs/testing-architecture.md names every guard and the device, conformance, contract and smoke tests', () {
    final doc = File('docs/testing-architecture.md').readAsStringSync();
    final guards = [
      for (final file in Directory('test/architecture').listSync().whereType<File>())
        if (file.path.endsWith('_test.dart')) file.uri.pathSegments.last.replaceAll('.dart', ''),
    ];
    expect(guards, isNotEmpty, reason: 'the guard read no file under test/architecture');
    final missing = [
      for (final name in [
        ...guards,
        'integration_test/',
        'test/shared/record/conformance_test.dart',
        'test/fixtures/record_conformance/v1.json',
        'test/integration/app_smoke_test.dart',
        'test/support/accessibility.dart',
      ])
        if (!doc.contains(name)) name,
    ];
    expect(missing, isEmpty, reason: 'docs/testing-architecture.md does not name:\n${missing.join('\n')}');
  });
}
