import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner decision O2 and plan Decision A5: a route path carries a module key, so no code records routes for analytics
/// or Sentry. Comment lines are skipped; a declaration of logScreenView in the analytics interface is not a call.
void main() {
  test('no code in lib/ records navigation for analytics or Sentry', () {
    final banned = RegExp(r'\bSentryNavigatorObserver\b|\bAnalyticsRouteObserver\b|\.logScreenView\(');
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/generated/'))
        .toList();
    final hits = [
      for (final file in files)
        for (final (index, line) in file.readAsLinesSync().indexed)
          if (!line.trimLeft().startsWith('//') && banned.hasMatch(line)) '${file.path}:${index + 1}: ${line.trim()}',
    ];

    expect(files, isNotEmpty, reason: 'the guard read no file');
    expect(hits, isEmpty);
  });
}
