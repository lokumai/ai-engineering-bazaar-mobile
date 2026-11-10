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
      case CompletionToggled(:final key, :final revision, :final track, :final everyone):
        if (_pendingErases > 0) return;
        final RecordData next;
        if (current.record.signedOff(key, track) != null) {
          next = unsign(current.record, key, track: track);
        } else {
          final now = nowIso();
          final signed = signOff(current.record, key, revision, now, track: track);
          // A For Engineers completion completes the For Everyone version too, never the reverse (plan 1V).
          next = everyone != null && track == Track.engineers && signed.signedOff(key, Track.everyone) == null
              ? signOff(signed, key, everyone.revision, now, track: Track.everyone)
              : signed;
        }
        await _commit(current, next, emit);
      case BackupStarted(:final at, :final reply):
        final next = markActivity(current.record, at);
        if (_pendingErases == 0) await _commit(current, next, emit);
        reply.complete(
          RecordBackup(bytes: utf8.encode(serialise(next, at, pretty: true)), filename: exportFilename(at)),
        );
      case BackupCompleted(:final at):
        if (_pendingErases > 0) return;
        await _commit(current, markExported(current.record, at), emit);
      case RecordReplaced(:final data):
        if (_pendingErases > 0) return;
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
      case RecordErased(:final at, :final reply):
        await _onErased(current, at, reply, emit);
      case EraseUndone():
        await _onUndone(current, emit);
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
        emit(
          RecordReady(
            record: current.record,
            writeState: current.writeState,
            quarantine: null,
            quarantineKept: false,
            launchReadFailed: current.launchReadFailed,
            undo: current.undo,
          ),
        );
    }
  }

  /// An event whose turn comes before the launch read does nothing; a caller waiting on a reply is told so.
  ///
  /// Under `sequential()` an event added after [RecordStarted] waits for the launch read and then runs on its record.
  void _ignore(RecordEvent event) {
    switch (event) {
      case RecordErased(:final reply):
        reply?.complete(false);
      case BackupStarted(:final reply):
        reply.completeError(StateError('the record is not read yet'));
      default:
        break;
    }
  }

  Future<void> _onStarted(Emitter<RecordState> emit) async {
    final load = await _repository.load();
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

  /// Makes [next] the record on top of [base], and writes it unless the cap or the launch-read gate refuses.
  Future<void> _commit(RecordReady base, RecordData next, Emitter<RecordState> emit) async {
    if (identical(next, base.record)) {
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
  /// deleted does not happen.
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
    _closeUndo();
    _beforeErase = current;
    emit(
      RecordReady(
        record: erasedRecord(current.record),
        writeState: const WriteSaved(),
        quarantine: null,
        quarantineKept: false,
        launchReadFailed: false,
        undo: EraseUndo(at: at, bytes: bytes, data: current.record),
      ),
    );
    _undoTimer = Timer(RecordConstants.undoWindow, () => add(const UndoExpired()));
    reply?.complete(true);
  }

  /// Puts the record from before the erase back in memory whatever the disk does (spec 3.3.9, Decision E7): a restore
  /// that cannot write answers quota or blocked, and the write notice says so. After an erase that kept no record
  /// bytes (A41), the record is written from memory, so the disk holds what the page shows.
  Future<void> _onUndone(RecordReady current, Emitter<RecordState> emit) async {
    final undo = current.undo;
    final before = _beforeErase;
    if (undo == null || before == null) return;
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
        undo.data,
        emit,
      );
      return;
    }
    emit(back);
  }

  /// Cancels the undo timer and drops the state the undo would restore.
  void _closeUndo() {
    _undoTimer?.cancel();
    _undoTimer = null;
    _beforeErase = null;
  }
}
