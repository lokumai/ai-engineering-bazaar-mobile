import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/content_builders.dart';

void main() {
  const quiz = [
    QuizItem(question: 'Q', options: ['a', 'b'], answer: 0, explain: 'E'),
  ];

  test("reads every module written in the track, in the index's order, in the language or else English", () async {
    final index = testIndex(
      modules: [
        testModule(
          key: 'alpha/second',
          number: 2,
          tracks: {
            Track.engineers: testModuleTrack(docs: {'en': 'docs/second.en.json'}),
          },
        ),
        testModule(
          key: 'alpha/first',
          number: 1,
          tracks: {
            Track.engineers: testModuleTrack(docs: {'en': 'docs/first.en.json', 'tr': 'docs/first.tr.json'}),
          },
        ),
      ],
    );
    final repository = MockContentRepository();
    final read = <String>[];
    when(() => repository.readModuleDoc(any())).thenAnswer((call) async {
      read.add(call.positionalArguments.single as String);
      return testDoc(quiz: quiz);
    });
    final cubit = StudyNotesCubit(repository: repository);
    addTearDown(cubit.close);

    await cubit.load(index, Track.engineers, 'tr');
    expect(read, ['docs/first.tr.json', 'docs/second.en.json']);
    final ready = cubit.state as StudyNotesReady;
    expect([for (final notes in ready.modules) notes.moduleKey], ['alpha/first', 'alpha/second']);
    expect(ready.of('alpha/first')!.quiz, quiz);

    await cubit.load(index, Track.engineers, 'tr');
    expect(read, hasLength(2), reason: 'read once');
  });

  test('a module whose document cannot be read is left out; the others are read', () async {
    final index = testIndex(
      modules: [
        testModule(
          key: 'alpha/first',
          number: 1,
          tracks: {
            Track.engineers: testModuleTrack(docs: {'en': 'docs/first.en.json'}),
          },
        ),
        testModule(
          key: 'alpha/second',
          number: 2,
          tracks: {
            Track.engineers: testModuleTrack(docs: {'en': 'docs/second.en.json'}),
          },
        ),
      ],
    );
    final repository = MockContentRepository();
    when(() => repository.readModuleDoc('docs/first.en.json')).thenThrow(const ContentMissingException('x'));
    when(() => repository.readModuleDoc('docs/second.en.json')).thenAnswer((_) async => testDoc(quiz: quiz));
    final cubit = StudyNotesCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load(index, Track.engineers, 'en');
    expect([for (final notes in (cubit.state as StudyNotesReady).modules) notes.moduleKey], ['alpha/second']);
  });
}
