part of 'data_bloc.dart';

sealed class DataEvent {
  const DataEvent();
}

/// The reader asked to back the record up to a file (spec 3.3.10).
final class BackupRequested extends DataEvent {
  const BackupRequested();
}

/// The reader asked to restore the record from a file (spec 3.3.10).
final class RestoreRequested extends DataEvent {
  const RestoreRequested();
}

/// The reader confirmed replacing the record with the file waiting in [DataState.pendingRestore].
final class RestoreConfirmed extends DataEvent {
  const RestoreConfirmed();
}

/// The reader kept the record instead of the file waiting in [DataState.pendingRestore].
final class RestoreDeclined extends DataEvent {
  const RestoreDeclined();
}

/// The reader confirmed the reset; the dialog has already checked `confirmsErase` (spec 3.3.11).
final class ResetConfirmed extends DataEvent {
  const ResetConfirmed();
}

/// The reader asked to undo the reset while its countdown runs.
final class UndoRequested extends DataEvent {
  const UndoRequested();
}

/// The countdown's ticker fired; only DataBloc adds it.
final class UndoTicked extends DataEvent {
  const UndoTicked();
}

/// The reader asked to save the set-aside record to a file (spec 3.3.9).
final class QuarantineExportRequested extends DataEvent {
  const QuarantineExportRequested();
}

/// The reader confirmed deleting the set-aside record (spec 3.3.9).
final class QuarantineDeleteConfirmed extends DataEvent {
  const QuarantineDeleteConfirmed();
}
