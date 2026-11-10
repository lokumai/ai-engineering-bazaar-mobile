import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart' show PlatformException;

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';

/// [IBackupGateway] over `file_picker`.
///
/// Save takes the system save dialog on both Android and iOS: the picker measurement of 2026-11-09 found that
/// `FilePicker.saveFile` answers a non-null [Uri] once the file is written and `null` when the dialog is closed, and
/// throws when the write fails, on both platforms. Only null versus non-null is read: Android answers the document's
/// path without a scheme, so the [Uri] itself carries nothing to rely on.
///
/// Each seam defaults to the real plugin call; tests replace them, so constructing the gateway calls no plugin.
final class PlatformBackupGateway implements IBackupGateway {
  PlatformBackupGateway({
    Future<Uri?> Function(String filename, Uint8List bytes)? saveFile,
    Future<PlatformFile?> Function()? pickFile,
  }) : _saveFile = saveFile ?? _pluginSaveFile,
       _pickFile = pickFile ?? _pluginPickFile;

  static final _log = AppLogger.getLogger('PlatformBackupGateway');

  final Future<Uri?> Function(String filename, Uint8List bytes) _saveFile;
  final Future<PlatformFile?> Function() _pickFile;

  static Future<Uri?> _pluginSaveFile(String filename, Uint8List bytes) =>
      FilePicker.saveFile(fileName: filename, bytes: bytes, mimeType: 'application/json');

  static Future<PlatformFile?> _pluginPickFile() {
    final (type, extensions) = backupPickFilter(defaultTargetPlatform);
    return FilePicker.pickFile(type: type, allowedExtensions: extensions);
  }

  /// The largest file read as a backup. A record is a few kilobytes; a file past this is not one, and reading it
  /// whole could run the app out of memory, so it is refused before it is read.
  static const maxBackupBytes = 16 * 1024 * 1024;

  @override
  Future<BackupSaveResult> save(Uint8List bytes, String filename) async {
    final saved = await _saveFile(filename, bytes);
    return saved == null ? BackupSaveResult.dismissed : BackupSaveResult.saved;
  }

  @override
  Future<PickedBackup> pickJson() async {
    final PlatformFile? file;
    try {
      file = await _pickFile();
    } on PlatformException catch (error) {
      // Both plugins copy the picked document during the pick, so a file they cannot load fails here (Android
      // `unknown_path`, iOS `load_failed`); only the code is logged, never a path.
      _log.warn('Backup file not loaded: {}', [error.code]);
      return const PickedBackupUnreadable();
    }
    if (file == null) return const PickedBackupCancelled();
    try {
      final length = await file.length();
      if (length != null && length > maxBackupBytes) {
        _log.warn('Backup file too large: {} bytes', [length]);
        return const PickedBackupUnreadable();
      }
      return PickedBackupBytes(bytes: await file.readAsBytes());
    } on Exception catch (error) {
      _log.warn('Backup file unreadable: {}', [error.runtimeType]);
      return const PickedBackupUnreadable();
    }
  }
}

/// What the restore picker offers on [platform] (plan 4.6). Android shows every file: a `.json` filter becomes the
/// `application/json` type, and a provider that labels a backup otherwise (`application/octet-stream`, `text/plain`)
/// greys it out, so the reader could not pick their own backup. A file that is not a backup is refused when read, as
/// on the web. iOS keeps the `.json` filter, which it matches by the file's name.
(FileType, List<String>?) backupPickFilter(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => (FileType.any, null),
  _ => (FileType.custom, const ['json']),
};
