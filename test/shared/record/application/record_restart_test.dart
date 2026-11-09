import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spec 4.2 #3: a completion survives a cold restart, over the real file store.
void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('record_restart_'));
  tearDown(() async => dir.delete(recursive: true));

  test('the sign-off survives a cold restart', () async {
    await withClock(Clock.fixed(DateTime.utc(2026, 3, 14, 22, 30).toLocal()), () async {
      final first = RecordBloc(repository: FileRecordRepository(baseDirectory: () async => dir))
        ..add(const RecordStarted())
        ..add(const CompletionToggled(key: 'alpha/first', revision: 'a1b2c3d', track: Track.everyone));
      await first.stream.firstWhere(
        (state) => state is RecordReady && state.writeState == const WriteSaved() && state.record.days.isNotEmpty,
      );
      await first.close();

      final second = RecordBloc(repository: FileRecordRepository(baseDirectory: () async => dir))
        ..add(const RecordStarted());
      final state = await second.stream.firstWhere((state) => state is RecordReady) as RecordReady;
      expect(state.record.signedOff('alpha/first', Track.everyone), '2026-03-14T22:30:00.000Z');
      expect(state.record.signedOff('alpha/first', Track.engineers), isNull);
      await second.close();
    });
  });
}
