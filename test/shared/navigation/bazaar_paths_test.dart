import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // (location, trackOf)
  const rows = <(String, Track?)>[
    ('/', null),
    ('/sheets', Track.engineers),
    ('/sheets/alpha', Track.engineers),
    ('/courses/alpha/first', Track.engineers),
    ('/everyone/sheets', Track.everyone),
    ('/everyone/sheets/alpha', Track.everyone),
    ('/everyone/courses/alpha/first', Track.everyone),
    ('/practice', null),
    ('/settings', null),
    ('/courses', null),
    ('/courses/alpha', null),
    ('/everyone', null),
    ('/everyone/courses/alpha', null),
    ('/sheets/alpha/first', null),
    ('/nope', null),
  ];
  for (final (location, track) in rows) {
    for (final form in {location, if (location != '/') '$location/'}) {
      test('$form belongs to $track', () => expect(BazaarPaths.trackOf(form), track));
    }
  }
  test('builders', () {
    expect(BazaarPaths.home, '/');
    expect(BazaarPaths.catalog(Track.engineers), '/sheets');
    expect(BazaarPaths.catalog(Track.everyone), '/everyone/sheets');
    expect(BazaarPaths.level(Track.engineers, 'alpha'), '/sheets/alpha');
    expect(BazaarPaths.level(Track.everyone, 'alpha'), '/everyone/sheets/alpha');
    expect(BazaarPaths.module(Track.engineers, 'alpha/first'), '/courses/alpha/first');
    expect(BazaarPaths.module(Track.everyone, 'alpha/first'), '/everyone/courses/alpha/first');
    expect(BazaarPaths.practice, '/practice');
    expect(BazaarPaths.quiz('alpha/first'), '/quiz/alpha/first');
    expect(BazaarPaths.settings, '/settings');
  });

  test('levelOf and moduleOf read a level page and a module page in either track, and nothing else', () {
    for (final (location, level, module) in [
      ('/sheets/alpha', 'alpha', null),
      ('/everyone/sheets/alpha/', 'alpha', null),
      ('/courses/alpha/first', null, 'alpha/first'),
      ('/everyone/courses/alpha/first', null, 'alpha/first'),
      ('/sheets', null, null),
      ('/quiz/alpha/first', null, null),
      ('/', null, null),
    ]) {
      expect((BazaarPaths.levelOf(location), BazaarPaths.moduleOf(location)), (level, module), reason: location);
    }
  });
}
