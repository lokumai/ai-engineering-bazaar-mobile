import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/settings/application/undo_countdown.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/instant.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';

part 'data_event.dart';
part 'data_state.dart';

/// Runs the data line's flows: back up, restore, reset with its undo, and the set-aside record (spec 3.3.9 to
/// 3.3.11). The reset erases the quiz scores and the reading places too, and its undo brings them back (plan 1W, 1BA).
///
/// [RecordBloc] owns every write and the undo window (Decision A42); this bloc hands it events, talks to the
/// platform through [IBackupGateway], and only displays the countdown, which it never ends on the record's behalf.
///
/// An interface class rather than a final one, so widget tests can provide a `MockBloc` that implements it.
interface class DataBloc extends Bloc<DataEvent, DataState> {
  DataBloc({required this._recordBloc, required this._gateway, required this._repository, this._scores, this._places})
    : super(const DataState()) {
    on<BackupRequested>(_onBackupRequested, transformer: EventTransformers.dropConcurrent());
    on<RestoreRequested>(_onRestoreRequested, transformer: EventTransformers.dropConcurrent());
    on<RestoreConfirmed>(_onRestoreConfirmed);
    on<RestoreDeclined>(_onRestoreDeclined);
    on<ResetConfirmed>(_onResetConfirmed, transformer: EventTransformers.dropConcurrent());
    on<UndoRequested>(_onUndoRequested);
    on<UndoTicked>(_onUndoTicked);
    on<QuarantineExportRequested>(_onQuarantineExportRequested, transformer: EventTransformers.dropConcurrent());
    on<QuarantineDeleteConfirmed>(_onQuarantineDeleteConfirmed);
  }

  static final _log = AppLogger.getLogger('DataBloc');

  static const _tick = Duration(milliseconds: 250);

  final RecordBloc _recordBloc;
  final IBackupGateway _gateway;
  final IRecordRepository _repository;

  /// The quiz scores, which the reset erases with the record and its undo brings back (plan 1W).
  final QuizScoresBloc? _scores;

  /// Where each module was left, which the reset erases with the record and its undo brings back (plan 1BA).
  final ReadingPlacesBloc? _places;

  /// The instant of the erase whose countdown is shown.
  DateTime? _erasedAt;

  StreamSubscription<void>? _ticker;

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }

  /// Web `onExport` (`DataPanel.tsx:104-137`); `lastExport` is marked only after a confirmed save or share (A19).
  Future<void> _onBackupRequested(BackupRequested event, Emitter<DataState> emit) async {
    emit(state._with(busy: DataBusy.backingUp));
    try {
      final at = nowIso();
      final reply = Completer<RecordBackup>();
      _recordBloc.add(BackupStarted(at: at, reply: reply));
      final backup = await reply.future;
      final BackupSaveResult result;
      try {
        result = await _gateway.save(backup.bytes, backup.filename);
      } on Exception catch (error) {
        _log.warn('Backup not written: {}', [error.runtimeType]);
        emit(state._with(busy: DataBusy.idle, backup: const BackupNotWritten()));
        return;
      }
      switch (result) {
        case BackupSaveResult.saved || BackupSaveResult.shared:
          _recordBloc.add(BackupCompleted(at: at));
          emit(state._with(busy: DataBusy.idle, backup: BackedUp(at.substring(0, 10))));
        case BackupSaveResult.dismissed:
          emit(state._with(busy: DataBusy.idle));
      }
    } finally {
      _settle(DataBusy.backingUp, emit);
    }
  }

  /// Web `onImport` (`DataPanel.tsx:139-173`), with the app's confirmation when the record carries something.
  Future<void> _onRestoreRequested(RestoreRequested event, Emitter<DataState> emit) async {
    emit(state._with(busy: DataBusy.restoring));
    try {
      final picked = await _gateway.pickJson();
      final next = switch (picked) {
        PickedBackupCancelled() => state,
        PickedBackupUnreadable() => state._with(restore: RestoreOutcome.unreadable),
        PickedBackupBytes(:final bytes) => switch (parseEnvelope(envelopeTextFrom(decodeRecordBytes(bytes)))) {
          EnvelopeEmpty() => state._with(restore: RestoreOutcome.empty),
          EnvelopeQuarantine(reason: QuarantineReason.newer) => state._with(restore: RestoreOutcome.newer),
          EnvelopeQuarantine(reason: QuarantineReason.malformed) => state._with(restore: RestoreOutcome.malformed),
          EnvelopeOk(:final data) => _offer(data),
        },
      };
      emit(next._with(busy: DataBusy.idle));
    } finally {
      _settle(DataBusy.restoring, emit);
    }
  }

  /// The state once [data] is offered: applied at once over a record that carries nothing, else held for the
  /// reader's confirmation with the tally of what it replaces.
  DataState _offer(RecordData data) {
    // A record the app would not write is refused before it replaces anything: it would be gone at the next start.
    if (utf8.encode(serialise(data, nowIso(), pretty: false)).length > RecordConstants.softCapBytes) {
      return state._with(restore: RestoreOutcome.tooLarge);
    }
    final local = switch (_recordBloc.state) {
      RecordReady(:final record) => record,
      RecordLoading() => throw StateError('the record is not read yet'),
    };
    if (carriesNothing(local)) return _apply(data);
    return state._with(
      pendingRestore: PendingRestore(data: data, local: tally(local)),
    );
  }

  /// Replaces the record with [data]; the replacement closes an open undo (A33), so the countdown stops.
  DataState _apply(RecordData data) {
    _recordBloc.add(RecordReplaced(data: data));
    _stopTicker();
    return state._with(reset: null, pendingRestore: null, restore: RestoreOutcome.restored);
  }

  void _onRestoreConfirmed(RestoreConfirmed event, Emitter<DataState> emit) {
    final pending = state.pendingRestore;
    if (pending == null) {
      // A second tap on the dialog's button arrives after the first one applied the file.
      _log.debug('Restore confirmed with nothing waiting');
      return;
    }
    emit(_apply(pending.data));
  }

  void _onRestoreDeclined(RestoreDeclined event, Emitter<DataState> emit) {
    emit(state._with(pendingRestore: null));
  }

  /// Web `onErase` (`DataPanel.tsx:175-190`); RecordBloc replies whether the files were deleted (A41).
  Future<void> _onResetConfirmed(ResetConfirmed event, Emitter<DataState> emit) async {
    _stopTicker();
    emit(state._with(busy: DataBusy.erasing));
    try {
      final at = clock.now();
      final done = Completer<bool>();
      _recordBloc.add(RecordErased(at: at, reply: done));
      final erased = await done.future;
      // The scores and the places go with the record even when the page closed meanwhile: a reset is never half done.
      if (erased) {
        // A reset while the undo of the one before is open keeps what that undo brings back.
        final again = switch (_recordBloc.state) {
          RecordReady(:final undo?) => undo.again,
          _ => false,
        };
        _scores?.add(QuizScoresErased(again: again));
        _places?.add(ReadingPlacesErased(again: again));
      }
      // The page closed while the erase waited in the record's queue: a ticker started now is never cancelled.
      if (isClosed) return;
      if (!erased) {
        emit(state._with(busy: DataBusy.idle, reset: const ResetNotFinished()));
        return;
      }
      _erasedAt = at;
      emit(
        state._with(
          busy: DataBusy.idle,
          backup: null,
          restore: null,
          reset: ResetCounting(undoSecondsLeft(at, clock.now())),
        ),
      );
      _ticker = Stream<void>.periodic(_tick).listen((_) => add(const UndoTicked()));
    } finally {
      _settle(DataBusy.erasing, emit);
    }
  }

  /// Web `onUndo` (`DataPanel.tsx:192-199`); RecordBloc restores the record and the files. The scores and the places
  /// come back only when the record does: a tap as the window closes undoes nothing rather than half the reset.
  Future<void> _onUndoRequested(UndoRequested event, Emitter<DataState> emit) async {
    if (state.reset is! ResetCounting) return;
    final undone = Completer<bool>();
    _recordBloc.add(EraseUndone(reply: undone));
    _stopTicker();
    emit(state._with(reset: null));
    if (await undone.future) {
      _scores?.add(const QuizScoresEraseUndone());
      _places?.add(const ReadingPlacesEraseUndone());
    }
  }

  /// Shows the seconds left while the record's undo for [_erasedAt] is open; closes the line once it is not.
  void _onUndoTicked(UndoTicked event, Emitter<DataState> emit) {
    final at = _erasedAt;
    if (state.reset is! ResetCounting || at == null) return;
    final left = undoSecondsLeft(at, clock.now());
    final record = _recordBloc.state;
    if (record is RecordReady && record.undo?.at == at && left > 0) {
      emit(state._with(reset: ResetCounting(left)));
      return;
    }
    _stopTicker();
    emit(state._with(reset: const ResetClosed()));
  }

  /// Saves the set-aside bytes unchanged; nothing is marked in the record.
  Future<void> _onQuarantineExportRequested(QuarantineExportRequested event, Emitter<DataState> emit) async {
    emit(state._with(busy: DataBusy.savingQuarantine));
    try {
      final StoredBytes stored;
      try {
        stored = await _repository.readStored();
      } on FileSystemException catch (error) {
        _log.warn('Set-aside record not read: {}', [error.runtimeType]);
        emit(state._with(busy: DataBusy.idle, quarantineCopy: QuarantineCopy.notWritten));
        return;
      }
      final bytes = stored.quarantine;
      if (bytes == null) throw StateError('no set-aside record to save');
      final BackupSaveResult result;
      try {
        result = await _gateway.save(bytes, 'hl-record-quarantine-${nowIso().substring(0, 10)}.json');
      } on Exception catch (error) {
        _log.warn('Set-aside copy not written: {}', [error.runtimeType]);
        emit(state._with(busy: DataBusy.idle, quarantineCopy: QuarantineCopy.notWritten));
        return;
      }
      emit(switch (result) {
        BackupSaveResult.saved ||
        BackupSaveResult.shared => state._with(busy: DataBusy.idle, quarantineCopy: QuarantineCopy.saved),
        BackupSaveResult.dismissed => state._with(busy: DataBusy.idle),
      });
    } finally {
      _settle(DataBusy.savingQuarantine, emit);
    }
  }

  void _onQuarantineDeleteConfirmed(QuarantineDeleteConfirmed event, Emitter<DataState> emit) {
    _recordBloc.add(const QuarantineDeleted());
    emit(state._with(quarantineCopy: null));
  }

  /// Ends [busy] when a handler leaves early with an error, so the data line's actions come back.
  void _settle(DataBusy busy, Emitter<DataState> emit) {
    if (state.busy == busy && !emit.isDone) emit(state._with(busy: DataBusy.idle));
  }

  /// Cancels the countdown's ticker without waiting: a periodic stream's cancel has nothing to wait for, and its
  /// future may complete in another zone.
  void _stopTicker() {
    unawaited(_ticker?.cancel());
    _ticker = null;
  }
}
