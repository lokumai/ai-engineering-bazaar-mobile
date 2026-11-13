part of 'data_bloc.dart';

/// Which action of the data line is running.
enum DataBusy { idle, backingUp, restoring, erasing, savingQuarantine }

/// How the latest restore ended.
enum RestoreOutcome {
  /// The file replaced the record.
  restored,

  /// The file was read but did not replace the record: a reset was under way.
  notRestored,

  /// The file holds no progress.
  empty,

  /// The file was written by a newer version.
  newer,

  /// The file is not a backup.
  malformed,

  /// The file could not be read.
  unreadable,

  /// The file's record is larger than the app writes (the web's soft cap), so restoring it would last only until the
  /// app closed.
  tooLarge,
}

/// How the latest save of the set-aside record ended.
enum QuarantineCopy { saved, notWritten }

/// The backup line of the data line.
sealed class BackupLine extends Equatable {
  const BackupLine();
}

/// The record was backed up on [day] (`YYYY-MM-DD`).
final class BackedUp extends BackupLine {
  const BackedUp(this.day);

  final String day;

  @override
  List<Object?> get props => [day];
}

/// The platform failed to write the backup.
final class BackupNotWritten extends BackupLine {
  const BackupNotWritten();

  @override
  List<Object?> get props => const [];
}

/// The reset line of the data line.
sealed class ResetLine extends Equatable {
  const ResetLine();
}

/// The record was reset and can be restored for [secondsLeft] more seconds.
final class ResetCounting extends ResetLine {
  const ResetCounting(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object?> get props => [secondsLeft];
}

/// The record was reset and the time to undo it has passed.
final class ResetClosed extends ResetLine {
  const ResetClosed();

  @override
  List<Object?> get props => const [];
}

/// The files could not be deleted, so nothing was erased and there is no undo (Decision A41).
final class ResetNotFinished extends ResetLine {
  const ResetNotFinished();

  @override
  List<Object?> get props => const [];
}

/// A file read for restore that waits for the reader to confirm replacing [local], whose [Tally] the dialog shows.
final class PendingRestore extends Equatable {
  const PendingRestore({required this.data, required this.local});

  final RecordData data;
  final Tally local;

  @override
  List<Object?> get props => [data, local];
}

/// The data line of the Settings page.
///
/// A single state with a status: CLAUDE.md exception 1 (concurrent state access). The data line shows
/// its last outcome while its four actions stay available, and a backup line, a restore line and a
/// reset line can stand at the same time, as on the web (DataPanel.tsx:236-266).
final class DataState extends Equatable {
  const DataState({
    this.busy = DataBusy.idle,
    this.backup,
    this.restore,
    this.pendingRestore,
    this.reset,
    this.quarantineCopy,
  });

  final DataBusy busy;
  final BackupLine? backup;
  final RestoreOutcome? restore;
  final PendingRestore? pendingRestore;
  final ResetLine? reset;
  final QuarantineCopy? quarantineCopy;

  /// This state with the fields given replaced; a field passed as null is cleared.
  DataState _with({
    DataBusy? busy,
    Object? backup = _keep,
    Object? restore = _keep,
    Object? pendingRestore = _keep,
    Object? reset = _keep,
    Object? quarantineCopy = _keep,
  }) => DataState(
    busy: busy ?? this.busy,
    backup: identical(backup, _keep) ? this.backup : backup as BackupLine?,
    restore: identical(restore, _keep) ? this.restore : restore as RestoreOutcome?,
    pendingRestore: identical(pendingRestore, _keep) ? this.pendingRestore : pendingRestore as PendingRestore?,
    reset: identical(reset, _keep) ? this.reset : reset as ResetLine?,
    quarantineCopy: identical(quarantineCopy, _keep) ? this.quarantineCopy : quarantineCopy as QuarantineCopy?,
  );

  @override
  List<Object?> get props => [busy, backup, restore, pendingRestore, reset, quarantineCopy];
}

/// Marks a field of [DataState._with] that keeps its value.
const _keep = Object();
