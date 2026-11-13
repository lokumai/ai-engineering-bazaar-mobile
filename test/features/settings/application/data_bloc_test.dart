import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';

final _now = DateTime.utc(2026, 3, 15, 10);
const _nowIso = '2026-03-15T10:00:00.000Z';
const _noBytes = StoredBytes(record: null, quarantine: null);
final _backupBytes = Uint8List.fromList([123, 125]);
const _backupName = 'hl-record-2026-03-15.json';
const _restorable =
    '{"schema":1,"savedAt":"2026-03-15T10:00:00.000Z","data":{"sheets":{"alpha/first":{"signedOff":"2026-03-15T10:00:00.000Z"}}}}';

RecordReady _ready({RecordData record = RecordData.empty, EraseUndo? undo}) => RecordReady(
  record: record,
  writeState: const WriteSaved(),
  quarantine: null,
  quarantineKept: false,
  launchReadFailed: false,
  undo: undo,
);

PickedBackup _picked(String text) => PickedBackupBytes(bytes: Uint8List.fromList(utf8.encode(text)));

void main() {
  late MockRecordBloc recordBloc;
  late MockBackupGateway gateway;
  late MockRecordRepository repository;
  late RecordState recordState;
  late bool eraseSucceeds;
  late bool replaceSucceeds;
  late bool backupFails;

  setUp(() {
    recordBloc = readyRecordBloc() as MockRecordBloc;
    gateway = MockBackupGateway();
    repository = MockRecordRepository();
    recordState = _ready();
    eraseSucceeds = true;
    replaceSucceeds = true;
    backupFails = false;
    when(() => recordBloc.state).thenAnswer((_) => recordState);
    when(() => recordBloc.add(any())).thenAnswer((invocation) {
      switch (invocation.positionalArguments.first as RecordEvent) {
        case BackupStarted(:final reply):
          if (backupFails) {
            reply.completeError(StateError('the backup could not be made'));
          } else {
            reply.complete(RecordBackup(bytes: _backupBytes, filename: _backupName));
          }
        case RecordErased(:final at, :final reply):
          if (eraseSucceeds) {
            // As the record does: an erase while an undo is open keeps that undo, and says it is again.
            final open = recordState is RecordReady && (recordState as RecordReady).undo != null;
            recordState = _ready(
              undo: EraseUndo(at: at, bytes: _noBytes, data: RecordData.empty, again: open),
            );
          }
          reply?.complete(eraseSucceeds);
        // The undo is answered as the record's own is: open while the erase's undo is.
        case EraseUndone(:final reply):
          final open = recordState is RecordReady && (recordState as RecordReady).undo != null;
          if (open) recordState = _ready();
          reply?.complete(open);
        // A replacement is answered as the record's own is: done unless an erase waits in the queue.
        case RecordReplaced(:final reply):
          reply?.complete(replaceSucceeds);
        default:
      }
    });
  });

  DataBloc build() => DataBloc(recordBloc: recordBloc, gateway: gateway, repository: repository);

  /// Runs [body] on the fixed clock; the bloc is built inside it, so its handlers read that clock.
  Future<void> onClock(Future<void> Function() body) => withClock(Clock.fixed(_now), body);

  /// Runs [body] in `fakeAsync` on a clock that starts at [_now] and moves with the fake time.
  void onFakeClock(void Function(FakeAsync async) body) =>
      fakeAsync((async) => withClock(async.getClock(_now), () => body(async)));

  List<RecordEvent> added() => verify(() => recordBloc.add(captureAny())).captured.cast<RecordEvent>();

  group('back up', () {
    test('a saved backup marks the export and shows the day', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.saved);
        bloc.add(const BackupRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const DataState(busy: DataBusy.backingUp), const DataState(backup: BackedUp('2026-03-15'))]),
        );
        final events = added();
        expect(events.whereType<BackupStarted>().single.at, _nowIso);
        expect(events.whereType<BackupCompleted>().single.at, _nowIso);
        verify(() => gateway.save(Uint8List.fromList([123, 125]), _backupName)).called(1);
        await bloc.close();
      });
    });

    test('a shared backup marks the export', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.shared);
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        expect(added().whereType<BackupCompleted>(), hasLength(1));
        expect(bloc.state, const DataState(backup: BackedUp('2026-03-15')));
        await bloc.close();
      });
    });

    test('a dismissed sheet marks nothing and shows no line', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.dismissed);
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        expect(added().whereType<BackupCompleted>(), isEmpty);
        expect(bloc.state, const DataState());
        await bloc.close();
      });
    });

    test('a dismissed sheet keeps the previous backup line', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.saved);
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.dismissed);
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        expect(added().whereType<BackupCompleted>(), hasLength(1));
        expect(bloc.state, const DataState(backup: BackedUp('2026-03-15')));
        await bloc.close();
      });
    });

    test('a save that throws marks nothing and says so', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.save(any(), any())).thenThrow(PlatformException(code: 'x'));
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        expect(added().whereType<BackupCompleted>(), isEmpty);
        expect(bloc.state, const DataState(backup: BackupNotWritten()));
        await bloc.close();
      });
    });

    test('a backup the record could not make says so, and the line is not left busy (review B6)', () async {
      await onClock(() async {
        backupFails = true;
        final bloc = build();
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        verifyNever(() => gateway.save(any(), any()));
        expect(bloc.state, const DataState(backup: BackupNotWritten()));
        await bloc.close();
      });
    });

    test('a second request while a backup runs is dropped', () async {
      await onClock(() async {
        final bloc = build();
        final saved = Completer<BackupSaveResult>();
        when(() => gateway.save(any(), any())).thenAnswer((_) => saved.future);
        bloc
          ..add(const BackupRequested())
          ..add(const BackupRequested());
        await pumpEventQueue();
        saved.complete(BackupSaveResult.saved);
        await pumpEventQueue();
        expect(added().whereType<BackupStarted>(), hasLength(1));
        verify(() => gateway.save(any(), any())).called(1);
        await bloc.close();
      });
    });
  });

  group('restore', () {
    test('restore over a record that carries nothing replaces it at once', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(_restorable));
        bloc.add(const RestoreRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const DataState(busy: DataBusy.restoring), const DataState(restore: RestoreOutcome.restored)]),
        );
        final replaced = added().whereType<RecordReplaced>().single;
        expect(replaced.data.signedOff('alpha/first', Track.engineers), _nowIso);
        await bloc.close();
      });
    });

    test('a file the record did not take is not called restored (review B6)', () async {
      await onClock(() async {
        replaceSucceeds = false;
        final bloc = build();
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(_restorable));
        bloc.add(const RestoreRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const DataState(busy: DataBusy.restoring), const DataState(restore: RestoreOutcome.notRestored)]),
        );
        await bloc.close();
      });
    });

    test('a backup whose record is larger than the app writes is refused, and nothing is replaced', () async {
      await onClock(() async {
        final sheets = [for (var i = 0; i < 12000; i++) '"level/module-$i":{"signedOff":"2026-03-15T10:00:00.000Z"}']
            .join(',');
        final huge = '{"schema":1,"savedAt":"2026-03-15T10:00:00.000Z","data":{"sheets":{$sheets}}}';
        final bloc = build();
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(huge));
        bloc.add(const RestoreRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const DataState(busy: DataBusy.restoring), const DataState(restore: RestoreOutcome.tooLarge)]),
        );
        verifyNever(() => recordBloc.add(any()));
        await bloc.close();
      });
    });

    test('restore over a record that carries something waits for confirmation with the tally', () async {
      await onClock(() async {
        recordState = _ready(record: signOff(RecordData.empty, 'alpha/first', null, _nowIso));
        final bloc = build();
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(_restorable));
        bloc.add(const RestoreRequested());
        await pumpEventQueue();
        expect(bloc.state.busy, DataBusy.idle);
        expect(bloc.state.restore, isNull);
        expect(bloc.state.pendingRestore!.local, const Tally(sheets: 1));
        expect(bloc.state.pendingRestore!.data.signedOff('alpha/first', Track.engineers), _nowIso);
        verifyNever(() => recordBloc.add(any(that: isA<RecordReplaced>())));

        bloc.add(const RestoreConfirmed());
        await pumpEventQueue();
        expect(added().whereType<RecordReplaced>(), hasLength(1));
        expect(bloc.state, const DataState(restore: RestoreOutcome.restored));
        await bloc.close();
      });
    });

    test('a declined restore changes nothing', () async {
      await onClock(() async {
        recordState = _ready(record: signOff(RecordData.empty, 'alpha/first', null, _nowIso));
        final bloc = build();
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(_restorable));
        bloc.add(const RestoreRequested());
        await pumpEventQueue();
        expect(bloc.state.pendingRestore, isNotNull);
        bloc.add(const RestoreDeclined());
        await pumpEventQueue();
        expect(bloc.state, const DataState());
        verifyNever(() => recordBloc.add(any(that: isA<RecordReplaced>())));
        await bloc.close();
      });
    });

    test('a confirmation with nothing waiting changes nothing', () async {
      await onClock(() async {
        final bloc = build();
        bloc.add(const RestoreConfirmed());
        await pumpEventQueue();
        expect(bloc.state, const DataState());
        verifyNever(() => recordBloc.add(any()));
        await bloc.close();
      });
    });

    test('restore refusals change nothing', () async {
      await onClock(() async {
        final cases = <PickedBackup, RestoreOutcome>{
          _picked('<!doctype html><p>x</p>'): RestoreOutcome.empty,
          _picked('{"unrelated": true}'): RestoreOutcome.malformed,
          _picked('{"schema":99,"savedAt":"2026-03-15T10:00:00.000Z","data":{}}'): RestoreOutcome.newer,
          const PickedBackupUnreadable(): RestoreOutcome.unreadable,
        };
        for (final MapEntry(key: picked, value: outcome) in cases.entries) {
          final bloc = build();
          when(() => gateway.pickJson()).thenAnswer((_) async => picked);
          bloc.add(const RestoreRequested());
          await pumpEventQueue();
          expect(bloc.state, DataState(restore: outcome), reason: '$picked');
          await bloc.close();
        }

        final bloc = build();
        when(() => gateway.pickJson()).thenAnswer((_) async => const PickedBackupCancelled());
        final states = <DataState>[];
        final subscription = bloc.stream.listen(states.add);
        bloc.add(const RestoreRequested());
        await pumpEventQueue();
        expect(states, [const DataState(busy: DataBusy.restoring), const DataState()]);
        verifyNever(() => recordBloc.add(any(that: isA<RecordReplaced>())));
        await subscription.cancel();
        await bloc.close();
      });
    });

    test('restore before the record is read is an error', () async {
      await onClock(() async {
        recordState = const RecordLoading();
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(_restorable));
        final errors = <Object>[];
        late DataBloc bloc;
        await runZonedGuarded(() async {
          bloc = build()..add(const RestoreRequested());
          await pumpEventQueue();
        }, (error, _) => errors.add(error));
        expect(errors.single, isA<StateError>());
        expect(bloc.state, const DataState());
        verifyNever(() => recordBloc.add(any()));
        await bloc.close();
      });
    });
  });

  group('reset', () {
    test('the reset erases the quiz scores with the record, and its undo brings them back (plan 1W)', () {
      onFakeClock((async) {
        const kept = {'alpha/first': QuizScore(last: 2, best: 3, total: 3)};
        final scores = QuizScoresBloc(store: MemoryQuizScoreStore(kept))..add(const QuizScoresStarted());
        final bloc = DataBloc(recordBloc: recordBloc, gateway: gateway, repository: repository, scores: scores);
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady(kept));

        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady({}));

        bloc.add(const UndoRequested());
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady(kept));

        eraseSucceeds = false;
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady(kept), reason: 'a reset that did not erase keeps the scores');
        bloc.close();
        scores.close();
        async.flushMicrotasks();
      });
    });

    test('a second reset while the undo is open keeps the scores and places the first set aside', () {
      onFakeClock((async) {
        const kept = {'alpha/first': QuizScore(last: 2, best: 3, total: 3)};
        final place = ReadingPlace(heading: 'h', offset: 0, share: 0.5, at: _now);
        final scores = QuizScoresBloc(store: MemoryQuizScoreStore(kept))..add(const QuizScoresStarted());
        final places = ReadingPlacesBloc(store: MemoryReadingPlaceStore({'engineers:alpha/first': place}))
          ..add(const ReadingPlacesStarted());
        final bloc = DataBloc(
          recordBloc: recordBloc,
          gateway: gateway,
          repository: repository,
          scores: scores,
          places: places,
        );
        async.flushMicrotasks();

        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady({}));

        bloc.add(const UndoRequested());
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady(kept), reason: 'not the empty scores of the second reset');
        expect(places.state, ReadingPlacesReady({'engineers:alpha/first': place}));
        bloc.close();
        scores.close();
        places.close();
        async.flushMicrotasks();
      });
    });

    test('an undo the record no longer takes brings back neither the scores nor the places', () {
      onFakeClock((async) {
        const kept = {'alpha/first': QuizScore(last: 2, best: 3, total: 3)};
        final scores = QuizScoresBloc(store: MemoryQuizScoreStore(kept))..add(const QuizScoresStarted());
        final bloc = DataBloc(recordBloc: recordBloc, gateway: gateway, repository: repository, scores: scores);
        async.flushMicrotasks();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();

        // The record's window closed a moment before the line caught up.
        recordState = _ready();
        bloc.add(const UndoRequested());
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady({}), reason: 'never half a reset undone');
        bloc.close();
        scores.close();
        async.flushMicrotasks();
      });
    });

    test('a reset whose page closes while it waits still erases the scores with the record', () {
      onFakeClock((async) {
        const kept = {'alpha/first': QuizScore(last: 2, best: 3, total: 3)};
        final scores = QuizScoresBloc(store: MemoryQuizScoreStore(kept))..add(const QuizScoresStarted());
        final reply = Completer<bool>();
        when(() => recordBloc.add(any())).thenAnswer((invocation) {
          if (invocation.positionalArguments.first case RecordErased(reply: final done?)) {
            reply.future.then(done.complete);
          }
        });
        final bloc = DataBloc(recordBloc: recordBloc, gateway: gateway, repository: repository, scores: scores);
        async.flushMicrotasks();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        bloc.close();
        async.flushMicrotasks();
        reply.complete(true);
        async.flushMicrotasks();
        expect(scores.state, const QuizScoresReady({}));
        scores.close();
        async.flushMicrotasks();
      });
    });

    test('the reset erases the reading places with the record, and its undo brings them back (plan 1BA)', () {
      onFakeClock((async) {
        final kept = {'engineers:alpha/first': ReadingPlace(offset: 300, share: 0.4, at: DateTime.utc(2026, 11, 11))};
        final places = ReadingPlacesBloc(store: MemoryReadingPlaceStore(kept))..add(const ReadingPlacesStarted());
        final bloc = DataBloc(recordBloc: recordBloc, gateway: gateway, repository: repository, places: places);
        async.flushMicrotasks();
        expect(places.state, ReadingPlacesReady(kept));

        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect(places.state, const ReadingPlacesReady({}));

        bloc.add(const UndoRequested());
        async.flushMicrotasks();
        expect(places.state, ReadingPlacesReady(kept));
        bloc.close();
        places.close();
        async.flushMicrotasks();
      });
    });

    test('reset counts down from the record undo and closes at ten seconds', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect(bloc.state.reset, const ResetCounting(10));
        expect(added().whereType<RecordErased>().single.at, _now);
        async.elapse(const Duration(milliseconds: 1250));
        expect(bloc.state.reset, const ResetCounting(9));
        async.elapse(const Duration(seconds: 9));
        expect(bloc.state.reset, const ResetClosed());
        verifyNever(() => recordBloc.add(any(that: isA<UndoExpired>())));
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('the line closes when the record closes the window', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 4));
        expect(bloc.state.reset, const ResetCounting(6));
        recordState = _ready();
        async.elapse(const Duration(milliseconds: 250));
        expect(bloc.state.reset, const ResetClosed());
        async.elapse(const Duration(seconds: 20));
        expect(bloc.state.reset, const ResetClosed());
        verifyNever(() => recordBloc.add(any(that: isA<UndoExpired>())));
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('a reset whose files cannot be deleted says so and offers no undo', () {
      onFakeClock((async) {
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.saved);
        final bloc = build();
        bloc.add(const BackupRequested());
        async.flushMicrotasks();
        expect(bloc.state, const DataState(backup: BackedUp('2026-03-15')));

        eraseSucceeds = false;
        final states = <DataState>[];
        final subscription = bloc.stream.listen(states.add);
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect(states, [
          const DataState(busy: DataBusy.erasing, backup: BackedUp('2026-03-15')),
          const DataState(backup: BackedUp('2026-03-15'), reset: ResetNotFinished()),
        ]);
        async.elapse(const Duration(seconds: 20));
        expect(bloc.state, const DataState(backup: BackedUp('2026-03-15'), reset: ResetNotFinished()));
        expect(states, hasLength(2));
        verifyNever(() => recordBloc.add(any(that: isA<EraseUndone>())));
        verifyNever(() => recordBloc.add(any(that: isA<UndoExpired>())));
        subscription.cancel();
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('a reset whose files cannot be read still counts down', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        expect((recordState as RecordReady).undo!.bytes, _noBytes);
        expect(bloc.state, const DataState(reset: ResetCounting(10)));
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('undo within the window restores and clears the line', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(bloc.state.reset, const ResetCounting(7));
        bloc.add(const UndoRequested());
        async.flushMicrotasks();
        expect(added().whereType<EraseUndone>(), hasLength(1));
        expect(bloc.state, const DataState());
        expect(async.periodicTimerCount, 0);
        final states = <DataState>[];
        final subscription = bloc.stream.listen(states.add);
        async.elapse(const Duration(seconds: 20));
        expect(states, isEmpty);
        subscription.cancel();
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('undo once the line closed does nothing', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 11));
        expect(bloc.state.reset, const ResetClosed());
        bloc.add(const UndoRequested());
        async.flushMicrotasks();
        verifyNever(() => recordBloc.add(any(that: isA<EraseUndone>())));
        expect(bloc.state.reset, const ResetClosed());
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('a restore closes an open undo', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        when(() => gateway.pickJson()).thenAnswer((_) async => _picked(_restorable));
        bloc.add(const RestoreRequested());
        async.flushMicrotasks();
        expect(bloc.state, const DataState(restore: RestoreOutcome.restored));
        expect(added().whereType<RecordReplaced>(), hasLength(1));
        expect(async.periodicTimerCount, 0);
        final states = <DataState>[];
        final subscription = bloc.stream.listen(states.add);
        async.elapse(const Duration(seconds: 20));
        expect(states, isEmpty);
        verifyNever(() => recordBloc.add(any(that: isA<UndoExpired>())));
        subscription.cancel();
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('reset clears the backup and restore lines', () async {
      await onClock(() async {
        final bloc = build();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.saved);
        when(() => gateway.pickJson()).thenAnswer((_) async => const PickedBackupUnreadable());
        bloc.add(const BackupRequested());
        await pumpEventQueue();
        bloc.add(const RestoreRequested());
        await pumpEventQueue();
        expect(bloc.state, const DataState(backup: BackedUp('2026-03-15'), restore: RestoreOutcome.unreadable));
        bloc.add(const ResetConfirmed());
        await pumpEventQueue();
        expect(bloc.state, const DataState(reset: ResetCounting(10)));
        await bloc.close();
      });
    });

    test('an erase that answers after the bloc closed starts no countdown', () {
      onFakeClock((async) {
        final reply = Completer<bool>();
        when(() => recordBloc.add(any())).thenAnswer((invocation) {
          if (invocation.positionalArguments.first case RecordErased(:final at, reply: final done?)) {
            recordState = _ready(
              undo: EraseUndo(at: at, bytes: _noBytes, data: RecordData.empty),
            );
            reply.future.then(done.complete);
          }
        });
        final errors = <Object>[];
        runZonedGuarded(() {
          final bloc = build();
          bloc.add(const ResetConfirmed());
          async.flushMicrotasks();
          bloc.close();
          async.flushMicrotasks();
          reply.complete(true);
          async.elapse(const Duration(seconds: 2));
        }, (error, _) => errors.add(error));
        expect(async.periodicTimerCount, 0);
        expect(errors, isEmpty);
      });
    });

    test('closing the bloc stops the countdown', () {
      onFakeClock((async) {
        final bloc = build();
        bloc.add(const ResetConfirmed());
        async.flushMicrotasks();
        bloc.close();
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 0);
      });
    });
  });

  group('the set-aside record', () {
    test('the set-aside bytes are saved as they are', () async {
      await onClock(() async {
        final bloc = build();
        when(() => repository.readStored())
            .thenAnswer((_) async => StoredBytes(record: null, quarantine: Uint8List.fromList([1, 2, 3])));
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.saved);
        bloc.add(const QuarantineExportRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            const DataState(busy: DataBusy.savingQuarantine),
            const DataState(quarantineCopy: QuarantineCopy.saved),
          ]),
        );
        verify(() => gateway.save(Uint8List.fromList([1, 2, 3]), 'hl-record-quarantine-2026-03-15.json')).called(1);
        verifyNever(() => recordBloc.add(any()));
        await bloc.close();
      });
    });

    test('a set-aside copy that is not written says so', () async {
      await onClock(() async {
        when(() => repository.readStored())
            .thenAnswer((_) async => StoredBytes(record: null, quarantine: Uint8List.fromList([1, 2, 3])));

        final failing = build();
        when(() => gateway.save(any(), any())).thenThrow(PlatformException(code: 'x'));
        failing.add(const QuarantineExportRequested());
        await pumpEventQueue();
        expect(failing.state, const DataState(quarantineCopy: QuarantineCopy.notWritten));
        await failing.close();

        final dismissed = build();
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.dismissed);
        dismissed.add(const QuarantineExportRequested());
        await pumpEventQueue();
        expect(dismissed.state, const DataState());
        await dismissed.close();
        verifyNever(() => recordBloc.add(any()));
      });
    });

    test('set-aside bytes that cannot be read say the copy was not written', () async {
      await onClock(() async {
        final bloc = build();
        when(() => repository.readStored()).thenAnswer((_) async => throw const FileSystemException('read failed'));
        bloc.add(const QuarantineExportRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            const DataState(busy: DataBusy.savingQuarantine),
            const DataState(quarantineCopy: QuarantineCopy.notWritten),
          ]),
        );
        verifyNever(() => gateway.save(any(), any()));
        await bloc.close();
      });
    });

    test('a request with no set-aside bytes is an error', () async {
      await onClock(() async {
        when(() => repository.readStored()).thenAnswer((_) async => _noBytes);
        final errors = <Object>[];
        late DataBloc bloc;
        await runZonedGuarded(() async {
          bloc = build()..add(const QuarantineExportRequested());
          await pumpEventQueue();
        }, (error, _) => errors.add(error));
        expect(errors.single, isA<StateError>());
        expect(bloc.state, const DataState());
        verifyNever(() => gateway.save(any(), any()));
        await bloc.close();
      });
    });

    test('deleting the set-aside bytes goes through the record queue', () async {
      await onClock(() async {
        final bloc = build();
        when(() => repository.readStored())
            .thenAnswer((_) async => StoredBytes(record: null, quarantine: Uint8List.fromList([1, 2, 3])));
        when(() => gateway.save(any(), any())).thenAnswer((_) async => BackupSaveResult.saved);
        bloc.add(const QuarantineExportRequested());
        await pumpEventQueue();
        expect(bloc.state, const DataState(quarantineCopy: QuarantineCopy.saved));
        bloc.add(const QuarantineDeleteConfirmed());
        await pumpEventQueue();
        expect(added().whereType<QuarantineDeleted>(), hasLength(1));
        expect(bloc.state, const DataState());
        await bloc.close();
      });
    });
  });
}
