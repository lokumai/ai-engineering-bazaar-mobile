import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

  static Future<PlatformFile?> _pluginPickFile() =>
      FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['json']);

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
      return PickedBackupBytes(bytes: await file.readAsBytes());
    } on Exception catch (error) {
      _log.warn('Backup file unreadable: {}', [error.runtimeType]);
      return const PickedBackupUnreadable();
    }
  }
}
