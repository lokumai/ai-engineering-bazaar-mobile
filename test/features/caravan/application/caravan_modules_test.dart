import 'package:ai_engineering_bazaar/features/caravan/application/caravan_modules.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

void main() {
  CaravanTrend trend(List<String> modules) =>
      CaravanTrend(id: 't', title: 't', text: 't', start: DateTime.utc(2024), end: null, peak: 3, modules: modules);

  final index = testIndex(
    modules: [
      testModule(key: 'alpha/first'),
      testModule(
        key: 'alpha/second',
        number: 2,
        tracks: {
          Track.engineers: const ModuleTrack(
            title: 'Second',
            drawn: true,
            summary: 'A summary.',
            hasQuiz: false,
            revision: null,
            docs: {'en': 'api/v1/modules/alpha/second/en.json'},
            titles: {'tr': 'İkinci'},
            webPath: 'courses/alpha/second/',
          ),
          Track.everyone: testModuleTrack(title: 'Second', drawn: false),
        },
      ),
    ],
  );

  test('a name finds the module whose key ends with it, titled in the language', () {
    expect(courseModules(trend(['second']), index, Track.engineers, 'tr'), const [
      CaravanModule(key: 'alpha/second', title: 'İkinci'),
    ]);
    expect(courseModules(trend(['second']), index, Track.engineers, 'fa').single.title, 'Second');
  });

  test('a name the course does not have is left out, and the order of the trend is kept', () {
    expect(courseModules(trend(['gone', 'second', 'first']), index, Track.engineers, 'en').map((m) => m.key), [
      'alpha/second',
      'alpha/first',
    ]);
  });

  test('a module named twice is linked once', () {
    expect(courseModules(trend(['first', 'first']), index, Track.engineers, 'en'), hasLength(1));
  });

  test('a module not written in the track is left out', () {
    expect(courseModules(trend(['second']), index, Track.everyone, 'en'), isEmpty);
  });
}
