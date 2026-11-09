part of 'record_bloc.dart';

sealed class RecordEvent {
  const RecordEvent();
}

/// The app started: run the launch read (spec 3.3.9).
final class RecordStarted extends RecordEvent {
  const RecordStarted();
}

/// The reader toggled the completion of [key] on [track]; [revision] is the track's `revision.hash` from the reader,
/// null from the progress page (Decision A35). Build it with `completionToggled`, which fills [everyone].
final class CompletionToggled extends RecordEvent {
  const CompletionToggled({required this.key, required this.revision, required this.track, this.everyone});

  final String key;
  final String? revision;
  final Track track;

  /// The For Everyone version that a For Engineers completion completes as well, when it is written (plan 1V); null
  /// otherwise. Removing a completion never touches it.
  final EveryoneCompletion? everyone;
}

/// The For Everyone version of a module, completed along with its For Engineers version (plan 1V).
final class EveryoneCompletion {
  const EveryoneCompletion({required this.revision});

  /// The For Everyone `revision.hash`, null where the caller passes none (A35).
  final String? revision;
}

/// A backup starts at [at]: mark the day, write, and complete [reply] with the export bytes (spec 3.3.10).
final class BackupStarted extends RecordEvent {
  const BackupStarted({required this.at, required this.reply});

  final String at;
  final Completer<RecordBackup> reply;
}

/// The platform reported the backup saved or shared: mark `lastExport` with [at] and write (Decision A19).
final class BackupCompleted extends RecordEvent {
  const BackupCompleted({required this.at});

  final String at;
}

/// An imported record replaces the record: written at once, with no day stamp, and an open undo closes (A33).
final class RecordReplaced extends RecordEvent {
  const RecordReplaced({required this.data});

  final RecordData data;
}

/// The reader confirmed an erase at [at] (spec 3.3.11, Decision A41).
///
/// [reply] completes with true once the record is erased, and with false when the files could not be deleted or the
/// event was ignored.
final class RecordErased extends RecordEvent {
  const RecordErased({required this.at, this.reply});

  final DateTime at;
  final Completer<bool>? reply;
}

/// The reader asked to undo the erase while its window is open.
final class EraseUndone extends RecordEvent {
  const EraseUndone();
}

/// The undo window ended; only RecordBloc's own timer adds it (Decision A42).
final class UndoExpired extends RecordEvent {
  const UndoExpired();
}

/// The reader confirmed deleting the quarantined bytes.
final class QuarantineDeleted extends RecordEvent {
  const QuarantineDeleted();
}

/// The bytes of a backup file and its name.
final class RecordBackup extends Equatable {
  const RecordBackup({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  @override
  List<Object?> get props => [bytes, filename];
}
