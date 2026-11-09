import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _now = '2026-03-14T22:30:00.000Z';
final _clock = Clock.fixed(DateTime.utc(2026, 3, 14, 22, 30).toLocal());
const _toggle = CompletionToggled(key: 'alpha/first', revision: 'a1b2c3d', track: Track.engineers);
final _signed = signOff(RecordData.empty, 'alpha/first', 'a1b2c3d', _now);
final _t = DateTime.utc(2026, 3, 15, 8);
const _noBytes = StoredBytes(record: null, quarantine: null);

RecordReady ready({
  RecordData record = RecordData.empty,
  WriteState writeState = const WriteSaved(),
  QuarantineReason? quarantine,
  bool quarantineKept = false,
  bool launchReadFailed = false,
  EraseUndo? undo,
}) => RecordReady(
  record: record,
  writeState: writeState,
  quarantine: quarantine,
  quarantineKept: quarantineKept,
  launchReadFailed: launchReadFailed,
  undo: undo,
);

/// A record store in memory that logs every call, with a gate on the write and injectable errors.
final class _MemoryRecordRepository implements IRecordRepository {
  RecordLoad loadResult = const RecordLoadEmpty(quarantineKept: false);
  Completer<void>? loadGate;
  Uint8List? record;
  Uint8List? quarantine;
  WriteResult nextResult = WriteResult.saved;
  WriteResult restoreResult = WriteResult.saved;
  Completer<void>? gate;
  FileSystemException? readStoredError;
  FileSystemException? deleteAllError;
  final writes = <String>[];
  final calls = <String>[];

  @override
  Future<RecordLoad> load() async {
    calls.add('load');
    await loadGate?.future;
    return loadResult;
  }

  @override
  Future<WriteResult> write(String compactJson) async {
    calls.add('write');
    writes.add(compactJson);
    await gate?.future;
    if (nextResult == WriteResult.saved) record = utf8.encode(compactJson);
    return nextResult;
  }

  @override
  Future<StoredBytes> readStored() async {
    calls.add('readStored');
    if (readStoredError case final error?) throw error;
    return StoredBytes(record: record, quarantine: quarantine);
  }

  @override
  Future<void> deleteAll() async {
    calls.add('deleteAll');
    if (deleteAllError case final error?) throw error;
    record = null;
    quarantine = null;
  }

  @override
  Future<RestoreResult> restore(StoredBytes bytes) async {
    calls.add('restore');
    if (restoreResult == WriteResult.saved) {
      if (bytes.record case final bytes?) record = bytes;
      if (bytes.quarantine case final bytes?) quarantine = bytes;
    }
    return RestoreResult(write: restoreResult, quarantineKept: quarantine != null);
  }

  @override
  Future<void> deleteQuarantine() async {
    calls.add('deleteQuarantine');
    quarantine = null;
  }
}

FileSystemException _injected() => const FileSystemException('delete', 'record/record.json', OSError('injected', 13));

/// A bloc over [repository] that has run its launch read.
Future<RecordBloc> _started(_MemoryRecordRepository repository) async {
  final bloc = RecordBloc(repository: repository)..add(const RecordStarted());
  await pumpEventQueue();
  return bloc;
}

/// The same, inside `fakeAsync`.
RecordBloc _startedFake(FakeAsync async, _MemoryRecordRepository repository) {
  final bloc = RecordBloc(repository: repository)..add(const RecordStarted());
  async.flushMicrotasks();
  return bloc;
}

RecordReady _ready(RecordBloc bloc) => bloc.state as RecordReady;

/// Runs [body] with the fixed clock, so `nowIso()` is [_now].
Future<void> _withClock(Future<void> Function() body) => withClock(_clock, body);

/// Runs [body] in `fakeAsync` with the fixed clock.
void _fake(void Function(FakeAsync async) body) => fakeAsync((async) => withClock(_clock, () => body(async)));

void main() {
  test('starts loading, then reads an empty store as the empty record', () async {
    await _withClock(() async {
      final bloc = RecordBloc(repository: _MemoryRecordRepository());
      expect(bloc.state, const RecordLoading());
      bloc.add(const RecordStarted());
      await pumpEventQueue();
      expect(bloc.state, ready(record: RecordData.empty));
      await bloc.close();
    });
  });

  test('a stored record is the record', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()..loadResult = RecordLoadOk(data: _signed, quarantineKept: false);
      final bloc = await _started(repository);
      expect(bloc.state, ready(record: _signed));
      await bloc.close();
    });
  });

  test('a quarantined store reads as empty and says why', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()
        ..loadResult = const RecordLoadQuarantined(reason: QuarantineReason.newer, quarantineKept: true);
      final bloc = await _started(repository);
      expect(bloc.state, ready(record: RecordData.empty, quarantine: QuarantineReason.newer, quarantineKept: true));
      await bloc.close();
    });
  });

  test('a failed launch read refuses every write except erase', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()..loadResult = const RecordLoadFailed(quarantineKept: false);
      final bloc = await _started(repository);
      expect(bloc.state, ready(writeState: const WriteBlocked(), launchReadFailed: true));

      bloc.add(_toggle);
      await pumpEventQueue();
      expect(_ready(bloc).record.signedOff('alpha/first', Track.engineers), _now);
      expect(_ready(bloc).writeState, const WriteBlocked());
      expect(repository.writes, isEmpty);

      bloc.add(RecordErased(at: _t));
      await pumpEventQueue();
      expect(repository.calls, contains('deleteAll'));
      expect(_ready(bloc).launchReadFailed, isFalse);

      bloc.add(_toggle);
      await pumpEventQueue();
      expect(repository.writes, hasLength(1));
      await bloc.close();
    });
  });

  test('Review Focus 3: a completion is stamped with the UTC day', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository();
      final bloc = await _started(repository);
      final states = <RecordState>[];
      bloc.stream.listen(states.add);

      bloc.add(_toggle);
      await pumpEventQueue();

      final r = _ready(bloc).record;
      expect(states, [ready(record: r, writeState: const WritePending()), ready(record: r)]);
      expect(r.signedOff('alpha/first', Track.engineers), '2026-03-14T22:30:00.000Z');
      expect(r.days, ['2026-03-14']);
      expect(repository.writes.single, serialise(r, '2026-03-14T22:30:00.000Z', pretty: false));
      await bloc.close();
    });
  });

  test('A35: the track decides the map', () async {
    await _withClock(() async {
      final bloc = await _started(_MemoryRecordRepository());
      bloc.add(const CompletionToggled(key: 'alpha/first', revision: null, track: Track.everyone));
      await pumpEventQueue();

      final raw = _ready(bloc).record.raw;
      final sheet = (raw['everyoneSheets']! as Map)['alpha/first'] as Map;
      expect(sheet['signedOff'], _now);
      expect(sheet['signedRevision'], isNull);
      expect(raw['sheets'], isEmpty);
      await bloc.close();
    });
  });

  test('Review Focus 4: two quick taps apply in order and the file equals memory', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository();
      final bloc = await _started(repository);
      repository.gate = Completer();

      bloc
        ..add(_toggle)
        ..add(_toggle);
      await pumpEventQueue();
      expect(repository.writes, hasLength(1));

      repository.gate!.complete();
      await pumpEventQueue();
      expect(repository.writes, hasLength(2));

      RecordData written(String json) =>
          (parseEnvelope(json) as EnvelopeOk).data; // the compact form parses back to the record it holds
      expect(written(repository.writes[0]).signedOff('alpha/first', Track.engineers), _now);
      expect(written(repository.writes[1]).signedOff('alpha/first', Track.engineers), isNull);
      expect(utf8.decode(repository.record!), serialise(_ready(bloc).record, _now, pretty: false));
      expect(_ready(bloc).writeState, const WriteSaved());
      await bloc.close();
    });
  });

  test('a failed write keeps the change in memory', () async {
    await _withClock(() async {
      for (final (result, state) in [
        (WriteResult.quota, const WriteQuota()),
        (WriteResult.blocked, const WriteBlocked()),
      ]) {
        final repository = _MemoryRecordRepository();
        final bloc = await _started(repository);
        repository.nextResult = result;
        bloc.add(_toggle);
        await pumpEventQueue();
        expect(_ready(bloc).writeState, state);
        expect(_ready(bloc).record.signedOff('alpha/first', Track.engineers), _now);
        await bloc.close();
      }
    });
  });

  test('the cap is the UTF-8 length of the compact form', () async {
    await _withClock(() async {
      RecordData padded(int n) => normaliseRecord({
        'prefs': {'note': 'x' * n},
      });
      final base = utf8.encode(serialise(padded(0), _now, pretty: false)).length;
      final repository = _MemoryRecordRepository();
      final bloc = await _started(repository);

      bloc.add(RecordReplaced(data: padded(524288 - base)));
      await pumpEventQueue();
      expect(_ready(bloc).writeState, const WriteSaved());
      expect(repository.writes, hasLength(1));
      expect(utf8.encode(repository.writes.single).length, 524288);

      final over = padded(524288 - base + 1);
      bloc.add(RecordReplaced(data: over));
      await pumpEventQueue();
      expect(_ready(bloc).writeState, const WriteTooLarge());
      expect(_ready(bloc).record, same(over));
      expect(repository.writes, hasLength(1));
      await bloc.close();
    });
  });

  test('a backup marks the day, writes, and replies with the export bytes', () async {
    await _withClock(() async {
      const at = '2026-03-15T07:10:00.000Z';
      final repository = _MemoryRecordRepository()..loadResult = RecordLoadOk(data: _signed, quarantineKept: false);
      final bloc = await _started(repository);
      final before = _ready(bloc).record;

      final reply = Completer<RecordBackup>();
      bloc.add(BackupStarted(at: at, reply: reply));
      expect(
        await reply.future,
        RecordBackup(
          bytes: utf8.encode(serialise(markActivity(before, at), at, pretty: true)),
          filename: 'hl-record-2026-03-15.json',
        ),
      );
      await pumpEventQueue();
      expect(_ready(bloc).record.days, ['2026-03-14', '2026-03-15']);
      expect(repository.writes, hasLength(1));
      await bloc.close();
    });
  });

  test('a completed backup marks lastExport', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository();
      final bloc = await _started(repository);
      bloc.add(const BackupCompleted(at: '2026-03-15T07:10:00.000Z'));
      await pumpEventQueue();
      expect((_ready(bloc).record.raw['meta']! as Map)['lastExport'], '2026-03-15T07:10:00.000Z');
      expect(repository.writes, hasLength(1));
      await bloc.close();
    });
  });

  test('A33: a restore replaces and writes at once, with no day stamp, and closes the undo', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()..loadResult = RecordLoadOk(data: _signed, quarantineKept: false);
      final bloc = await _started(repository);
      bloc.add(RecordErased(at: _t));
      await pumpEventQueue();
      expect(_ready(bloc).undo, isNotNull);

      final d = normaliseRecord({
        'days': ['2026-01-02'],
      });
      bloc.add(RecordReplaced(data: d));
      await pumpEventQueue();
      expect(_ready(bloc).record, same(d));
      expect(_ready(bloc).record.days, ['2026-01-02']);
      expect(_ready(bloc).undo, isNull);
      expect(repository.writes, hasLength(1));
      await bloc.close();
    });
  });

  test('an erase holds the stored bytes and the record, then deletes the files', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()
        ..loadResult = RecordLoadOk(data: _signed, quarantineKept: true)
        ..record = Uint8List.fromList([1])
        ..quarantine = Uint8List.fromList([2]);
      final bloc = await _started(repository);
      final reply = Completer<bool>();

      bloc.add(RecordErased(at: _t, reply: reply));
      await pumpEventQueue();

      expect(repository.calls, ['load', 'readStored', 'deleteAll']);
      expect(
        bloc.state,
        ready(
          record: RecordData.empty,
          undo: EraseUndo(
            at: _t,
            bytes: StoredBytes(record: Uint8List.fromList([1]), quarantine: Uint8List.fromList([2])),
            data: _signed,
          ),
        ),
      );
      expect(_ready(bloc).record, same(RecordData.empty));
      expect(repository.writes, isEmpty);
      expect(await reply.future, isTrue);
      await bloc.close();
    });
  });

  test('an erase discards the writes queued before it', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository();
      final bloc = await _started(repository);
      bloc
        ..add(_toggle)
        ..add(const BackupCompleted(at: '2026-03-15T07:10:00.000Z'))
        ..add(RecordReplaced(data: _signed))
        ..add(RecordErased(at: _t));
      await pumpEventQueue();
      expect(repository.writes, isEmpty);
      expect(_ready(bloc).record, same(RecordData.empty));
      await bloc.close();
    });
  });

  test('a backup queued before an erase replies without writing', () async {
    await _withClock(() async {
      const at = '2026-03-15T07:10:00.000Z';
      final repository = _MemoryRecordRepository()..loadResult = RecordLoadOk(data: _signed, quarantineKept: false);
      final bloc = await _started(repository);
      final reply = Completer<RecordBackup>();
      bloc
        ..add(BackupStarted(at: at, reply: reply))
        ..add(RecordErased(at: _t));

      expect(
        await reply.future,
        RecordBackup(
          bytes: utf8.encode(serialise(markActivity(_signed, at), at, pretty: true)),
          filename: 'hl-record-2026-03-15.json',
        ),
      );
      await pumpEventQueue();
      expect(repository.writes, isEmpty);
      expect(_ready(bloc).record, same(RecordData.empty));
      await bloc.close();
    });
  });

  test('undo within 10 s restores the bytes and the record', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()
        ..loadResult = RecordLoadOk(data: _signed, quarantineKept: false)
        ..record = Uint8List.fromList([1])
        ..quarantine = Uint8List.fromList([2]);
      final bloc = _startedFake(async, repository)..add(RecordErased(at: _t));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 9));

      bloc.add(const EraseUndone());
      async.flushMicrotasks();
      expect(repository.calls.last, 'restore');
      expect(repository.record, [1]);
      expect(repository.quarantine, [2]);
      expect(bloc.state, ready(record: _signed, quarantineKept: true));

      async.elapse(const Duration(seconds: 5));
      expect(bloc.state, ready(record: _signed, quarantineKept: true));
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('the undo expires after 10 s', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()
        ..loadResult = RecordLoadOk(data: _signed, quarantineKept: false)
        ..record = Uint8List.fromList([1]);
      final bloc = _startedFake(async, repository)..add(RecordErased(at: _t));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 10));
      expect(_ready(bloc).undo, isNull);
      expect(bloc.state, ready());

      final states = <RecordState>[];
      bloc.stream.listen(states.add);
      final calls = repository.calls.length;
      bloc.add(const EraseUndone());
      async.flushMicrotasks();
      expect(repository.calls, hasLength(calls));
      expect(states, isEmpty);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('deleting the quarantine clears the notice', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()
        ..loadResult = const RecordLoadQuarantined(reason: QuarantineReason.newer, quarantineKept: true)
        ..quarantine = Uint8List.fromList([2]);
      final bloc = await _started(repository);
      bloc.add(const QuarantineDeleted());
      await pumpEventQueue();
      expect(repository.calls.last, 'deleteQuarantine');
      expect(repository.quarantine, isNull);
      expect(bloc.state, ready());
      await bloc.close();
    });
  });

  test('undo after a failed launch read closes the write gate again', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()
        ..loadResult = const RecordLoadFailed(quarantineKept: false)
        ..record = Uint8List.fromList([1]);
      final bloc = _startedFake(async, repository);
      expect(bloc.state, ready(writeState: const WriteBlocked(), launchReadFailed: true));

      bloc.add(RecordErased(at: _t));
      async.flushMicrotasks();
      expect(_ready(bloc).launchReadFailed, isFalse);
      async.elapse(const Duration(seconds: 3));
      bloc.add(const EraseUndone());
      async.flushMicrotasks();
      expect(repository.record, [1]);
      expect(bloc.state, ready(record: RecordData.empty, writeState: const WriteBlocked(), launchReadFailed: true));

      bloc.add(_toggle);
      async.flushMicrotasks();
      expect(repository.writes, isEmpty);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('events before the launch read are ignored', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()
        ..loadResult = const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true)
        ..loadGate = Completer();
      final erased = Completer<bool>();
      final backup = Completer<RecordBackup>();
      final backupRefused = expectLater(backup.future, throwsStateError);
      // Under sequential() an event added after RecordStarted waits for the launch read, so the events that find
      // RecordLoading are the ones added before it.
      final bloc = RecordBloc(repository: repository)
        ..add(const QuarantineDeleted())
        ..add(RecordErased(at: _t, reply: erased))
        ..add(BackupStarted(at: '2026-03-15T07:10:00.000Z', reply: backup))
        ..add(_toggle)
        ..add(const RecordStarted());
      await pumpEventQueue();
      expect(bloc.state, const RecordLoading());
      expect(await erased.future, isFalse);
      await backupRefused;

      repository.loadGate!.complete();
      await pumpEventQueue();
      expect(repository.calls, ['load']);
      expect(bloc.state, ready(quarantine: QuarantineReason.malformed, quarantineKept: true));
      await bloc.close();
    });
  });

  test('an event added behind the launch read runs on the record it returns', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository()
        ..loadResult = const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true)
        ..loadGate = Completer();
      final bloc = RecordBloc(repository: repository)
        ..add(const RecordStarted())
        ..add(const QuarantineDeleted());
      await pumpEventQueue();
      expect(bloc.state, const RecordLoading());

      repository.loadGate!.complete();
      await pumpEventQueue();
      expect(repository.calls, ['load', 'deleteQuarantine']);
      expect(bloc.state, ready());
      await bloc.close();
    });
  });

  test('a second start after the launch read does nothing', () async {
    await _withClock(() async {
      final repository = _MemoryRecordRepository();
      final bloc = await _started(repository);
      bloc.add(const RecordStarted());
      await pumpEventQueue();
      expect(repository.calls, ['load']);
      expect(bloc.state, ready());
      await bloc.close();
    });
  });

  test('A41: an erase whose files cannot be read keeps no undo bytes and still erases', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()
        ..loadResult = RecordLoadOk(data: _signed, quarantineKept: false)
        ..record = Uint8List.fromList([1])
        ..readStoredError = _injected();
      final bloc = _startedFake(async, repository);
      final reply = Completer<bool>();
      bool? replied;
      reply.future.then((value) => replied = value);

      bloc.add(RecordErased(at: _t, reply: reply));
      async.flushMicrotasks();
      expect(repository.calls, ['load', 'readStored', 'deleteAll']);
      expect(
        bloc.state,
        ready(
          record: RecordData.empty,
          undo: EraseUndo(at: _t, bytes: _noBytes, data: _signed),
        ),
      );
      expect(replied, isTrue);

      async.elapse(const Duration(seconds: 5));
      bloc.add(const EraseUndone());
      async.flushMicrotasks();
      // Decision E7: the undo writes the record from memory, so the disk holds what the page shows.
      expect(repository.calls.sublist(repository.calls.length - 2), ['restore', 'write']);
      expect(repository.writes, hasLength(1));
      expect(repository.record, utf8.encode(serialise(_signed, _now, pretty: false)));
      expect(bloc.state, ready(record: _signed));
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('A41: an undo of a record that carries nothing writes nothing', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()..readStoredError = _injected();
      final bloc = _startedFake(async, repository)..add(RecordErased(at: _t));
      async.flushMicrotasks();
      bloc.add(const EraseUndone());
      async.flushMicrotasks();
      expect(repository.calls.last, 'restore');
      expect(repository.writes, isEmpty);
      expect(bloc.state, ready());
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('an undo whose restore fails keeps the record in memory and says it is not saved', () {
    for (final (result, writeState) in [
      (WriteResult.quota, const WriteQuota()),
      (WriteResult.blocked, const WriteBlocked()),
    ]) {
      final errors = <Object>[];
      runZonedGuarded(
        () => _fake((async) {
          final repository = _MemoryRecordRepository()
            ..loadResult = RecordLoadOk(data: _signed, quarantineKept: false)
            ..record = Uint8List.fromList([1])
            ..restoreResult = result;
          final bloc = _startedFake(async, repository)..add(RecordErased(at: _t));
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 3));

          bloc.add(const EraseUndone());
          async.flushMicrotasks();
          expect(repository.calls.last, 'restore');
          expect(repository.record, isNull);
          expect(
            bloc.state,
            ready(record: _signed, writeState: writeState),
            reason: '$result',
          );

          async.elapse(const Duration(seconds: 20));
          expect(
            bloc.state,
            ready(record: _signed, writeState: writeState),
            reason: '$result',
          );
          expect(async.pendingTimers, isEmpty, reason: '$result');
          bloc.close();
          async.flushMicrotasks();
        }),
        (error, _) => errors.add(error),
      );
      expect(errors, isEmpty, reason: '$result');
    }
  });

  test('A41: an erase whose files cannot be deleted does not happen', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()
        ..loadResult = const RecordLoadQuarantined(reason: QuarantineReason.newer, quarantineKept: true);
      final bloc = _startedFake(async, repository)..add(_toggle);
      async.flushMicrotasks();
      final r = _ready(bloc).record;
      expect(r.signedOff('alpha/first', Track.engineers), _now);

      repository.deleteAllError = _injected();
      final reply = Completer<bool>();
      bool? replied;
      reply.future.then((value) => replied = value);
      bloc.add(RecordErased(at: _t, reply: reply));
      async.flushMicrotasks();

      final expected = ready(
        record: r,
        writeState: const WriteBlocked(),
        quarantine: QuarantineReason.newer,
        quarantineKept: true,
      );
      expect(bloc.state, expected);
      expect(repository.calls.last, 'deleteAll');
      expect(repository.calls, isNot(contains('restore')));
      expect(replied, isFalse);

      final states = <RecordState>[];
      bloc.stream.listen(states.add);
      async.elapse(const Duration(seconds: 20));
      expect(states, isEmpty);
      expect(bloc.state, expected);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('A42: RecordBloc owns the undo window', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()..loadResult = RecordLoadOk(data: _signed, quarantineKept: false);
      final t1 = DateTime.utc(2026, 3, 15, 8);
      final t2 = DateTime.utc(2026, 3, 15, 8, 0, 6);
      final bloc = _startedFake(async, repository)..add(RecordErased(at: t1));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      bloc.add(RecordErased(at: t2));
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 6));
      expect(_ready(bloc).undo?.at, t2);
      async.elapse(const Duration(seconds: 4));
      expect(_ready(bloc).undo, isNull);

      final states = <RecordState>[];
      bloc.stream.listen(states.add);
      final d = normaliseRecord({
        'days': ['2026-01-02'],
      });
      bloc
        ..add(RecordErased(at: t2))
        ..add(RecordReplaced(data: d));
      async.flushMicrotasks();
      final count = states.length;
      expect(_ready(bloc).record, same(d));
      expect(_ready(bloc).undo, isNull);
      async.elapse(const Duration(seconds: 20));
      expect(states, hasLength(count));

      bloc
        ..add(const UndoExpired())
        ..add(const UndoExpired());
      async.flushMicrotasks();
      expect(states, hasLength(count));
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('close cancels an open undo window', () {
    _fake((async) {
      final repository = _MemoryRecordRepository()..loadResult = RecordLoadOk(data: _signed, quarantineKept: false);
      final bloc = _startedFake(async, repository)..add(RecordErased(at: _t));
      async.flushMicrotasks();
      expect(_ready(bloc).undo, isNotNull);
      bloc.close();
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  });
}
