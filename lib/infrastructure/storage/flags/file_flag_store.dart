import 'dart:io';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// Named on and off flags of the app itself, one empty file each under `<baseDirectory>/flags/`, apart from the
/// record (the record stays the web's, byte for byte, R60).
///
/// A flag is set once and never cleared. A flag that cannot be read counts as not set, and one that cannot be written
/// is logged and stays unset: the app then shows again what the flag would have hidden, which costs a tap, never data.
/// `baseDirectory` is called on first use and its result kept; a call that fails is not kept.
final class FileFlagStore {
  FileFlagStore({required this._baseDirectory});

  static final _log = AppLogger.getLogger('FileFlagStore');

  final Future<Directory> Function() _baseDirectory;

  Directory? _resolved;

  Future<File> _file(String name) async {
    final directory = _resolved ??= Directory('${(await _baseDirectory()).path}/flags');
    return File('${directory.path}/$name');
  }

  /// Whether the flag [name] is set.
  Future<bool> isSet(String name) async {
    try {
      return await (await _file(name)).exists();
    } on FileSystemException catch (error) {
      _log.warn('flag {} not read: {}', [name, error]);
      return false;
    }
  }

  /// Sets the flag [name].
  Future<void> set(String name) async {
    try {
      final file = await _file(name);
      await file.create(recursive: true);
    } on FileSystemException catch (error) {
      _log.warn('flag {} not written: {}', [name, error]);
    }
  }
}
