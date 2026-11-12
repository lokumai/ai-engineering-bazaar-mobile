import 'package:ai_engineering_bazaar/features/quiz/application/quiz_loader.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/catalog_fixture_index.dart';
import '../../../support/content_builders.dart';

const _items = [
  QuizItem(question: 'Q1', options: ['One', 'Two'], answer: 0, explain: 'E1'),
];

void main() {
  late MockContentRepository repository;

  setUp(() => repository = MockContentRepository());

  QuizLoader loader() => QuizLoader(repository: repository, index: catalogFixtureIndex());

  blocTest<QuizLoader, QuizLoad>(
    'reads the For Engineers document and shows its quiz under the module title',
    setUp: () =>
        when(() => repository.readModuleDoc('api/v1/modules/alpha/first/en.json'))
            .thenAnswer((_) async => testDoc(quiz: _items)),
    build: loader,
    act: (loader) => loader.load('alpha/first', 'en'),
    expect: () => [const QuizReady(title: 'First Module', items: _items)],
  );

  blocTest<QuizLoader, QuizLoad>(
    'a language the module is not translated into reads the English document',
    setUp: () =>
        when(() => repository.readModuleDoc('api/v1/modules/alpha/first/en.json'))
            .thenAnswer((_) async => testDoc(quiz: _items)),
    build: loader,
    act: (loader) => loader.load('alpha/first', 'tr'),
    expect: () => [const QuizReady(title: 'First Module', items: _items)],
  );

  blocTest<QuizLoader, QuizLoad>(
    'For Everyone reads the For Everyone document, under its title there (web D137)',
    setUp: () =>
        when(() => repository.readModuleDoc('api/v1/modules/alpha/first/everyone/en.json'))
            .thenAnswer((_) async => testDoc(quiz: _items)),
    build: loader,
    act: (loader) => loader.load('alpha/first', 'en', track: Track.everyone),
    expect: () => [const QuizReady(title: 'First Story', items: _items)],
  );

  blocTest<QuizLoader, QuizLoad>(
    'For Everyone, a module not written there lends its For Engineers quiz, so a link to it still opens',
    setUp: () =>
        when(() => repository.readModuleDoc('api/v1/modules/alpha/second/en.json'))
            .thenAnswer((_) async => testDoc(quiz: _items)),
    build: loader,
    act: (loader) => loader.load('alpha/second', 'en', track: Track.everyone),
    expect: () => [const QuizReady(title: 'Second Module', items: _items)],
  );

  blocTest<QuizLoader, QuizLoad>(
    'a module without a quiz, or no such module, is missing and reads nothing',
    build: loader,
    act: (loader) async {
      await loader.load('alpha/third', 'en');
      await loader.load('alpha/nope', 'en');
    },
    expect: () => [const QuizMissing()],
    verify: (_) => verifyNever(() => repository.readModuleDoc(any())),
  );

  blocTest<QuizLoader, QuizLoad>(
    'a document whose quiz is empty is missing',
    setUp: () => when(() => repository.readModuleDoc(any())).thenAnswer((_) async => testDoc(quiz: const [])),
    build: loader,
    act: (loader) => loader.load('alpha/first', 'en'),
    expect: () => [const QuizMissing()],
  );

  for (final error in [
    ContentMissingException('gone'),
    ContentCorruptException('bad'),
    ContentFormatException('shape', 'quiz'),
  ]) {
    blocTest<QuizLoader, QuizLoad>(
      'a document that cannot be read is unreadable (${error.runtimeType})',
      setUp: () => when(() => repository.readModuleDoc(any())).thenThrow(error),
      build: loader,
      act: (loader) => loader.load('alpha/first', 'en'),
      expect: () => [const QuizUnreadable()],
    );
  }
}
