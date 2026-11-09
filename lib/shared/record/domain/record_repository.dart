import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';

/// The record's files as they are on the device; `null` for a file that does not exist.
final class StoredBytes extends Equatable {
  const StoredBytes({required this.record, required this.quarantine});

  /// The bytes of `record.json`.
  final Uint8List? record;

  /// The bytes of `record-quarantine.json`.
  final Uint8List? quarantine;

  @override
  List<Object?> get props => [record, quarantine];
}

/// What the launch read found (spec 3.3.9).
sealed class RecordLoad extends Equatable {
  const RecordLoad({required this.quarantineKept});

  /// Whether `record-quarantine.json` exists when the launch read returns.
  final bool quarantineKept;
}

/// No record: no file, or a file holding only whitespace.
final class RecordLoadEmpty extends RecordLoad {
  const RecordLoadEmpty({required super.quarantineKept});

  @override
  List<Object?> get props => [quarantineKept];
}

/// A stored record this app reads.
final class RecordLoadOk extends RecordLoad {
  const RecordLoadOk({required this.data, required super.quarantineKept});

  final RecordData data;

  @override
  List<Object?> get props => [data, quarantineKept];
}

/// A stored record set aside in `record-quarantine.json`; the record reads as absent.
final class RecordLoadQuarantined extends RecordLoad {
  const RecordLoadQuarantined({required this.reason, required super.quarantineKept});

  final QuarantineReason reason;

  @override
  List<Object?> get props => [reason, quarantineKept];
}

/// The launch read hit an I/O error other than not-found, so the stored record is unread and must not be overwritten.
final class RecordLoadFailed extends RecordLoad {
  const RecordLoadFailed({required super.quarantineKept});

  @override
  List<Object?> get props => [quarantineKept];
}

/// The outcome of a record write (spec 3.3.9).
enum WriteResult {
  saved,

  /// The device is out of space (ENOSPC).
  quota,

  /// Any other file system error.
  blocked,
}

/// The record's storage on the device (spec 3.3.9).
///
/// [load], [write], [deleteAll], [restore] and [deleteQuarantine] are called only from `RecordBloc`'s one serial
/// queue, so no two of them overlap. [readStored] changes nothing, so `DataBloc` may also call it to export the
/// quarantined bytes.
///
/// [readStored], [deleteAll], [restore] and [deleteQuarantine] throw a `FileSystemException` on an I/O error other
/// than not-found; `RecordBloc` handles that for an erase (Decision A41).
abstract interface class IRecordRepository {
  /// The launch read: reads `record.json` with `parseEnvelope` and copies quarantined bytes to
  /// `record-quarantine.json` unless it already holds the same bytes.
  Future<RecordLoad> load();

  /// Writes [compactJson] to `record.json.tmp` with a flush, then renames it over `record.json`.
  Future<WriteResult> write(String compactJson);

  Future<StoredBytes> readStored();

  /// Deletes `record.json`, `record-quarantine.json` and `record.json.tmp`; a missing file is not an error.
  Future<void> deleteAll();

  /// Writes each non-null field of [bytes] back to its file.
  Future<void> restore(StoredBytes bytes);

  /// Deletes `record-quarantine.json`; a missing file is not an error.
  Future<void> deleteQuarantine();
}
