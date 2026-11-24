import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/instant.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';

part 'record_event.dart';
part 'record_state.dart';

/// Owns the record and its one serial write queue (spec 3.3.2, 3.3.9 to 3.3.11).
///
/// Every event goes through one handler under `sequential()`, so writes, erases and undos never overlap and run in
/// the order they were added (Review Focus 4). The record in memory stays authoritative when a write fails.
/// RecordBloc owns the erase's undo window (Decision A42).
///
/// An interface class rather than a final one, so widget tests can provide a `MockBloc` that implements it.
interface class RecordBloc extends Bloc<RecordEvent, RecordState> {
  RecordBloc({required this._repository}) : super(const RecordLoading()) {
    on<RecordEvent>(_onEvent, transformer: EventTransformers.queue());
  }

  static final _log = AppLogger.getLogger('RecordBloc');

  final IRecordRepository _repository;

  /// Erases added whose handler has not started; the writes queued before them are discarded (spec 3.3.11 step 2).
  int _pendingErases = 0;

  /// The state before the erase that the open undo restores.
  RecordReady? _beforeErase;

  Timer? _undoTimer;

  /// The changes made while the undo is open, which the undo makes again on the record it brings back: a module
  /// completed or a box ticked after the reset is not lost to the undo.
  final _sinceErase = <RecordData Function(RecordData)>[];

  @override
  void add(RecordEvent event) {
    if (event is RecordErased) _pendingErases++;
    super.add(event);
  }

  @override
  Future<void> close() {
    _undoTimer?.cancel();
    return super.close();
  }

  Future<void> _onEvent(RecordEvent event, Emitter<RecordState> emit) async {
    try {
      await _handle(event, emit);
    } on Object catch (error, stack) {
      // An error no handler names still answers whoever waits, or the Settings line would stay busy for ever. It is
      // reported, and the queue goes on with the next event.
      _log.error('record event {} failed: {}', [event.runtimeType, error]);
      _answerFailed(event);
      addError(error, stack);
    }
  }

  /// Answers [event]'s caller, when it waits and was not answered yet, that it did not happen.
  void _answerFailed(RecordEvent event) {
    switch (event) {
      case RecordErased(:final reply?) when !reply.isCompleted:
        reply.complete(false);
      case EraseUndone(:final reply?) when !reply.isCompleted:
        reply.complete(false);
      case RecordReplaced(:final reply?) when !reply.isCompleted:
        reply.complete(false);
      case TransferMerged(:final reply) when !reply.isCompleted:
        reply.complete(TransferMergeResult.notAdded);
      case BackupStarted(:final reply) when !reply.isCompleted:
        reply.completeError(StateError('the backup could not be made'));
      default:
        break;
    }
  }

  Future<void> _handle(RecordEvent event, Emitter<RecordState> emit) async {
    if (event is RecordErased) _pendingErases--;
    final current = state;
    if (current is! RecordReady) {
      if (event is RecordStarted) {
        await _onStarted(emit);
      } else {
        _ignore(event);
      }
      return;
    }
    switch (event) {
      case RecordStarted():
        return;
      case CompletionToggled(:final key, :final revision, :final track):
        final signing = current.record.signedOff(key, track) == null;
        await _setCompletion(current, emit, key: key, revision: revision, track: track, completed: signing);
      case CompletionSet(:final key, :final revision, :final track, :final completed):
        await _setCompletion(current, emit, key: key, revision: revision, track: track, completed: completed);
      case ChecklistItemToggled(:final key, :final index, :final ticked, :final track):
        if (_pendingErases > 0) return;
        final now = nowIso();
        RecordData ticking(RecordData record) =>
            setChecklistItem(record, key, index, now, ticked: ticked, track: track);
        if (current.undo != null) _sinceErase.add(ticking);
        await _commit(current, ticking(current.record), emit);
      case BackupStarted(:final at, :final reply):
        final next = markActivity(current.record, at);
        if (_pendingErases == 0) await _commit(current, next, emit);
        reply.complete(
          RecordBackup(bytes: utf8.encode(serialise(next, at, pretty: true)), filename: exportFilename(at)),
        );
      case BackupCompleted(:final at):
        if (_pendingErases > 0) return;
        if (current.undo != null) _sinceErase.add((record) => markExported(record, at));
        await _commit(current, markExported(current.record, at), emit);
      case RecordReplaced(:final data, :final reply):
        if (_pendingErases > 0) {
          reply?.complete(false);
          return;
        }
        _closeUndo();
        await _commit(
          RecordReady(
            record: current.record,
            writeState: current.writeState,
            quarantine: current.quarantine,
            quarantineKept: current.quarantineKept,
            launchReadFailed: current.launchReadFailed,
            undo: null,
          ),
          data,
          emit,
        );
        reply?.complete(true);
      case TransferMerged(:final progress, :final reply):
        if (_pendingErases > 0) {
          reply.complete(TransferMergeResult.notAdded);
          return;
        }
        final merged = mergeTransfer(current.record, progress);
        if (identical(merged, current.record)) {
          reply.complete(TransferMergeResult.nothingNew);
          return;
        }
        // A link under its length limit can still carry enough to take the record past the cap; it is refused before
        // it reaches the record in use, as a restore is (review 7, finding 2).
        if (utf8.encode(serialise(merged, nowIso(), pretty: false)).length > RecordConstants.softCapBytes) {
          reply.complete(TransferMergeResult.notAdded);
          return;
        }
        _closeUndo();
        await _commit(
          RecordReady(
            record: current.record,
            writeState: current.writeState,
            quarantine: current.quarantine,
            quarantineKept: current.quarantineKept,
            launchReadFailed: current.launchReadFailed,
            undo: null,
          ),
          merged,
          emit,
        );
        reply.complete(switch (state) {
          RecordReady(writeState: WriteSaved()) => TransferMergeResult.added,
          _ => TransferMergeResult.notAdded,
        });
      case RecordErased(:final at, :final reply):
        await _onErased(current, at, reply, emit);
      case EraseUndone(:final reply):
        // Undone first, then answered: `reply?.complete(await ...)` would skip the undo when no one waits for it.
        final undone = await _onUndone(current, emit);
        reply?.complete(undone);
      case UndoExpired():
        if (current.undo == null) return;
        _closeUndo();
        emit(
          RecordReady(
            record: current.record,
            writeState: current.writeState,
            quarantine: current.quarantine,
            quarantineKept: current.quarantineKept,
            launchReadFailed: current.launchReadFailed,
            undo: null,
          ),
        );
      case QuarantineDeleted():
        await _repository.deleteQuarantine();
        final cleared = RecordReady(
          record: current.record,
          writeState: current.writeState,
          quarantine: null,
          quarantineKept: false,
          launchReadFailed: current.launchReadFailed,
          undo: current.undo,
        );
        // A record set aside at this launch is still in `record.json`: the record in use is written over it, or the
        // next start sets the same bytes aside again and the notice comes back after a delete said it was final
        // (review 6, finding 8).
        if (current.quarantine == null) {
          emit(cleared);
        } else {
          await _commit(cleared, current.record, emit, always: true);
        }
    }
  }

  /// An event whose turn comes before the launch read does nothing; a caller waiting on a reply is told so.
  ///
  /// Under `sequential()` an event added after [RecordStarted] waits for the launch read and then runs on its record.
  void _ignore(RecordEvent event) {
    switch (event) {
      case RecordErased(:final reply):
        reply?.complete(false);
      case EraseUndone(:final reply):
        reply?.complete(false);
      case BackupStarted(:final reply):
        reply.completeError(StateError('the record is not read yet'));
      case RecordReplaced(:final reply):
        reply?.complete(false);
      case TransferMerged(:final reply):
        reply.complete(TransferMergeResult.notAdded);
      default:
        break;
    }
  }

  Future<void> _onStarted(Emitter<RecordState> emit) async {
    RecordLoad load;
    try {
      load = await _repository.load();
    } on Object catch (error, stack) {
      // An error the store does not answer for, such as the platform refusing the support directory, is a failed
      // launch read: the app opens, and nothing is written over a record that may still be there.
      _log.error('record launch read threw: {}\n{}', [error, stack]);
      load = const RecordLoadFailed(quarantineKept: false);
    }
    emit(
      RecordReady(
        record: switch (load) {
          RecordLoadOk(:final data) => data,
          RecordLoadEmpty() || RecordLoadQuarantined() || RecordLoadFailed() => RecordData.empty,
        },
        writeState: load is RecordLoadFailed ? const WriteBlocked() : const WriteSaved(),
        quarantine: load is RecordLoadQuarantined ? load.reason : null,
        quarantineKept: load.quarantineKept,
        launchReadFailed: load is RecordLoadFailed,
        undo: null,
      ),
    );
  }

  /// Completes [key] on [track], or takes its completion away, as [completed] says; a module already so is left as it
  /// is, and nothing is written.
  Future<void> _setCompletion(
    RecordReady current,
    Emitter<RecordState> emit, {
    required String key,
    required String? revision,
    required Track track,
    required bool completed,
  }) async {
    if (_pendingErases > 0) return;
    final now = nowIso();
    RecordData set(RecordData record) {
      final signed = record.signedOff(key, track) != null;
      if (signed == completed) return record;
      // Each track is completed on its own, as on the website (plan 17.4; 1V is undone).
      return completed ? signOff(record, key, revision, now, track: track) : unsign(record, key, track: track);
    }

    if (current.undo != null) _sinceErase.add(set);
    await _commit(current, set(current.record), emit);
  }

  /// Makes [next] the record on top of [base], and writes it unless the cap or the launch-read gate refuses.
  Future<void> _commit(RecordReady base, RecordData next, Emitter<RecordState> emit, {bool always = false}) async {
    if (!always && identical(next, base.record)) {
      emit(base);
      return;
    }
    RecordReady withRecord(WriteState writeState) => RecordReady(
      record: next,
      writeState: writeState,
      quarantine: base.quarantine,
      quarantineKept: base.quarantineKept,
      launchReadFailed: base.launchReadFailed,
      undo: base.undo,
    );

    final json = serialise(next, nowIso(), pretty: false);
    if (utf8.encode(json).length > RecordConstants.softCapBytes) {
      emit(withRecord(const WriteTooLarge()));
      return;
    }
    if (base.launchReadFailed) {
      emit(withRecord(const WriteBlocked()));
      return;
    }
    emit(withRecord(const WritePending()));
    final result = await _repository.write(json);
    if (result != WriteResult.saved) _log.warn('record write failed: {}', [result]);
    emit(
      withRecord(switch (result) {
        WriteResult.saved => const WriteSaved(),
        WriteResult.quota => const WriteQuota(),
        WriteResult.blocked => const WriteBlocked(),
      }),
    );
  }

  /// Decision A41: an erase whose files cannot be read still erases with no undo bytes; one whose files cannot be
  /// deleted does not happen, and the files read before it are written back, so a delete that stopped part way loses
  /// nothing on the device.
  Future<void> _onErased(RecordReady current, DateTime at, Completer<bool>? reply, Emitter<RecordState> emit) async {
    StoredBytes bytes;
    try {
      bytes = await _repository.readStored();
    } on FileSystemException catch (error) {
      _log.warn('record read before erase failed: {}', [error]);
      bytes = const StoredBytes(record: null, quarantine: null);
    }
    try {
      await _repository.deleteAll();
    } on FileSystemException catch (error) {
      _log.warn('record erase failed: {}', [error]);
      if (bytes.record != null || bytes.quarantine != null) {
        final put = await _repository.restore(bytes);
        if (put.write != WriteResult.saved) _log.error('record not written back after a failed erase: {}', [put.write]);
      }
      emit(
        RecordReady(
          record: current.record,
          writeState: const WriteBlocked(),
          quarantine: current.quarantine,
          quarantineKept: current.quarantineKept,
          launchReadFailed: current.launchReadFailed,
          undo: current.undo,
        ),
      );
      reply?.complete(false);
      return;
    }
    // A second erase while the first one's undo is open keeps what that undo brings back: the record from before the
    // first, not the empty one. What was changed in between is erased with it, and does not come back.
    final open = current.undo;
    final before = _beforeErase;
    _closeUndo();
    _beforeErase = open != null && before != null ? before : current;
    emit(
      RecordReady(
        record: erasedRecord(current.record),
        writeState: const WriteSaved(),
        quarantine: null,
        quarantineKept: false,
        launchReadFailed: false,
        undo: open != null && before != null
            ? EraseUndo(at: at, bytes: open.bytes, data: open.data, again: true)
            : EraseUndo(at: at, bytes: bytes, data: current.record),
      ),
    );
    _undoTimer = Timer(RecordConstants.undoWindow, () => add(const UndoExpired()));
    reply?.complete(true);
  }

  /// Puts the record from before the erase back in memory whatever the disk does (spec 3.3.9, Decision E7): a restore
  /// that cannot write answers quota or blocked, and the write notice says so. After an erase that kept no record
  /// bytes (A41), the record is written from memory, so the disk holds what the page shows.
  ///
  /// The changes made since the erase are made again on the record brought back. Answers whether the undo was open.
  Future<bool> _onUndone(RecordReady current, Emitter<RecordState> emit) async {
    final undo = current.undo;
    final before = _beforeErase;
    if (undo == null || before == null) return false;
    final since = [..._sinceErase];
    _closeUndo();
    final restored = await _repository.restore(undo.bytes);
    if (restored.write != WriteResult.saved) _log.warn('record undo write failed: {}', [restored.write]);
    final back = RecordReady(
      record: undo.data,
      writeState: switch (restored.write) {
        WriteResult.saved => before.writeState,
        WriteResult.quota => const WriteQuota(),
        WriteResult.blocked => const WriteBlocked(),
      },
      quarantine: before.quarantine,
      quarantineKept: restored.quarantineKept,
      launchReadFailed: before.launchReadFailed,
      undo: null,
    );
    final target = since.fold(undo.data, (record, change) => change(record));
    if (undo.bytes.record == null && !before.launchReadFailed && !carriesNothing(undo.data)) {
      await _commit(
        RecordReady(
          record: current.record,
          writeState: back.writeState,
          quarantine: back.quarantine,
          quarantineKept: back.quarantineKept,
          launchReadFailed: back.launchReadFailed,
          undo: null,
        ),
        target,
        emit,
      );
      return true;
    }
    if (since.isNotEmpty) {
      await _commit(back, target, emit);
      return true;
    }
    emit(back);
    return true;
  }

  /// Cancels the undo timer and drops the state the undo would restore.
  void _closeUndo() {
    _undoTimer?.cancel();
    _undoTimer = null;
    _beforeErase = null;
    _sinceErase.clear();
  }
}
