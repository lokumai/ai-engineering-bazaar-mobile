import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/catalog_fixture_index.dart';

void main() {
  final index = catalogFixtureIndex();
  const now = '2026-11-09T10:00:00.000Z';

  RecordData completed(List<String> keys, {Track track = Track.engineers}) =>
      keys.fold(RecordData.empty, (record, key) => signOff(record, key, 'abc1234', now, track: track));

  test('the next module is the first written one not completed, with its level, place and track title', () {
    final next = homeOverview(index, Track.engineers, RecordData.empty).next!;

    expect(next.module.key, 'alpha/first');
    expect(next.level.slug, 'alpha');
    expect(next.position, 0);
    expect(next.title, 'First Module');
  });

  test('a completed module moves the next one on, past modules not written in the track', () {
    expect(homeOverview(index, Track.engineers, completed(['alpha/first'])).next!.module.key, 'alpha/second');
    expect(
      homeOverview(index, Track.engineers, completed(['alpha/first', 'alpha/second'])).next!.module.key,
      'beta/fourth',
      reason: 'alpha/third is not written For Engineers',
    );
  });

  test('each track has its own next module and title', () {
    final next = homeOverview(index, Track.everyone, completed(['alpha/first'], track: Track.everyone)).next!;

    expect(next.module.key, 'beta/fourth');
    expect(next.position, 1);
    expect(next.title, 'Fourth Story');
  });

  test('no next module once every written module of the track is completed', () {
    final record = completed(['alpha/first', 'alpha/second', 'beta/fourth', 'gamma/sixth']);

    expect(homeOverview(index, Track.engineers, record).next, isNull);
    expect(homeOverview(index, Track.everyone, record).next, isNotNull, reason: 'the other track is not completed');
  });

  test('the path counts each level\'s written modules in the track and how many are completed', () {
    final levels = homeOverview(index, Track.engineers, completed(['alpha/first', 'beta/fourth'])).levels;

    expect(
      [for (final level in levels) (level.level.slug, level.position, level.done, level.total)],
      [('alpha', 0, 1, 2), ('beta', 1, 1, 1), ('gamma', 2, 0, 1)],
      reason: 'alpha/third is not written For Engineers, so it is not on the path',
    );
  });

  test('after the next module come up to two more, written and not completed, in number order (plan 1P)', () {
    expect(
      [for (final entry in homeOverview(index, Track.engineers, RecordData.empty).after) entry.module.key],
      ['alpha/second', 'beta/fourth'],
      reason: 'alpha/third is not written For Engineers',
    );
    expect(
      [
        for (final entry in homeOverview(index, Track.engineers, completed(['alpha/second'])).after) entry.module.key,
      ],
      ['beta/fourth', 'gamma/sixth'],
      reason: 'a completed module is skipped',
    );
    expect(
      homeOverview(index, Track.engineers, completed(['alpha/first', 'alpha/second', 'beta/fourth'])).after,
      isEmpty,
      reason: 'gamma/sixth is the next one, and nothing comes after it',
    );
    expect(homeOverview(index, Track.everyone, RecordData.empty).after.first.title, 'Fourth Story');
  });

  group('practice (plan 1AD)', () {
    RecordData at(List<(String, String)> done, {Track track = Track.engineers}) =>
        done.fold(RecordData.empty, (record, entry) => signOff(record, entry.$1, 'abc1234', entry.$2, track: track));

    test('nothing to practise before a module is completed', () {
      expect(homeOverview(index, Track.engineers, RecordData.empty).practice, isEmpty);
    });

    test('the completed modules with a quiz, the most recently completed first, three at most', () {
      final record = at([
        ('alpha/first', '2026-11-01T10:00:00.000Z'),
        ('gamma/sixth', '2026-11-04T10:00:00.000Z'),
        ('alpha/second', '2026-11-03T10:00:00.000Z'),
        ('beta/fourth', '2026-11-02T10:00:00.000Z'),
      ]);

      final practice = homeOverview(index, Track.engineers, record).practice;
      expect([for (final entry in practice) entry.module.key], ['gamma/sixth', 'alpha/second', 'beta/fourth']);
      expect(practice.first.title, 'Sixth Module');
      expect(practice.first.position, 2);
    });

    test('with scores: a quiz never finished first, then the lowest last score, then the most recent (plan 1W)', () {
      final record = at([
        ('alpha/first', '2026-11-01T10:00:00.000Z'),
        ('gamma/sixth', '2026-11-04T10:00:00.000Z'),
        ('alpha/second', '2026-11-03T10:00:00.000Z'),
        ('beta/fourth', '2026-11-02T10:00:00.000Z'),
      ]);
      const scores = {
        'gamma/sixth': QuizScore(last: 4, best: 4, total: 4),
        'alpha/second': QuizScore(last: 1, best: 3, total: 4, previous: 3),
        'beta/fourth': QuizScore(last: 1, best: 2, total: 8),
      };

      final practice = homeOverview(index, Track.engineers, record, scores).practice;
      expect([for (final entry in practice) entry.module.key], ['alpha/first', 'beta/fourth', 'alpha/second']);
      expect(practice.first.score, isNull);
      expect(practice[1].score, scores['beta/fourth']);
    });

    test('a quiz once answered all right is not offered again', () {
      final record = at([('alpha/first', '2026-11-01T10:00:00.000Z'), ('alpha/second', '2026-11-03T10:00:00.000Z')]);
      const scores = {'alpha/second': QuizScore(last: 3, best: 4, total: 4, previous: 4)};

      final practice = homeOverview(index, Track.engineers, record, scores).practice;
      expect([for (final entry in practice) entry.module.key], ['alpha/first']);
    });

    test('two completed at the same instant keep their number order', () {
      final record = at([('beta/fourth', now), ('alpha/first', now)]);

      expect(
        [for (final entry in homeOverview(index, Track.engineers, record).practice) entry.module.key],
        ['alpha/first', 'beta/fourth'],
      );
    });

    test('a For Everyone reader practises the For Engineers quiz of the modules completed in their track', () {
      final record = at([('alpha/first', now)], track: Track.everyone);

      final practice = homeOverview(index, Track.everyone, record).practice;
      expect([for (final entry in practice) entry.module.key], ['alpha/first']);
      expect(practice.single.title, 'First Module', reason: 'the quiz is the For Engineers one');
      expect(homeOverview(index, Track.engineers, record).practice, isEmpty, reason: 'not completed For Engineers');
    });
  });
}
