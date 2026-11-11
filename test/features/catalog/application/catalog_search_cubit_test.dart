@Tags(['unit'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search_cubit.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/content_builders.dart';

ModuleDoc _doc(String key, String title, String text) => testDoc(
  key: key,
  title: title,
  body: [
    ParagraphBlock(inlines: [TextInline(text: text)], lead: false),
  ],
);

void main() {
  late MockContentRepository repository;
  final index = testIndex(
    modules: [
      testModule(
        key: 'alpha/first',
        tracks: {
          Track.engineers: testModuleTrack(
            docs: {'en': 'api/v1/modules/alpha/first/en.json', 'tr': 'api/v1/modules/alpha/first/tr.json'},
          ),
        },
      ),
      testModule(key: 'alpha/second', number: 2),
      testModule(
        key: 'alpha/third',
        number: 3,
        tracks: {
          Track.engineers: testModuleTrack(docs: {'en': 'api/v1/modules/alpha/third/en.json'}),
          Track.everyone: testModuleTrack(drawn: false, docs: const {}),
        },
      ),
    ],
  );

  setUp(() {
    repository = MockContentRepository();
    when(() => repository.readModuleDoc('api/v1/modules/alpha/first/tr.json'))
        .thenAnswer((_) async => _doc('alpha/first', 'Birinci', 'Araç çağırma görevi.'));
    when(() => repository.readModuleDoc('api/v1/modules/alpha/first/en.json'))
        .thenAnswer((_) async => _doc('alpha/first', 'First', 'Tool swinging.'));
    when(() => repository.readModuleDoc('api/v1/modules/alpha/second/en.json'))
        .thenAnswer((_) async => _doc('alpha/second', 'Second', 'Tool use, in English only.'));
    when(() => repository.readModuleDoc('api/v1/modules/alpha/third/en.json'))
        .thenThrow(const ContentMissingException('api/v1/modules/alpha/third/en.json'));
  });

  CatalogSearchCubit cubit({String language = 'en', Track track = Track.engineers}) {
    final cubit = CatalogSearchCubit(repository: repository, bundle: index, track: track, language: language);
    addTearDown(cubit.close);
    return cubit;
  }

  test('starts with no query, showing the catalog', () {
    expect(cubit().state, const CatalogSearchState());
    expect(cubit().state.active, isFalse);
  });

  test(
    'reads the documents in the language, English where a module has none, and leaves out an unreadable one',
    () async {
      final search = cubit(language: 'tr');

      await search.search('arac');
      expect(search.state.results!.hits.map((h) => h.entry.module), ['Birinci']);

      await search.search('tool');
      expect(search.state.results!.hits.map((h) => h.entry.module), ['Second']);
      verifyNever(() => repository.readModuleDoc('api/v1/modules/alpha/first/en.json'));
    },
  );

  test('reads the documents once, for every query after the first', () async {
    final search = cubit();

    await search.search('tool');
    await search.search('swinging');

    verify(() => repository.readModuleDoc('api/v1/modules/alpha/first/en.json')).called(1);
    expect(search.state.results!.hits.single.entry.module, 'First');
  });

  test('says it is reading while the first query waits for the documents', () async {
    final gate = Completer<ModuleDoc>();
    when(() => repository.readModuleDoc('api/v1/modules/alpha/second/en.json')).thenAnswer((_) => gate.future);
    final search = cubit();

    final searching = search.search('tool');
    await pumpEventQueue();
    expect(search.state, const CatalogSearchState(query: 'tool', reading: true));
    expect(search.state.active, isTrue);

    gate.complete(_doc('alpha/second', 'Second', 'Tool use.'));
    await searching;
    expect(search.state.results!.hits, hasLength(2));
  });

  test('a query answered after a later one is dropped', () async {
    final gate = Completer<ModuleDoc>();
    when(() => repository.readModuleDoc('api/v1/modules/alpha/second/en.json')).thenAnswer((_) => gate.future);
    final search = cubit();

    final first = search.search('tool');
    final second = search.search('swinging');
    gate.complete(_doc('alpha/second', 'Second', 'Tool use.'));
    await Future.wait([first, second]);

    expect(search.state.query, 'swinging');
    expect(search.state.results!.hits.single.entry.module, 'First');
  });

  test('an empty query and clear go back to the catalog', () async {
    final search = cubit();

    await search.search('tool');
    await search.search('  ');
    expect(search.state, const CatalogSearchState());

    await search.search('tool');
    search.clear();
    expect(search.state, const CatalogSearchState());
  });

  test('a module with no document in the track is absent', () async {
    final search = cubit(track: Track.everyone);

    await search.search('tool');

    expect(search.state.results!.hits, isEmpty);
    verifyNever(() => repository.readModuleDoc('api/v1/modules/alpha/third/en.json'));
  });
}
