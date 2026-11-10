import 'dart:io';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// One text file of the app's own, at `<baseDirectory>/<path>`, apart from the record: written to `<path>.tmp` with a
/// flush and renamed over the file, so a crash leaves the old text or the new, never half of one.
///
/// A file that cannot be read reads as null, and one that cannot be written is logged and stays as it was.
/// `baseDirectory` is called on first use and its result kept; a call that fails is not kept.
final class FileTextStore {
  FileTextStore({required this._baseDirectory, required this._path});

  static final _log = AppLogger.getLogger('FileTextStore');

  final Future<Directory> Function() _baseDirectory;
  final String _path;

  File? _resolved;

  Future<File> _file() async => _resolved ??= File('${(await _baseDirectory()).path}/$_path');

  /// The file's text, or null when there is none or it cannot be read.
  Future<String?> read() async {
    try {
      final file = await _file();
      return await file.exists() ? await file.readAsString() : null;
    } on FileSystemException catch (error) {
      _log.warn('{} not read: {}', [_path, error]);
      return null;
    }
  }

  /// Replaces the file's text with [text].
  Future<void> write(String text) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(text, flush: true);
      await temporary.rename(file.path);
    } on FileSystemException catch (error) {
      _log.warn('{} not written: {}', [_path, error]);
    }
  }

  /// Removes the file; a file that is not there stays so.
  Future<void> delete() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error) {
      _log.warn('{} not deleted: {}', [_path, error]);
    }
  }
}
