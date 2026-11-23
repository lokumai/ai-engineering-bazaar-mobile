import 'dart:io';

import 'package:ai_engineering_bazaar/features/caravan/application/caravan_modules.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/sample_trends.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';

/// Review 8, finding 3: the trends name modules with underscores, the bundle's keys have hyphens, and 14 trend cards
/// showed no module of the course; the test of the matching used one-word names only.
void main() {
  final index = ContentParser.parseIndex(File('assets/content/index.json').readAsStringSync());

  test('every module a trend names is a module of the bundled course', () {
    final missing = [
      for (final trend in SampleCaravan.trends('en'))
        for (final name in trend.modules)
          if (!index.modules.any((module) => module.key.split('/').last == name.replaceAll('_', '-'))) name,
    ];
    expect(missing, isEmpty);
  });

  test('a trend with a two-word module shows it', () {
    final trend = SampleCaravan.trends('en').firstWhere((trend) => trend.modules.any((name) => name.contains('_')));
    final name = trend.modules.firstWhere((name) => name.contains('_'));
    expect(
      courseModules(trend, index, Track.engineers, 'en').map((module) => module.key.split('/').last),
      contains(name.replaceAll('_', '-')),
    );
  });
}
