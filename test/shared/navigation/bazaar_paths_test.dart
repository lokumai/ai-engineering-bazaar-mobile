import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // (location, trackOf, target for engineers, target for everyone)
  const rows = <(String, Track?, String?, String?)>[
    ('/', null, null, null),
    ('/sheets', Track.engineers, '/sheets', '/everyone/sheets'),
    ('/sheets/alpha', Track.engineers, '/sheets/alpha', '/everyone/sheets/alpha'),
    ('/courses/alpha/first', Track.engineers, '/courses/alpha/first', '/everyone/courses/alpha/first'),
    ('/everyone/sheets', Track.everyone, '/sheets', '/everyone/sheets'),
    ('/everyone/sheets/alpha', Track.everyone, '/sheets/alpha', '/everyone/sheets/alpha'),
    ('/everyone/courses/alpha/first', Track.everyone, '/courses/alpha/first', '/everyone/courses/alpha/first'),
    ('/quiz', null, null, null),
    ('/settings', null, null, null),
    ('/courses', null, null, null),
    ('/courses/alpha', null, null, null),
    ('/everyone', null, null, null),
    ('/everyone/courses/alpha', null, null, null),
    ('/sheets/alpha/first', null, null, null),
    ('/nope', null, null, null),
  ];
  for (final (location, track, toEngineers, toEveryone) in rows) {
    for (final form in {location, if (location != '/') '$location/'}) {
      test('$form belongs to $track and switches to $toEngineers / $toEveryone', () {
        expect(BazaarPaths.trackOf(form), track);
        expect(BazaarPaths.trackSwitchTarget(form, Track.engineers), toEngineers);
        expect(BazaarPaths.trackSwitchTarget(form, Track.everyone), toEveryone);
      });
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
    expect(BazaarPaths.quizzes, '/quiz');
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
