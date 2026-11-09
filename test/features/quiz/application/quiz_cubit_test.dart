import 'package:ai_engineering_bazaar/features/quiz/application/quiz_cubit.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = ['One', 'Two', 'Three', 'Four'];
const items = [
  QuizItem(question: 'Q1', options: _options, answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: _options, answer: 1, explain: 'E2'),
  QuizItem(question: 'Q3', options: _options, answer: 2, explain: 'E3'),
];

void main() {
  test('starts on the first question with no picks', () {
    expect(QuizCubit(items).state, const QuizAsking(index: 0, picks: [null, null, null]));
  });

  blocTest<QuizCubit, QuizState>(
    'the first answer is final',
    build: () => QuizCubit(items),
    act: (c) => c
      ..pick(1)
      ..pick(0),
    expect: () => [
      const QuizAsking(index: 0, picks: [1, null, null]),
    ],
  );

  blocTest<QuizCubit, QuizState>(
    'next waits for an answer',
    build: () => QuizCubit(items),
    act: (c) => c.next(),
    expect: () => <QuizState>[],
  );

  blocTest<QuizCubit, QuizState>(
    'next and previous move between answered questions',
    build: () => QuizCubit(items),
    act: (c) => c
      ..pick(0)
      ..next()
      ..previous(),
    expect: () => [
      const QuizAsking(index: 0, picks: [0, null, null]),
      const QuizAsking(index: 1, picks: [0, null, null]),
      const QuizAsking(index: 0, picks: [0, null, null]),
    ],
  );

  blocTest<QuizCubit, QuizState>(
    'previous on the first question does nothing',
    build: () => QuizCubit(items),
    act: (c) => c.previous(),
    expect: () => <QuizState>[],
  );

  blocTest<QuizCubit, QuizState>(
    'next on the last question does nothing',
    build: () => QuizCubit(items),
    act: (c) => c
      ..go(2)
      ..pick(2)
      ..next(),
    expect: () => [
      const QuizAsking(index: 2, picks: [null, null, null]),
      const QuizAsking(index: 2, picks: [null, null, 2]),
    ],
  );

  blocTest<QuizCubit, QuizState>(
    'results only after the last answer, then back and restart',
    build: () => QuizCubit(items),
    act: (c) => c
      ..pick(0)
      ..next()
      ..pick(3)
      ..next()
      ..showResults()
      ..pick(2)
      ..showResults()
      ..backToQuestions()
      ..restart(),
    expect: () => [
      const QuizAsking(index: 0, picks: [0, null, null]),
      const QuizAsking(index: 1, picks: [0, null, null]),
      const QuizAsking(index: 1, picks: [0, 3, null]),
      const QuizAsking(index: 2, picks: [0, 3, null]),
      const QuizAsking(index: 2, picks: [0, 3, 2]),
      const QuizResults(picks: [0, 3, 2]),
      const QuizAsking(index: 2, picks: [0, 3, 2]),
      const QuizAsking(index: 0, picks: [null, null, null]),
    ],
  );

  blocTest<QuizCubit, QuizState>(
    'show results waits for the last question',
    build: () => QuizCubit(items),
    act: (c) => c
      ..pick(0)
      ..showResults(),
    expect: () => [
      const QuizAsking(index: 0, picks: [0, null, null]),
    ],
  );

  blocTest<QuizCubit, QuizState>(
    'next, previous and back to the questions do nothing outside their state',
    build: () => QuizCubit(items),
    act: (c) => c
      ..backToQuestions()
      ..go(2)
      ..pick(2)
      ..showResults()
      ..next()
      ..previous(),
    expect: () => [
      const QuizAsking(index: 2, picks: [null, null, null]),
      const QuizAsking(index: 2, picks: [null, null, 2]),
      const QuizResults(picks: [null, null, 2]),
    ],
  );

  test('score counts right answers', () {
    final c = QuizCubit(items)
      ..pick(0)
      ..next()
      ..pick(3)
      ..next()
      ..pick(2);
    expect(c.score, 2);
  });

  blocTest<QuizCubit, QuizState>(
    'go jumps to a question from the results',
    build: () => QuizCubit(items),
    act: (c) => c
      ..pick(0)
      ..next()
      ..pick(3)
      ..next()
      ..pick(2)
      ..showResults()
      ..go(1),
    skip: 6,
    expect: () => [
      const QuizAsking(index: 1, picks: [0, 3, 2]),
    ],
  );

  test('out-of-range input throws', () {
    expect(() => QuizCubit(items).go(3), throwsRangeError);
    expect(() => QuizCubit(items).go(-1), throwsRangeError);
    expect(() => QuizCubit(items).pick(4), throwsRangeError);
    expect(() => QuizCubit(items).pick(-1), throwsRangeError);
    expect(() => QuizCubit(const []), throwsArgumentError);
  });

  test('picks cannot be changed from outside', () {
    expect(() => QuizCubit(items).state.picks[0] = 1, throwsUnsupportedError);
    final c = QuizCubit(items)..pick(1);
    expect(() => c.state.picks[0] = 0, throwsUnsupportedError);
  });
}
