import 'package:ai_engineering_bazaar/features/home/application/home_overview.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
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

  test('every level in index order with its completed count, its total and the sum of its minutes', () {
    final levels = homeOverview(index, Track.engineers, completed(['alpha/first', 'alpha/second'])).levels;

    expect([for (final level in levels) level.level.slug], ['alpha', 'beta', 'gamma']);
    expect([for (final level in levels) level.position], [0, 1, 2]);
    expect([for (final level in levels) (level.completed, level.total)], [(2, 3), (0, 2), (0, 1)]);
    expect([for (final level in levels) level.minutes], [75, 60, 45]);
  });
}
