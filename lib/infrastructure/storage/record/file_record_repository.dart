import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_text.dart';

/// The record in files under `<baseDirectory>/record/` (spec 3.3.9): `record.json`, `record.json.tmp` and
/// `record-quarantine.json`.
///
/// The app passes `getApplicationSupportDirectory()`, which on Android is `filesDir`, the Auto Backup domain `file`
/// (Task 8.7). `baseDirectory` is called on first use and its result kept, so every method works in one directory.
final class FileRecordRepository implements IRecordRepository {
  FileRecordRepository({required this._baseDirectory});

  static final _log = AppLogger.getLogger('FileRecordRepository');

  /// ENOSPC on Linux, Android and Darwin.
  static const _noSpace = 28;

  final Future<Directory> Function() _baseDirectory;

  late final Future<Directory> _directory = _baseDirectory().then((base) => Directory('${base.path}/record'));

  Future<File> _file(String name) async => File('${(await _directory).path}/$name');

  Future<File> get _record => _file('record.json');

  Future<File> get _tmp => _file('record.json.tmp');

  Future<File> get _quarantine => _file('record-quarantine.json');

  @override
  Future<RecordLoad> load() async {
    final quarantine = await _quarantine;
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
      return error.osError?.errorCode == _noSpace ? WriteResult.quota : WriteResult.blocked;
    }
  }

  /// Writes [bytes] to `record.json.tmp` with a flush and renames it over `record.json`.
  Future<void> _replaceRecord(List<int> bytes) async {
    await (await _directory).create(recursive: true);
    final tmp = await _tmp;
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename((await _record).path);
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

  @override
  Future<void> deleteAll() async {
    await _deleteIfPresent(await _record);
    await _deleteIfPresent(await _quarantine);
    await _deleteIfPresent(await _tmp);
  }

  @override
  Future<void> restore(StoredBytes bytes) async {
    final record = bytes.record;
    final quarantine = bytes.quarantine;
    if (record != null) await _replaceRecord(record);
    if (quarantine != null) {
      await (await _directory).create(recursive: true);
      await (await _quarantine).writeAsBytes(quarantine, flush: true);
    }
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
