import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/infrastructure/backup/platform_backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';

/// A picked file whose name and bytes the test sets; [readAsBytes] throws [error] when it is given.
const _at = '2026-11-24T10:00:00.000Z';

final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({this.bytes, this.error});

  final List<int>? bytes;
  final Exception? error;

  /// How many times the bytes were read.
  int reads = 0;

  @override
  String get name => 'hl-record-2026-03-15.json';

  @override
  Future<Uint8List> readAsBytes() async {
    reads++;
    if (error case final error?) throw error;
    return Uint8List.fromList(bytes!);
  }

  @override
  Uri get uri => throw UnimplementedError();

  // The type is inferred from PlatformFile: cross_file, which declares it, is not a direct dependency.
  @override
  get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => throw UnimplementedError();

  @override
  Future<int?> length() async => lengthUnknown ? null : fakeLength ?? bytes?.length;

  /// The length the file reports, when the test sets one apart from its bytes.
  int? fakeLength;

  /// Whether the file reports no length, as a provider that cannot tell its size does.
  bool lengthUnknown = false;

  /// The chunks [readAsByteStream] gives, and how many of them were taken.
  Iterable<List<int>>? chunks;
  int chunksTaken = 0;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.fromIterable(
    chunks!.map((chunk) {
      chunksTaken++;
      return Uint8List.fromList(chunk);
    }),
  );
}

void main() {
  final bytes = Uint8List.fromList([123, 125]);
  const filename = 'hl-record-2026-03-15.json';

  group('save', () {
    test('reports saved when the picker answers a Uri', () async {
      final gateway = PlatformBackupGateway(saveFile: (_, _) async => Uri.parse('content://x/1'));

      expect(await gateway.save(bytes, filename), BackupSaveResult.saved);
    });

    test('reports saved for the scheme-less Uri Android answers', () async {
      final gateway = PlatformBackupGateway(saveFile: (_, _) async => Uri.parse('/document/39'));

      expect(await gateway.save(bytes, filename), BackupSaveResult.saved);
    });

    test('reports dismissed when the picker answers null', () async {
      final gateway = PlatformBackupGateway(saveFile: (_, _) async => null);

      expect(await gateway.save(bytes, filename), BackupSaveResult.dismissed);
    });

    test('passes the filename and the bytes unchanged', () async {
      String? savedName;
      Uint8List? savedBytes;
      final gateway = PlatformBackupGateway(
        saveFile: (name, data) async {
          savedName = name;
          savedBytes = data;
          return Uri.parse('content://x/1');
        },
      );

      await gateway.save(bytes, filename);

      expect(savedName, filename);
      expect(savedBytes, [123, 125]);
    });

    test('lets a failed write reach the caller', () async {
      final gateway = PlatformBackupGateway(saveFile: (_, _) async => throw const FileSystemException('full'));

      await expectLater(gateway.save(bytes, filename), throwsA(isA<FileSystemException>()));
    });
  });

  group('pickJson', () {
    test('reports the bytes of the chosen file', () async {
      final gateway = PlatformBackupGateway(pickFile: () async => _FakePlatformFile(bytes: [123, 125]));

      final picked = await gateway.pickJson();

      expect(picked, isA<PickedBackupBytes>().having((picked) => picked.bytes, 'bytes', [123, 125]));
    });

    test('reports a cancel', () async {
      final gateway = PlatformBackupGateway(pickFile: () async => null);

      expect(await gateway.pickJson(), isA<PickedBackupCancelled>());
    });

    test('reports a file it cannot read', () async {
      final gateway = PlatformBackupGateway(
        pickFile: () async => _FakePlatformFile(bytes: const [123], error: const FileSystemException('denied')),
      );

      expect(await gateway.pickJson(), isA<PickedBackupUnreadable>());
    });

    // Android answers unknown_path and iOS load_failed when the picked document cannot be copied for the app.
    for (final code in ['unknown_path', 'load_failed']) {
      test('reports a file the picker could not load as unreadable ($code)', () async {
        final gateway = PlatformBackupGateway(pickFile: () async => throw PlatformException(code: code));

        expect(await gateway.pickJson(), isA<PickedBackupUnreadable>());
      });
    }

    test('lets an error of the picker other than a platform failure reach the caller', () async {
      final gateway = PlatformBackupGateway(pickFile: () async => throw StateError('picker'));

      await expectLater(gateway.pickJson(), throwsStateError);
    });
  });

  group('the restore picker', () {
    test('shows every file on Android, where a provider may label a backup other than application/json', () {
      expect(backupPickFilter(TargetPlatform.android), (FileType.any, null));
    });

    test('keeps the json filter on iOS', () {
      final (type, extensions) = backupPickFilter(TargetPlatform.iOS);
      expect(type, FileType.custom);
      expect(extensions, ['json']);
    });

    // Review 6, finding 11: the file's read threw, so the test passed without the size check.
    test('refuses a file larger than a backup could be, before reading it', () async {
      final file = _FakePlatformFile(bytes: [123, 125])..fakeLength = PlatformBackupGateway.maxBackupBytes + 1;
      final gateway = PlatformBackupGateway(pickFile: () async => file);

      // Opus review 11, record finding 9: too large, not "could not be opened".
      expect(await gateway.pickJson(), isA<PickedBackupTooLarge>());
      expect(file.reads, 0, reason: 'never read');
    });

    // Review 7, finding 7: a file whose length the picker cannot tell was read whole, whatever its size.
    test('reads a file of unknown length by its stream, and refuses it past the limit', () async {
      const chunk = 1024 * 1024;
      final file = _FakePlatformFile()
        ..lengthUnknown = true
        ..chunks = Iterable.generate(1000, (_) => List.filled(chunk, 32));
      final gateway = PlatformBackupGateway(pickFile: () async => file);

      expect(await gateway.pickJson(), isA<PickedBackupTooLarge>());
      expect(file.reads, 0, reason: 'never read whole');
      expect(file.chunksTaken * chunk, lessThanOrEqualTo(PlatformBackupGateway.maxBackupBytes + chunk));
    });

    test('reads a small file of unknown length whole', () async {
      final file = _FakePlatformFile()
        ..lengthUnknown = true
        ..chunks = [
          [123],
          [125],
        ];
      final gateway = PlatformBackupGateway(pickFile: () async => file);

      final picked = await gateway.pickJson();
      expect(picked, isA<PickedBackupBytes>().having((backup) => backup.bytes, 'bytes', [123, 125]));
    });

    // Review 9, finding 4: the limit was 16 MB, and a file of nested arrays under it cost close to 1 GB to decode.
    test('the limit is 2 MB, and the export of a record at its cap fits under it', () {
      expect(PlatformBackupGateway.maxBackupBytes, 2 * 1024 * 1024);
      var record = RecordData.empty;
      // Completions added 500 at a time, until the compact record passes its cap.
      for (var i = 0; utf8.encode(serialise(record, _at, pretty: false)).length < RecordConstants.softCapBytes;) {
        for (final end = i + 500; i < end; i++) {
          record = signOff(record, 'level-$i/module-$i', 'a1b2c3d', _at);
        }
      }
      expect(utf8.encode(serialise(record, _at, pretty: true)).length, lessThan(PlatformBackupGateway.maxBackupBytes));
    });

    test('reads a file at the limit', () async {
      final file = _FakePlatformFile(bytes: [123, 125])..fakeLength = PlatformBackupGateway.maxBackupBytes;
      final gateway = PlatformBackupGateway(pickFile: () async => file);

      expect(await gateway.pickJson(), isA<PickedBackupBytes>());
    });
  });
}
