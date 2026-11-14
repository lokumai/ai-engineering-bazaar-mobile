import 'package:ai_engineering_bazaar/features/pocket_model/application/finished_modules.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

void main() {
  const now = '2026-11-14T12:00:00.000Z';
  // Every module of a real index carries both tracks.
  ModuleEntry module(String key, int number) => testModule(
    key: key,
    number: number,
    tracks: {
      Track.engineers: testModuleTrack(docs: {'en': 'api/v1/modules/$key/en.json'}, webPath: 'courses/$key/'),
      Track.everyone: testModuleTrack(docs: {'en': 'api/v1/everyone/$key/en.json'}, webPath: 'everyone/$key/'),
    },
  );
  final index = testIndex(modules: [module('alpha/third', 3), module('alpha/first', 1), module('alpha/second', 2)]);

  test('the modules completed in the track and not read, by number', () {
    var record = RecordData.empty;
    for (final key in ['alpha/third', 'alpha/first']) {
      record = signOff(record, key, null, now);
    }
    expect(finishedUnread(index: index, record: record, track: Track.engineers, model: PocketModel.fresh), [
      'alpha/first',
      'alpha/third',
    ]);

    final read = PocketModel.fresh.readAt('alpha/first', 100, DateTime.utc(2026, 11, 14));
    expect(finishedUnread(index: index, record: record, track: Track.engineers, model: read), ['alpha/third']);
  });

  test('none before a module is completed, and none from the other track', () {
    expect(
      finishedUnread(index: index, record: RecordData.empty, track: Track.engineers, model: PocketModel.fresh),
      isEmpty,
    );
    final record = signOff(RecordData.empty, 'alpha/first', null, now);
    expect(finishedUnread(index: index, record: record, track: Track.everyone, model: PocketModel.fresh), isEmpty);
  });
}
