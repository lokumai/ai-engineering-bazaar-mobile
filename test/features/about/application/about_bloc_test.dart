import 'package:ai_engineering_bazaar/features/about/application/about_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/catalog_fixture_index.dart';

const _path = 'api/v1/story/en.json';

const _story = StoryDoc(
  lang: 'en',
  dir: TextDir.ltr,
  title: 'A Title',
  stalls: [
    StoryStall(heading: 'One.', paragraphs: ['First.']),
  ],
  motto: null,
);

void main() {
  late MockContentRepository repository;

  setUp(() => repository = MockContentRepository());

  blocTest<AboutBloc, AboutState>(
    'reads the English story for a language it is not written in',
    build: () {
      when(() => repository.readStoryDoc(_path)).thenAnswer((_) async => _story);
      return AboutBloc(
        repository: repository,
        index: catalogFixtureIndex(story: const {'en': _path}),
      );
    },
    act: (bloc) => bloc.add(const AboutOpened(language: 'tr')),
    expect: () => [const AboutReady(story: _story)],
  );

  blocTest<AboutBloc, AboutState>(
    'is absent when the content names no story (web D125)',
    build: () => AboutBloc(repository: repository, index: catalogFixtureIndex()),
    act: (bloc) => bloc.add(const AboutOpened(language: 'en')),
    expect: () => [const AboutAbsent()],
    verify: (_) => verifyNever(() => repository.readStoryDoc(any())),
  );

  for (final error in [
    const ContentMissingException(_path),
    const ContentCorruptException(_path),
    const ContentFormatException(_path, 'stalls'),
  ]) {
    blocTest<AboutBloc, AboutState>(
      'fails when the document cannot be read: ${error.runtimeType}',
      build: () {
        when(() => repository.readStoryDoc(_path)).thenThrow(error);
        return AboutBloc(
          repository: repository,
          index: catalogFixtureIndex(story: const {'en': _path}),
        );
      },
      act: (bloc) => bloc.add(const AboutOpened(language: 'en')),
      expect: () => [const AboutFailed()],
    );
  }
}
