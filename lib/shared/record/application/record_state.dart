part of 'record_bloc.dart';

/// Where the latest record write stands (spec 3.3.9).
sealed class WriteState extends Equatable {
  const WriteState();

  @override
  List<Object?> get props => [];
}

/// The record on disk equals the record in memory.
final class WriteSaved extends WriteState {
  const WriteSaved();
}

/// A write is running.
final class WritePending extends WriteState {
  const WritePending();
}

/// The device is out of space; the record in memory holds the change.
final class WriteQuota extends WriteState {
  const WriteQuota();
}

/// The record is over the soft cap, so nothing was written.
final class WriteTooLarge extends WriteState {
  const WriteTooLarge();
}

/// A write failed, an erase could not delete the files, or the launch read failed and writes are refused.
final class WriteBlocked extends WriteState {
  const WriteBlocked();
}

sealed class RecordState extends Equatable {
  const RecordState();
}

/// The launch read is running.
final class RecordLoading extends RecordState {
  const RecordLoading();

  @override
  List<Object?> get props => [];
}

/// The record is read and in memory.
///
/// A single state carrying a coherent bundle of fields, the transactional snapshot of the Flutter `CLAUDE.md`
/// (exception 2): the record, where its write stands, the quarantine notice, the write gate and the erase undo
/// evolve together and are shown together.
final class RecordReady extends RecordState {
  const RecordReady({
    required this.record,
    required this.writeState,
    required this.quarantine,
    required this.quarantineKept,
    required this.launchReadFailed,
    required this.undo,
  });

  /// The record in memory; it stays authoritative when a write fails.
  final RecordData record;
  final WriteState writeState;

  /// Why this launch set a stored record aside, or null.
  final QuarantineReason? quarantine;

  /// Whether `record-quarantine.json` exists.
  final bool quarantineKept;

  /// The launch read hit an I/O error, so every write except an erase is refused.
  final bool launchReadFailed;

  /// The erase that can still be undone, or null.
  final EraseUndo? undo;

  @override
  List<Object?> get props => [record, writeState, quarantine, quarantineKept, launchReadFailed, undo];
}

/// What an undo of the erase at [at] restores: the files' [bytes] and the record [data].
final class EraseUndo extends Equatable {
  const EraseUndo({required this.at, required this.bytes, required this.data});

  final DateTime at;
  final StoredBytes bytes;
  final RecordData data;

  @override
  List<Object?> get props => [at, bytes, data];
}
