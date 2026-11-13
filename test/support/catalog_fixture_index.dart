import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// A synthetic index built with the entity constructors (no file, no parser), for the shell, router and catalog tests:
/// three levels and six modules, some written in one track only and some planned in both; [story] names a story
/// document (web D125), none by default; [words] gives a module's For Engineers word counts per language (web D128),
/// none by default; [titles] gives a module's For Engineers titles per language (web D139), none by default.
BundleIndex catalogFixtureIndex({
  Map<String, String> story = const {},
  Map<String, Map<String, int>> words = const {},
  Map<String, Map<String, String>> titles = const {},
}) {
  return BundleIndex(
    story: story,
    contentVersion: 'f' * 64,
    publishedAt: '2026-11-01T00:00:00.000Z',
    publishedAtInstant: DateTime.utc(2026, 11, 1),
    tracks: const [
      TrackInfo(track: Track.engineers, label: 'For Engineers'),
      TrackInfo(track: Track.everyone, label: 'For Everyone'),
    ],
    diagramFont: DiagramFont(family: 'Vazirmatn', sha256: '0' * 64),
    diagramThemes: const DiagramThemes(
      light: DiagramTheme(theme: 'default', backgroundArgb: 0xFFFFFFFF),
      dark: DiagramTheme(theme: 'dark', backgroundArgb: 0xFF333333),
    ),
    levels: const [
      LevelEntry(
        slug: 'alpha',
        title: 'Alpha Level',
        status: LevelStatus.ready,
        blurb: 'A blurb.',
        total: 3,
        readme: null,
      ),
      LevelEntry(
        slug: 'beta',
        title: 'Beta Level',
        status: LevelStatus.ready,
        blurb: 'A blurb.',
        total: 2,
        readme: null,
      ),
      LevelEntry(
        slug: 'gamma',
        title: 'Gamma Level',
        status: LevelStatus.ready,
        blurb: 'A blurb.',
        total: 1,
        readme: null,
      ),
    ],
    modules: [
      _module(
        'alpha/first',
        words: words['alpha/first'] ?? const {},
        titles: titles['alpha/first'] ?? const {},
        number: 1,
        minutes: 20,
        prerequisites: const [],
        engineers: ('First Module', 'Summary of the first module.'),
        everyone: ('First Story', 'Story of the first module.'),
      ),
      _module(
        'alpha/second',
        words: words['alpha/second'] ?? const {},
        titles: titles['alpha/second'] ?? const {},
        number: 2,
        minutes: 25,
        prerequisites: const ['alpha/first'],
        engineers: ('Second Module', 'Summary of the second module.'),
        everyone: ('Second Story', null),
      ),
      _module(
        'alpha/third',
        words: words['alpha/third'] ?? const {},
        titles: titles['alpha/third'] ?? const {},
        number: 3,
        minutes: 30,
        prerequisites: const ['alpha/first', 'alpha/second'],
        engineers: ('Third Module', null),
        everyone: ('Third Story', null),
      ),
      _module(
        'beta/fourth',
        words: words['beta/fourth'] ?? const {},
        titles: titles['beta/fourth'] ?? const {},
        number: 4,
        minutes: 40,
        prerequisites: const ['alpha/third'],
        engineers: ('Fourth Module', 'Summary of the fourth module.'),
        everyone: ('Fourth Story', 'Story of the fourth module.'),
      ),
      _module(
        'beta/fifth',
        words: words['beta/fifth'] ?? const {},
        titles: titles['beta/fifth'] ?? const {},
        number: 5,
        minutes: 20,
        prerequisites: const [],
        engineers: ('Fifth Module', null),
        everyone: ('Fifth Story', null),
      ),
      _module(
        'gamma/sixth',
        words: words['gamma/sixth'] ?? const {},
        titles: titles['gamma/sixth'] ?? const {},
        number: 6,
        minutes: 45,
        prerequisites: const ['beta/fourth'],
        engineers: ('Sixth Module', 'Summary of the sixth module.'),
        everyone: ('Sixth Story', 'Story of the sixth module.'),
      ),
    ],
    moved: const Moved(levels: {}, modules: {}),
    files: const {},
    images: const {},
  );
}

const _revision = Revision(hash: 'abc1234', date: '2026-11-01');

/// A module whose track is drawn exactly when its summary is not null.
ModuleEntry _module(
  String key, {
  required int number,
  required int minutes,
  required List<String> prerequisites,
  required (String, String?) engineers,
  required (String, String?) everyone,
  Map<String, int> words = const {},
  Map<String, String> titles = const {},
}) {
  final (engineersTitle, engineersSummary) = engineers;
  final (everyoneTitle, everyoneSummary) = everyone;
  final engineersDrawn = engineersSummary != null;
  final everyoneDrawn = everyoneSummary != null;
  return ModuleEntry(
    key: key,
    level: key.split('/').first,
    number: number,
    minutes: minutes,
    prerequisites: prerequisites,
    tracks: {
      Track.engineers: ModuleTrack(
        title: engineersTitle,
        drawn: engineersDrawn,
        summary: engineersSummary,
        hasQuiz: engineersDrawn,
        words: words,
        titles: titles,
        revision: _revision,
        docs: {'en': 'api/v1/modules/$key/en.json'},
        webPath: 'courses/$key/',
      ),
      Track.everyone: ModuleTrack(
        title: everyoneTitle,
        drawn: everyoneDrawn,
        summary: everyoneSummary,
        hasQuiz: everyoneDrawn && engineersDrawn,
        revision: everyoneDrawn ? _revision : null,
        docs: everyoneDrawn ? {'en': 'api/v1/modules/$key/everyone/en.json'} : const {},
        webPath: 'everyone/courses/$key/',
      ),
    },
  );
}
