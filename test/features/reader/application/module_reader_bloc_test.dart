import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

const _firstEnglish = 'api/v1/modules/alpha/first/en.json';
const _firstTurkish = 'api/v1/modules/alpha/first/tr.json';
const _firstEveryone = 'api/v1/modules/alpha/first/everyone/en.json';
const _body = [
  ParagraphBlock(inlines: [TextInline(text: 'Body text.')], lead: false),
];

final first = testModule(
  tracks: {
    Track.engineers: testModuleTrack(
      revision: const Revision(hash: 'def5678', date: '2026-11-01'),
      docs: const {'en': _firstEnglish, 'tr': _firstTurkish},
    ),
    Track.everyone: testModuleTrack(
      revision: const Revision(hash: 'abc1234', date: '2026-11-02'),
      docs: const {'en': _firstEveryone},
      webPath: 'everyone/courses/alpha/first/',
    ),
  },
);

final second = testModule(
  key: 'alpha/second',
  number: 2,
  tracks: {
    Track.engineers: testModuleTrack(
      title: 'Second',
      drawn: false,
      docs: const {'en': 'api/v1/modules/alpha/second/en.json'},
    ),
    Track.everyone: testModuleTrack(title: 'Second', drawn: false, docs: const {}),
  },
);

final writtenDoc = testDoc(body: _body);
final everyoneDoc = testDoc(track: Track.everyone, body: _body);
final plannedDoc = testDoc(
  draft: const Draft(summary: 'The plan.', parts: ['Part one'], written: null),
);

void main() {
  late MockContentRepository repository;
  late MockRecordBloc recordBloc;
  late BundleIndex index;

  setUp(() {
    repository = MockContentRepository();
    recordBloc = MockRecordBloc();
    index = testIndex(modules: [first, second]);
  });

  ModuleReaderBloc build() => ModuleReaderBloc(repository: repository, index: index, recordBloc: recordBloc);

  test('starts loading', () {
    expect(build().state, const ReaderLoading());
  });

  blocTest<ModuleReaderBloc, ReaderState>(
    'a written module',
    build: build,
    setUp: () => when(() => repository.readModuleDoc(_firstEnglish)).thenAnswer((_) async => writtenDoc),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => [ReaderWritten(doc: writtenDoc, entry: first, moduleCount: 2)],
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'the For Everyone document of a written module',
    build: build,
    setUp: () => when(() => repository.readModuleDoc(_firstEveryone)).thenAnswer((_) async => everyoneDoc),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.everyone)),
    expect: () => [ReaderWritten(doc: everyoneDoc, entry: first, moduleCount: 2)],
  );

  group('the language (plan 1Q)', () {
    final turkishDoc = testDoc(body: _body, title: 'Birinci');

    blocTest<ModuleReaderBloc, ReaderState>(
      'opens the document in the language',
      build: build,
      setUp: () => when(() => repository.readModuleDoc(_firstTurkish)).thenAnswer((_) async => turkishDoc),
      act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers, language: 'tr')),
      expect: () => [ReaderWritten(doc: turkishDoc, entry: first, moduleCount: 2)],
    );

    blocTest<ModuleReaderBloc, ReaderState>(
      'opens a module not translated into the language in English',
      build: build,
      setUp: () => when(() => repository.readModuleDoc(_firstEveryone)).thenAnswer((_) async => everyoneDoc),
      act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.everyone, language: 'fa')),
      expect: () => [ReaderWritten(doc: everyoneDoc, entry: first, moduleCount: 2)],
    );
  });

  blocTest<ModuleReaderBloc, ReaderState>(
    'a module with a draft is planned',
    build: build,
    setUp: () => when(() => repository.readModuleDoc(_firstEnglish)).thenAnswer((_) async => plannedDoc),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => [ReaderPlanned(doc: plannedDoc, entry: first, moduleCount: 2)],
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'For Everyone with no document is not written',
    build: build,
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/second', track: Track.everyone)),
    expect: () => [ReaderNotWritten(entry: second)],
    verify: (_) => verifyNever(() => repository.readModuleDoc(any())),
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'an unknown key is not found',
    build: build,
    act: (bloc) => bloc.add(const ReaderOpened(key: 'omega/none', track: Track.engineers)),
    expect: () => [const ReaderNotFound()],
    verify: (_) => verifyNever(() => repository.readModuleDoc(any())),
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'For Engineers with no English document is not found',
    build: build,
    setUp: () => index = testIndex(
      modules: [
        testModule(tracks: {Track.engineers: testModuleTrack(docs: const {})}),
      ],
    ),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => [const ReaderNotFound()],
    verify: (_) => verifyNever(() => repository.readModuleDoc(any())),
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'a missing object fails with missing',
    build: build,
    setUp: () =>
        when(() => repository.readModuleDoc(_firstEnglish)).thenThrow(const ContentMissingException(_firstEnglish)),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => [const ReaderFailed(code: ContentErrorCode.missing)],
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'a corrupt object fails with corrupt',
    build: build,
    setUp: () =>
        when(() => repository.readModuleDoc(_firstEnglish)).thenThrow(const ContentCorruptException(_firstEnglish)),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => [const ReaderFailed(code: ContentErrorCode.corrupt)],
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'a document that does not parse fails with format',
    build: build,
    setUp: () =>
        when(() => repository.readModuleDoc(_firstEnglish))
            .thenThrow(const ContentFormatException(_firstEnglish, 'title')),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => [const ReaderFailed(code: ContentErrorCode.format)],
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'any other error is not a state of the content',
    build: build,
    setUp: () => when(() => repository.readModuleDoc(_firstEnglish)).thenThrow(StateError('fault')),
    act: (bloc) => bloc.add(const ReaderOpened(key: 'alpha/first', track: Track.engineers)),
    expect: () => <ReaderState>[],
    errors: () => [isA<StateError>()],
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'completion forwards the opened track and its revision',
    build: build,
    seed: () => ReaderWritten(doc: everyoneDoc, entry: first, moduleCount: 2),
    act: (bloc) => bloc.add(const ReaderCompletionToggled()),
    expect: () => <ReaderState>[],
    verify: (_) {
      final event = verify(() => recordBloc.add(captureAny())).captured.single as CompletionToggled;
      expect((event.key, event.revision, event.track), ('alpha/first', 'abc1234', Track.everyone));
      expect(event.everyone, isNull, reason: 'For Everyone never completes For Engineers (plan 1V)');
    },
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'completion of a For Engineers module carries its own revision',
    build: build,
    seed: () => ReaderWritten(doc: writtenDoc, entry: first, moduleCount: 2),
    act: (bloc) => bloc.add(const ReaderCompletionToggled()),
    verify: (_) {
      final event = verify(() => recordBloc.add(captureAny())).captured.single as CompletionToggled;
      expect((event.key, event.revision, event.track), ('alpha/first', 'def5678', Track.engineers));
      expect(event.everyone?.revision, 'abc1234', reason: 'the written For Everyone version goes with it (plan 1V)');
    },
  );

  blocTest<ModuleReaderBloc, ReaderState>(
    'completion outside a written module throws',
    build: build,
    seed: () => ReaderPlanned(doc: plannedDoc, entry: first, moduleCount: 2),
    act: (bloc) => bloc.add(const ReaderCompletionToggled()),
    errors: () => [isA<StateError>()],
    verify: (_) => verifyNever(() => recordBloc.add(any())),
  );
}
