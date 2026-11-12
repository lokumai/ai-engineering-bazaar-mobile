import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';

/// The record in files under `<baseDirectory>/record/` (spec 3.3.9): `record.json`, `record-quarantine.json` and
/// their `.tmp` files.
///
/// The app passes `getApplicationSupportDirectory()`, which on Android is `filesDir`, the Auto Backup domain `file`
/// (Task 8.7). `baseDirectory` is called on first use and its result kept, so every method works in one directory; a
/// call that fails is not kept, so the next method asks again.
final class FileRecordRepository implements IRecordRepository {
  FileRecordRepository({required this._baseDirectory});

  static final _log = AppLogger.getLogger('FileRecordRepository');

  /// ENOSPC on Linux, Android and Darwin.
  static const _noSpace = 28;

  final Future<Directory> Function() _baseDirectory;

  Directory? _resolved;

  Future<Directory> get _directory async => _resolved ??= Directory('${(await _baseDirectory()).path}/record');

  Future<File> _file(String name) async => File('${(await _directory).path}/$name');

  Future<File> get _record => _file('record.json');

  Future<File> get _tmp => _file('record.json.tmp');

  Future<File> get _quarantine => _file('record-quarantine.json');

  Future<File> get _quarantineTmp => _file('record-quarantine.json.tmp');

  @override
  Future<RecordLoad> load() async {
    final File quarantine;
    try {
      quarantine = await _quarantine;
    } on FileSystemException catch (error) {
      // A support directory that cannot be made (a full device on a fresh iOS install) is a failed launch read.
      _log.error('record directory unavailable: {}', [error]);
      return const RecordLoadFailed(quarantineKept: false);
    }
    final Uint8List bytes;
    try {
      bytes = await (await _record).readAsBytes();
    } on PathNotFoundException {
      return RecordLoadEmpty(quarantineKept: await quarantine.exists());
    } on FileSystemException catch (error) {
      _log.error('record launch read failed: {}', [error]);
      return RecordLoadFailed(quarantineKept: await quarantine.exists());
    }

    // The launch read never runs envelopeTextFrom (correction row 3.3.14): a stored array is malformed.
    switch (parseEnvelope(decodeRecordBytes(bytes))) {
      case EnvelopeEmpty():
        return RecordLoadEmpty(quarantineKept: await quarantine.exists());
      case EnvelopeOk(:final data):
        return RecordLoadOk(data: data, quarantineKept: await quarantine.exists());
      case EnvelopeQuarantine(:final reason):
        _log.warn('record set aside: {}', [reason]);
        try {
          await _setAside(quarantine, bytes);
        } on FileSystemException catch (error) {
          _log.error('record quarantine copy failed: {}', [error]);
          return RecordLoadFailed(quarantineKept: await quarantine.exists());
        }
        return RecordLoadQuarantined(reason: reason, quarantineKept: await quarantine.exists());
    }
  }

  /// Copies the original [bytes] to [quarantine] unless it already holds the same bytes; `record.json` stays.
  Future<void> _setAside(File quarantine, Uint8List bytes) async {
    if (await quarantine.exists() && listEquals(await quarantine.readAsBytes(), bytes)) return;
    await quarantine.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<WriteResult> write(String compactJson) async {
    try {
      await _replaceRecord(utf8.encode(compactJson));
      return WriteResult.saved;
    } on FileSystemException catch (error) {
      _log.error('record write failed: {}', [error]);
      return _resultOf(error);
    }
  }

  static WriteResult _resultOf(FileSystemException error) =>
      error.osError?.errorCode == _noSpace ? WriteResult.quota : WriteResult.blocked;

  /// Writes [bytes] to `record.json.tmp` with a flush and renames it over `record.json`.
  Future<void> _replaceRecord(List<int> bytes) => _replace(_tmp, _record, bytes);

  /// Writes [bytes] to [tmp] with a flush and renames it over [target], so [target] is never left half written.
  Future<void> _replace(Future<File> tmp, Future<File> target, List<int> bytes) async {
    await (await _directory).create(recursive: true);
    final written = await tmp;
    await written.writeAsBytes(bytes, flush: true);
    await written.rename((await target).path);
  }

  @override
  Future<StoredBytes> readStored() async =>
      StoredBytes(record: await _readOrNull(await _record), quarantine: await _readOrNull(await _quarantine));

  Future<Uint8List?> _readOrNull(File file) async {
    try {
      return await file.readAsBytes();
    } on PathNotFoundException {
      return null;
    }
  }

  /// `record.json` goes last, so an error on any other file leaves the record where it was.
  @override
  Future<void> deleteAll() async {
    await _deleteIfPresent(await _tmp);
    await _deleteIfPresent(await _quarantineTmp);
    await _deleteIfPresent(await _quarantine);
    await _deleteIfPresent(await _record);
  }

  @override
  Future<RestoreResult> restore(StoredBytes bytes) async {
    var write = WriteResult.saved;
    Future<void> attempt(Future<void> Function() replace) async {
      try {
        await replace();
      } on FileSystemException catch (error) {
        _log.error('record restore failed: {}', [error]);
        if (write == WriteResult.saved) write = _resultOf(error);
      }
    }

    if (bytes.record case final record?) await attempt(() => _replaceRecord(record));
    if (bytes.quarantine case final quarantine?) await attempt(() => _replace(_quarantineTmp, _quarantine, quarantine));
    return RestoreResult(write: write, quarantineKept: await (await _quarantine).exists());
  }

  @override
  Future<void> deleteQuarantine() async => _deleteIfPresent(await _quarantine);

  Future<void> _deleteIfPresent(File file) async {
    try {
      await file.delete();
    } on PathNotFoundException {
      return;
    }
  }
}
