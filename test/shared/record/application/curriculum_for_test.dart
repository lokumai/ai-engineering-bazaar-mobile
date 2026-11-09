import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter_test/flutter_test.dart';

LevelEntry _level(String slug, int total) =>
    LevelEntry(slug: slug, title: 'Title', status: LevelStatus.ready, blurb: 'Blurb', total: total, readme: null);

ModuleTrack _track({required bool drawn}) => ModuleTrack(
  title: 'Title',
  drawn: drawn,
  summary: null,
  hasQuiz: false,
  revision: null,
  docs: const {},
  webPath: 'courses/placeholder/',
);

ModuleEntry _module(String key, String level, int number, {required bool engineers, required bool everyone}) =>
    ModuleEntry(
      key: key,
      level: level,
      number: number,
      minutes: 10,
      prerequisites: const [],
      tracks: {
        Track.engineers: _track(drawn: engineers),
        Track.everyone: _track(drawn: everyone),
      },
    );

final _index = BundleIndex(
  contentVersion: 'a' * 64,
  publishedAt: '2026-01-02T03:04:05.000Z',
  publishedAtInstant: DateTime.utc(2026, 1, 2, 3, 4, 5),
  tracks: const [
    TrackInfo(track: Track.engineers, label: 'For Engineers'),
    TrackInfo(track: Track.everyone, label: 'For Everyone'),
  ],
  diagramFont: DiagramFont(family: 'Vazirmatn', sha256: 'b' * 64),
  diagramThemes: const DiagramThemes(
    light: DiagramTheme(theme: 'default', backgroundArgb: 0xFFFFFFFF),
    dark: DiagramTheme(theme: 'dark', backgroundArgb: 0xFF000000),
  ),
  levels: [_level('alpha', 2), _level('beta', 1)],
  modules: [
    _module('alpha/first', 'alpha', 1, engineers: true, everyone: true),
    _module('alpha/second', 'alpha', 2, engineers: true, everyone: false),
    _module('beta/first', 'beta', 3, engineers: false, everyone: false),
  ],
  moved: const Moved(levels: {}, modules: {}),
  files: const {},
  images: const {},
);

void main() {
  test('maps the levels and the modules in index order, drawn as the track has it', () {
    expect(
      curriculumFor(_index, Track.engineers),
      const Curriculum(
        levels: [
          LevelTotal(slug: 'alpha', total: 2),
          LevelTotal(slug: 'beta', total: 1),
        ],
        modules: [
          CurriculumFact(slug: 'alpha/first', number: 1, level: 'alpha', drawn: true),
          CurriculumFact(slug: 'alpha/second', number: 2, level: 'alpha', drawn: true),
          CurriculumFact(slug: 'beta/first', number: 3, level: 'beta', drawn: false),
        ],
      ),
    );
    expect(curriculumFor(_index, Track.everyone).modules.map((f) => f.drawn), [true, false, false]);
  });
}
