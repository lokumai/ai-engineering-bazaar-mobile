import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';

import 'content_test_data.dart';

const _indexPath = 'api/v1/index.json';

Map<String, dynamic> _module(Map<String, dynamic> json) => (json['modules'] as List).first as Map<String, dynamic>;

Map<String, dynamic> _level(Map<String, dynamic> json) => (json['levels'] as List).first as Map<String, dynamic>;

Map<String, dynamic> _track(Map<String, dynamic> json, String id) =>
    (_module(json)['tracks'] as Map<String, dynamic>)[id] as Map<String, dynamic>;

BundleIndex _parse(Map<String, dynamic> json) => ContentParser.parseIndex(jsonEncode(json));

/// One rejection: a mutation of the valid index, the field it must be reported at, and why it is wrong.
typedef _Rejection = ({String field, String why, void Function(Map<String, dynamic> json) mutate});

final List<_Rejection> _rejections = [
  (field: 'schemaVersion', why: 'a major other than 1', mutate: (json) => json['schemaVersion'] = 2),
  (field: 'schemaVersion', why: 'a string', mutate: (json) => json['schemaVersion'] = '1'),
  (field: 'contentVersion', why: 'uppercase hex', mutate: (json) => json['contentVersion'] = 'A' * 64),
  (field: 'publishedAt', why: 'no milliseconds', mutate: (json) => json['publishedAt'] = '2026-01-02T03:04:05Z'),
  (field: 'publishedAt', why: 'a rolled date', mutate: (json) => json['publishedAt'] = '2026-02-31T03:04:05.000Z'),
  (field: 'sourceLanguage', why: 'missing', mutate: (json) => json.remove('sourceLanguage')),
  (
    field: 'translations[0].dir',
    why: 'a direction outside the closed set',
    mutate: (json) => json['translations'] = [
      {'id': 'tr', 'label': 'Turkish', 'dir': 'ttb'},
    ],
  ),
  (
    field: 'tracks',
    why: 'the everyone entry is missing',
    mutate: (json) => (json['tracks'] as List).removeWhere((t) => (t as Map)['id'] == 'everyone'),
  ),
  (
    field: 'diagramFont.family',
    why: 'a family other than Vazirmatn',
    mutate: (json) => (json['diagramFont'] as Map)['family'] = 'Inter',
  ),
  (
    field: 'diagramThemes.dark.background',
    why: 'a colour form the app does not read',
    mutate: (json) => ((json['diagramThemes'] as Map)['dark'] as Map)['background'] = 'rgb(0, 0, 0)',
  ),
  (
    field: 'levels[0].status',
    why: 'a status outside the closed set',
    mutate: (json) => _level(json)['status'] = 'retired',
  ),
  (field: 'levels[0].total', why: 'negative', mutate: (json) => _level(json)['total'] = -1),
  (
    field: 'levels[0].readme',
    why: 'a leading slash',
    mutate: (json) => _level(json)['readme'] = '/api/v1/levels/alpha.json',
  ),
  (
    field: 'levels[0].readme',
    why: 'absent from files',
    mutate: (json) => _level(json)['readme'] = 'api/v1/levels/beta.json',
  ),
  (field: 'modules[0].minutes', why: 'missing', mutate: (json) => _module(json).remove('minutes')),
  (field: 'modules[0].minutes', why: 'negative', mutate: (json) => _module(json)['minutes'] = -1),
  (field: 'modules[0].number', why: 'zero', mutate: (json) => _module(json)['number'] = 0),
  (field: 'modules[0].number', why: 'not whole', mutate: (json) => _module(json)['number'] = 1.5),
  (field: 'modules[0].level', why: 'an undeclared level', mutate: (json) => _module(json)['level'] = 'omega'),
  (field: 'modules[0].prerequisites[0]', why: 'not a string', mutate: (json) => _module(json)['prerequisites'] = [1]),
  (
    field: 'modules[0].tracks.everyone',
    why: 'the everyone track is missing',
    mutate: (json) => (_module(json)['tracks'] as Map).remove('everyone'),
  ),
  (
    field: 'modules[0].tracks.engineers.docs.en',
    why: 'the English document is missing',
    mutate: (json) => _track(json, 'engineers')['docs'] = <String, dynamic>{},
  ),
  (
    field: 'modules[0].tracks.everyone.docs.en',
    why: 'absent from files',
    mutate: (json) => _track(json, 'everyone')['docs'] = {'en': 'api/v1/missing.json'},
  ),
  (
    field: 'modules[0].tracks.engineers.revision.hash',
    why: 'three characters',
    mutate: (json) => (_track(json, 'engineers')['revision'] as Map)['hash'] = 'abc',
  ),
  (
    field: 'modules[0].tracks.engineers.revision.hash',
    why: 'uppercase hex',
    mutate: (json) => (_track(json, 'engineers')['revision'] as Map)['hash'] = 'ABC1234',
  ),
  (
    field: 'modules[0].tracks.engineers.revision.hash',
    why: 'forty-one characters',
    mutate: (json) => (_track(json, 'engineers')['revision'] as Map)['hash'] = 'a' * 41,
  ),
  (
    field: 'modules[0].tracks.engineers.revision.date',
    why: 'not a real day',
    mutate: (json) => (_track(json, 'engineers')['revision'] as Map)['date'] = '2026-13-01',
  ),
  (
    field: 'modules[0].tracks.engineers.drawn',
    why: 'not a bool',
    mutate: (json) => _track(json, 'engineers')['drawn'] = 'yes',
  ),
  (
    field: 'modules[0].tracks.engineers.webPath',
    why: 'whitespace in a site path',
    mutate: (json) => _track(json, 'engineers')['webPath'] = 'courses/alpha first/',
  ),
  (
    field: 'moved.modules.alpha/zeroth',
    why: 'not a string',
    mutate: (json) => ((json['moved'] as Map)['modules'] as Map)['alpha/zeroth'] = 1,
  ),
  (
    field: 'files.api/v1/levels/alpha.json',
    why: 'a sha256 one character short',
    mutate: (json) => (json['files'] as Map)['api/v1/levels/alpha.json'] = 'c' * 63,
  ),
  (
    field: 'files./api/v1/extra.json',
    why: 'a key that is not a site path',
    mutate: (json) => (json['files'] as Map)['/api/v1/extra.json'] = 'c' * 64,
  ),
  (
    field: 'images.course-images/alpha/figure.png',
    why: 'uppercase hex',
    mutate: (json) => (json['images'] as Map)['course-images/alpha/figure.png'] = 'E' * 64,
  ),
  (
    field: 'story.en',
    why: 'a story document the files do not list',
    mutate: (json) => json['story'] = {'en': 'api/v1/story/en.json'},
  ),
  (field: 'story', why: 'not an object', mutate: (json) => json['story'] = ['api/v1/story/en.json']),
];

void main() {
  test('parses a valid index', () {
    final index = ContentParser.parseIndex(jsonEncode(validIndexJson()));
    expect(index.contentVersion, 'a' * 64);
    expect(index.publishedAt, '2026-01-02T03:04:05.000Z');
    expect(index.publishedAtInstant, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(index.tracks, const [
      TrackInfo(track: Track.engineers, label: 'For Engineers'),
      TrackInfo(track: Track.everyone, label: 'For Everyone'),
    ]);
    expect(index.diagramFont, DiagramFont(family: 'Vazirmatn', sha256: 'b' * 64));
    expect(index.diagramThemes.light, const DiagramTheme(theme: 'default', backgroundArgb: 0xFFFFFFFF));
    expect(index.diagramThemes.light.backgroundArgb, 0xFFFFFFFF);
    expect(index.diagramThemes.dark.backgroundArgb, 0xFF333333);
    expect(index.level('alpha')!.status, LevelStatus.ready);
    expect(
      index.level('alpha'),
      const LevelEntry(
        slug: 'alpha',
        title: 'Alpha',
        status: LevelStatus.ready,
        blurb: '',
        total: 1,
        readme: 'api/v1/levels/alpha.json',
      ),
    );
    expect(index.level('omega'), isNull);
    final module = index.module('alpha/first')!;
    expect(module.level, 'alpha');
    expect(module.number, 1);
    expect(module.minutes, 12);
    expect(module.prerequisites, isEmpty);
    expect(module.tracks.keys, [Track.engineers, Track.everyone]);
    expect(module.tracks[Track.engineers]!.revision, const Revision(hash: 'abc1234', date: '2026-01-01'));
    expect(
      module.tracks[Track.engineers],
      const ModuleTrack(
        title: 'First Module',
        drawn: true,
        summary: null,
        hasQuiz: true,
        revision: Revision(hash: 'abc1234', date: '2026-01-01'),
        docs: {'en': 'api/v1/modules/alpha/first/en.json'},
        webPath: 'courses/alpha/first/',
      ),
    );
    expect(module.tracks[Track.everyone]!.docs, isEmpty);
    expect(module.tracks[Track.everyone]!.revision, isNull);
    expect(index.module('alpha/zeroth'), isNull);
    expect(index.moved.levels, {'gamma': 'alpha'});
    expect(index.moved.modules, {'alpha/zeroth': 'alpha/first'});
    expect(index.sha256Of('api/v1/levels/alpha.json'), 'c' * 64);
    expect(index.sha256Of('course-images/alpha/figure.png'), 'e' * 64);
    expect(index.sha256Of('api/v1/nothing.json'), isNull);
  });

  test('a parsed index cannot be changed', () {
    final index = _parse(validIndexJson());
    expect(() => index.modules.clear(), throwsUnsupportedError);
    expect(() => index.files.clear(), throwsUnsupportedError);
    expect(() => index.module('alpha/first')!.tracks.clear(), throwsUnsupportedError);
  });

  test('toString names only the version and the publication time', () {
    expect(_parse(validIndexJson()).toString(), 'BundleIndex(${'a' * 64}, 2026-01-02T03:04:05.000Z)');
  });

  test('ignores unknown keys and unknown tracks', () {
    final json = validIndexJson();
    json['extra'] = {'anything': true};
    _module(json)['extra'] = 1;
    _track(json, 'engineers')['extra'] = 'x';
    (json['tracks'] as List).add({'id': 'future', 'label': 'Future'});
    (_module(json)['tracks'] as Map<String, dynamic>)['future'] = {'shape': 'unknown'};
    expect(_parse(json), _parse(validIndexJson()));
  });

  test('reads translations it does not use', () {
    final json = validIndexJson();
    json['translations'] = [
      {'id': 'tr', 'label': 'Turkish', 'dir': 'ltr'},
      {'id': 'fa', 'label': 'Persian', 'dir': 'rtl'},
    ];
    expect(_parse(json), _parse(validIndexJson()));
  });

  test('accepts revision hashes of 4 and 40 hex characters (A24)', () {
    for (final hash in ['abcd', 'a' * 40]) {
      final json = validIndexJson();
      (_track(json, 'engineers')['revision'] as Map)['hash'] = hash;
      expect(_parse(json).module('alpha/first')!.tracks[Track.engineers]!.revision!.hash, hash);
    }
  });

  test('accepts a whole JSON number as an integer', () {
    final json = validIndexJson();
    _module(json)['number'] = 1.0;
    expect(_parse(json).module('alpha/first')!.number, 1);
  });

  test('accepts a level without a readme', () {
    final json = validIndexJson();
    _level(json)['readme'] = null;
    expect(_parse(json).level('alpha')!.readme, isNull);
  });

  test('reads the story documents the index names, and English when a language has none (web D125)', () {
    final json = validIndexJson();
    json['story'] = {'en': 'api/v1/levels/alpha.json'};
    final index = _parse(json);
    expect(index.story, {'en': 'api/v1/levels/alpha.json'});
    expect(index.storyIn('tr'), 'api/v1/levels/alpha.json');
  });

  test('an index from before the story names none (web D125)', () {
    final index = _parse(validIndexJson());
    expect(index.story, isEmpty);
    expect(index.storyIn('en'), isNull);
  });

  test('parseMajors reads the majors list', () => expect(ContentParser.parseMajors('{"majors":[1,2]}').majors, [1, 2]));

  test(
    'parseMajors rejects HTML',
    () => expect(() => ContentParser.parseMajors('<!doctype html>'), throwsA(formatError('api/index.json', '(json)'))),
  );

  test(
    'parseMajors rejects a major below 1',
    () =>
        expect(() => ContentParser.parseMajors('{"majors":[0]}'), throwsA(formatError('api/index.json', 'majors[0]'))),
  );

  test('rejects (json): an HTML page', () {
    expect(() => ContentParser.parseIndex('<html></html>'), throwsA(formatError(_indexPath, '(json)')));
  });

  test('rejects (root): not an object', () {
    expect(() => ContentParser.parseIndex('[]'), throwsA(formatError(_indexPath, '(root)')));
  });

  for (final rejection in _rejections) {
    test('rejects ${rejection.field}: ${rejection.why}', () {
      final json = validIndexJson();
      rejection.mutate(json);
      expect(() => _parse(json), throwsA(formatError(_indexPath, rejection.field)));
    });
  }

  group('word counts (web D128)', () {
    test("each language's words are read, and none is an empty map", () {
      final json = validIndexJson();
      _track(json, 'engineers')['words'] = {'en': 2754, 'tr': 2356};
      final tracks = _parse(json).module('alpha/first')!.tracks;
      expect(tracks[Track.engineers]!.words, {'en': 2754, 'tr': 2356});
      expect(tracks[Track.everyone]!.words, isEmpty);
    });

    test('a word count below one is refused', () {
      final json = validIndexJson();
      _track(json, 'engineers')['words'] = {'en': 0};
      expect(() => _parse(json), throwsA(formatError(_indexPath, 'modules[0].tracks.engineers.words.en')));
    });
  });
}
