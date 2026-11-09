import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// What the platform reported for a backup handed to it (spec 3.3.10 export step 4, A19).
enum BackupSaveResult {
  /// The platform reports the file as written.
  saved,

  /// The platform reports a completed share.
  shared,

  /// Nothing was written: the reader closed the dialog or the sheet.
  dismissed,
}

/// The outcome of the import picker.
sealed class PickedBackup extends Equatable {
  const PickedBackup();
}

/// A file was chosen and read.
final class PickedBackupBytes extends PickedBackup {
  const PickedBackupBytes({required this.bytes});

  final Uint8List bytes;

  @override
  List<Object?> get props => [bytes];
}

/// The picker was closed without a file.
final class PickedBackupCancelled extends PickedBackup {
  const PickedBackupCancelled();

  @override
  List<Object?> get props => const [];
}

/// A file was chosen, but its bytes could not be read.
final class PickedBackupUnreadable extends PickedBackup {
  const PickedBackupUnreadable();

  @override
  List<Object?> get props => const [];
}

/// Hands a backup to the platform and picks a backup file to restore (spec 3.3.10).
abstract interface class IBackupGateway {
  /// Offers [bytes] to the reader to keep as [filename]; a failed write throws.
  Future<BackupSaveResult> save(Uint8List bytes, String filename);

  /// Lets the reader choose a backup; the picker offers `.json` files only (spec 3.3.10).
  Future<PickedBackup> pickJson();
}
