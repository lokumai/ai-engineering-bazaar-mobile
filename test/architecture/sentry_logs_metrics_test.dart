import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Review 10, finding 10: sentry_flutter turns the iOS SDK's logs and metrics on, and Android has them off; neither is in
/// `docs/store-privacy.md`. No code writes one, and this guard keeps it so: a log or a metric sent to Sentry is a change
/// to the privacy doc first. Comment lines are skipped.
void main() {
  test('no code sends Sentry logs or metrics', () {
    final banned = RegExp(r'\bSentry(SDK)?\.(logger|metrics)\b');
    final files = [
      for (final root in ['lib', 'ios/Runner', 'android/app/src/main'])
        ...Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => RegExp(r'\.(dart|swift|kt)$').hasMatch(f.path) && !f.path.contains('/generated/')),
    ];
    final hits = [
      for (final file in files)
        for (final (index, line) in file.readAsLinesSync().indexed)
          if (!line.trimLeft().startsWith('//') && banned.hasMatch(line)) '${file.path}:${index + 1}: ${line.trim()}',
    ];

    expect(files.where((f) => f.path.endsWith('.swift')), isNotEmpty, reason: 'the guard read no Swift file');
    expect(files.where((f) => f.path.endsWith('.kt')), isNotEmpty, reason: 'the guard read no Kotlin file');
    expect(hits, isEmpty);
  });
}
