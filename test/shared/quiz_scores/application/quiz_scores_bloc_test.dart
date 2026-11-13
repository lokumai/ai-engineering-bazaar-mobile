import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

const _kept = {'alpha/first': QuizScore(last: 2, best: 3, total: 3)};

void main() {
  late MemoryQuizScoreStore store;

  setUp(() => store = MemoryQuizScoreStore(_kept));

  blocTest<QuizScoresBloc, QuizScoresState>(
    'reads the kept scores at start',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc.add(const QuizScoresStarted()),
    expect: () => [const QuizScoresReady(_kept)],
  );

  blocTest<QuizScoresBloc, QuizScoresState>(
    'a finished attempt updates its quiz and is kept',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc
      ..add(const QuizScoresStarted())
      ..add(const QuizScoreRecorded(key: 'alpha/first', right: 1, total: 3))
      ..add(const QuizScoreRecorded(key: 'beta/fourth', right: 2, total: 2)),
    expect: () => [
      const QuizScoresReady(_kept),
      const QuizScoresReady({'alpha/first': QuizScore(last: 1, best: 3, total: 3, previous: 2)}),
      const QuizScoresReady({
        'alpha/first': QuizScore(last: 1, best: 3, total: 3, previous: 2),
        'beta/fourth': QuizScore(last: 2, best: 2, total: 2),
      }),
    ],
    verify: (_) async => expect((await store.load()).keys, ['alpha/first', 'beta/fourth']),
  );

  blocTest<QuizScoresBloc, QuizScoresState>(
    'an erase empties the scores and its undo brings them back',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc
      ..add(const QuizScoresStarted())
      ..add(const QuizScoresErased())
      ..add(const QuizScoresEraseUndone()),
    expect: () => [const QuizScoresReady(_kept), const QuizScoresReady({}), const QuizScoresReady(_kept)],
    verify: (_) async => expect(await store.load(), _kept),
  );

  blocTest<QuizScoresBloc, QuizScoresState>(
    'an erase again while the undo is open keeps the scores the first set aside',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc
      ..add(const QuizScoresStarted())
      ..add(const QuizScoresErased())
      ..add(const QuizScoreRecorded(key: 'beta/fourth', right: 1, total: 2))
      ..add(const QuizScoresErased(again: true))
      ..add(const QuizScoresEraseUndone()),
    skip: 4,
    expect: () => [const QuizScoresReady(_kept)],
  );

  blocTest<QuizScoresBloc, QuizScoresState>(
    'an undo with no erase changes nothing, and one after a new score brings the old scores back with the new one',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc
      ..add(const QuizScoresStarted())
      ..add(const QuizScoresEraseUndone())
      ..add(const QuizScoresErased())
      ..add(const QuizScoreRecorded(key: 'beta/fourth', right: 1, total: 2))
      ..add(const QuizScoresEraseUndone()),
    expect: () => [
      const QuizScoresReady(_kept),
      const QuizScoresReady({}),
      const QuizScoresReady({'beta/fourth': QuizScore(last: 1, best: 1, total: 2)}),
      const QuizScoresReady({..._kept, 'beta/fourth': QuizScore(last: 1, best: 1, total: 2)}),
    ],
  );

  blocTest<QuizScoresBloc, QuizScoresState>(
    'a quiz finished again after a reset keeps the better best and its last attempt on undo',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc
      ..add(const QuizScoresStarted())
      ..add(const QuizScoresErased())
      ..add(const QuizScoreRecorded(key: 'alpha/first', right: 1, total: 3))
      ..add(const QuizScoresEraseUndone()),
    skip: 3,
    expect: () => [
      const QuizScoresReady({'alpha/first': QuizScore(last: 1, best: 3, total: 3, previous: 2)}),
    ],
    verify: (_) async =>
        expect(await store.load(), {'alpha/first': const QuizScore(last: 1, best: 3, total: 3, previous: 2)}),
  );

  blocTest<QuizScoresBloc, QuizScoresState>(
    'a quiz opened at another length drops its old score, and one at the same length keeps it',
    build: () => QuizScoresBloc(store: store),
    act: (bloc) => bloc
      ..add(const QuizScoresStarted())
      ..add(const QuizLengthSeen(key: 'alpha/first', total: 3))
      ..add(const QuizLengthSeen(key: 'alpha/first', total: 4)),
    expect: () => [const QuizScoresReady(_kept), const QuizScoresReady({})],
  );

  test('a score of the loading state is none', () {
    expect(const QuizScoresLoading().of('alpha/first'), isNull);
    expect(const QuizScoresReady(_kept).of('alpha/first'), _kept['alpha/first']);
  });
}
