import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// One text file of the app's own, at `<baseDirectory>/<path>`, apart from the record: written to `<path>.tmp` with a
/// flush and renamed over the file, so a crash leaves the old text or the new, never half of one.
///
/// Writes and deletes of one file run one at a time, in the order made, even from two stores over the same file: two
/// at once would share the `.tmp` file, and the text kept could be either, or neither.
///
/// A file that cannot be read reads as null, and one that cannot be written is logged and stays as it was. A file
/// there that could not be read (an I/O error, no folder from the phone) is not written over until a read succeeds or
/// it is deleted: the text in it may be the reader's, and a feature that started without it would replace it with
/// its own fresh start (review 5, finding 2). Bytes that are not text are not held: no read would ever succeed.
/// `baseDirectory` is called on first use and its result kept; a call that fails is not kept.
final class FileTextStore {
  FileTextStore({required this._baseDirectory, required this._path});

  static final _log = AppLogger.getLogger('FileTextStore');

  final Future<Directory> Function() _baseDirectory;
  final String _path;

  File? _resolved;

  /// Whether the last read failed with the file perhaps there: writes wait for a read that succeeds, or a delete.
  bool _held = false;

  /// The last write or delete of each file, by its path under the base directory, which the next one waits for.
  static final Map<String, Future<void>> _last = {};

  /// Runs [change] after the changes to this file made before it.
  Future<void> _inTurn(Future<void> Function() change) {
    final previous = _last[_path] ?? Future<void>.value();
    // One that failed was its own caller's to hear; the next still runs.
    final next = previous.then((_) {}, onError: (Object _) {}).then((_) => change());
    _last[_path] = next;
    // The queue forgets a file once nothing waits on it. An error is the caller's: this copy of it is let go.
    next.whenComplete(() {
      if (identical(_last[_path], next)) _last.remove(_path);
    }).ignore();
    return next;
  }

  Future<File> _file() async => _resolved ??= File('${(await _baseDirectory()).path}/$_path');

  /// The file's text, or null when there is none or it cannot be read.
  Future<String?> read() async {
    try {
      final file = await _file();
      // Bytes first, then the text: readAsString reports bytes that are not UTF-8 as a FileSystemException, which
      // would hold the file for good.
      final text = await file.exists() ? utf8.decode(await file.readAsBytes()) : null;
      _held = false;
      return text;
    } on FileSystemException catch (error) {
      _log.warn('{} not read: {}', [_path, error]);
      _held = true;
      return null;
    } on FormatException catch (error) {
      // Bytes that are not UTF-8 text: as unreadable as a file that cannot be opened, so the app starts without it.
      _log.warn('{} not text: {}', [_path, error]);
      _held = false;
      return null;
    } on Object catch (error) {
      // No folder from the phone (path_provider throws its own errors): unreadable too, so a feature that loads its
      // file at start is never left waiting (plan 20.5). A write's error stays the caller's.
      _log.warn('{} not read, no folder: {}', [_path, error]);
      _held = true;
      return null;
    }
  }

  /// Replaces the file's text with [text].
  Future<void> write(String text) => _inTurn(() async {
    if (_held) {
      _log.warn('{} not written: it could not be read, and may hold what is kept', [_path]);
      return;
    }
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(text, flush: true);
      await temporary.rename(file.path);
    } on FileSystemException catch (error) {
      _log.warn('{} not written: {}', [_path, error]);
    }
  });

  /// Moves the file to `<path>.unreadable`, over an older one there, so the next write does not replace what this
  /// version of the app could not read: a damaged file, or one a later version wrote in its own shape (opus review 11,
  /// record finding 7). A file that cannot be moved stays, and the next write replaces it, as before.
  Future<void> setAside() => _inTurn(() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.rename('${file.path}.unreadable');
    } on FileSystemException catch (error) {
      _log.warn('{} not set aside: {}', [_path, error]);
    }
  });

  /// Removes the file; a file that is not there stays so.
  Future<void> delete() => _inTurn(() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
      _held = false;
    } on FileSystemException catch (error) {
      _log.warn('{} not deleted: {}', [_path, error]);
    }
  });
}
