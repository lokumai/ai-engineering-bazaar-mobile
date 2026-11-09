import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';

class _MockFile extends Mock implements File {}

void main() {
  const valid = '{"schema":1,"savedAt":"2026-03-14T08:00:00.000Z","data":{"sheets":{},"days":["2026-03-14"]}}';

  late Directory base;
  late FileRecordRepository repo;
  late File recordFile;
  late File tmpFile;
  late File quarantineFile;
  late File quarantineTmpFile;

  setUpAll(() => registerFallbackValue(<int>[]));

  setUp(() {
    base = Directory.systemTemp.createTempSync('record_repo_test_');
    repo = FileRecordRepository(baseDirectory: () async => base);
    recordFile = File('${base.path}/record/record.json');
    tmpFile = File('${base.path}/record/record.json.tmp');
    quarantineFile = File('${base.path}/record/record-quarantine.json');
    quarantineTmpFile = File('${base.path}/record/record-quarantine.json.tmp');
  });

  tearDown(() => base.deleteSync(recursive: true));

  group('load', () {
    test('no directory and no file is empty', () async {
      expect(await repo.load(), const RecordLoadEmpty(quarantineKept: false));
    });

    test('an empty or whitespace file is empty', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsStringSync('');
      expect(await repo.load(), const RecordLoadEmpty(quarantineKept: false));
      recordFile.writeAsStringSync(' \n');
      expect(await repo.load(), const RecordLoadEmpty(quarantineKept: false));
      expect(quarantineFile.existsSync(), isFalse);
    });

    test('a stored record loads through parseEnvelope', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsStringSync(valid);
      final load = await repo.load() as RecordLoadOk;
      expect(load.data.days, ['2026-03-14']);
      expect(load.quarantineKept, isFalse);
    });

    test('a stored array is malformed: the launch read does not call envelopeTextFrom', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsStringSync('[$valid]');
      expect(await repo.load(), const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true));
      expect(quarantineFile.readAsStringSync(), '[$valid]');
    });

    test('a malformed record is copied aside byte for byte and left in place', () async {
      final bytes = [0x7B, 0xFF, 0x7D];
      recordFile
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      expect(await repo.load(), const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true));
      expect(quarantineFile.readAsBytesSync(), bytes); // the original bytes, not the decoded U+FFFD
      expect(recordFile.readAsBytesSync(), bytes);
    });

    test('a newer record is quarantined as newer', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsStringSync('{"schema":2,"data":{}}');
      expect(await repo.load(), const RecordLoadQuarantined(reason: QuarantineReason.newer, quarantineKept: true));
      expect(quarantineFile.readAsStringSync(), '{"schema":2,"data":{}}');
      expect(recordFile.readAsStringSync(), '{"schema":2,"data":{}}');
    });

    test('identical quarantine bytes are not rewritten; different ones are replaced', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsBytesSync([0x7B, 0xFF, 0x7D]);
      await repo.load();
      final old = DateTime(2020);
      quarantineFile.setLastModifiedSync(old);

      expect(await repo.load(), const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true));
      expect(quarantineFile.lastModifiedSync(), old);

      recordFile.writeAsBytesSync([0x5B, 0x31]);
      expect(await repo.load(), const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true));
      expect(quarantineFile.readAsBytesSync(), [0x5B, 0x31]);
    });

    test('a quarantine file from an earlier launch is reported', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsStringSync(valid);
      quarantineFile.writeAsBytesSync([0x7B]);
      final load = await repo.load() as RecordLoadOk;
      expect(load.data.days, ['2026-03-14']);
      expect(load.quarantineKept, isTrue);
      expect(quarantineFile.readAsBytesSync(), [0x7B]);
    });

    test('a quarantine file is reported when there is no record', () async {
      quarantineFile
        ..createSync(recursive: true)
        ..writeAsBytesSync([0x7B]);
      expect(await repo.load(), const RecordLoadEmpty(quarantineKept: true));
    });

    test('an I/O error other than not-found fails the launch read', () async {
      Directory('${base.path}/record/record.json').createSync(recursive: true); // reading a directory fails (EISDIR)
      expect(await repo.load(), const RecordLoadFailed(quarantineKept: false));
    });

    test('a quarantine copy that cannot be written fails the launch read and leaves record.json alone', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsBytesSync([0x7B, 0xFF, 0x7D]);
      Directory('${base.path}/record/record-quarantine.json').createSync(); // writing over a directory fails
      expect(await repo.load(), const RecordLoadFailed(quarantineKept: false)); // a directory is not a kept file
      expect(recordFile.readAsBytesSync(), [0x7B, 0xFF, 0x7D]);
    });
  });

  test('a base directory that cannot be resolved fails the launch read and is asked again next time', () async {
    var calls = 0;
    final failing = FileRecordRepository(
      baseDirectory: () async {
        calls++;
        throw const FileSystemException('Creation failed', 'support', OSError('No space left on device', 28));
      },
    );
    expect(await failing.load(), const RecordLoadFailed(quarantineKept: false));
    expect(await failing.load(), const RecordLoadFailed(quarantineKept: false));
    expect(calls, 2);
  });

  test('the base directory is resolved once', () async {
    var calls = 0;
    final counted = FileRecordRepository(
      baseDirectory: () async {
        calls++;
        return base;
      },
    );
    await counted.load();
    await counted.write(valid);
    await counted.readStored();
    expect(calls, 1);
  });

  group('write', () {
    test('write goes through record.json.tmp and leaves no tmp', () async {
      expect(await repo.write(valid), WriteResult.saved);
      expect(recordFile.readAsStringSync(), valid);
      expect(tmpFile.existsSync(), isFalse);
    });

    test('write stores the UTF-8 bytes of the text', () async {
      const text = '{"schema":1,"savedAt":"2026-03-14T08:00:00.000Z","data":{"note":"ç\u{1F600}"}}';
      expect(await repo.write(text), WriteResult.saved);
      expect(recordFile.readAsStringSync(), text);
    });

    test('Review Focus 1: a kill between the tmp write and the rename loses nothing', () async {
      await repo.write(valid);
      tmpFile.writeAsStringSync('{"schema":1,"savedAt":"x","da'); // the half-finished next write
      final relaunched = FileRecordRepository(baseDirectory: () async => base);
      expect((await relaunched.load() as RecordLoadOk).data.days, ['2026-03-14']);
      expect(tmpFile.existsSync(), isTrue); // ignored, not deleted
      const next = '{"schema":1,"savedAt":"2026-03-15T07:10:00.000Z","data":{"days":["2026-03-15"]}}';
      expect(await relaunched.write(next), WriteResult.saved);
      expect(recordFile.readAsStringSync(), next);
      expect(tmpFile.existsSync(), isFalse);
    });

    test('ENOSPC is quota, any other file system error is blocked', () async {
      for (final (errno, result) in [(28, WriteResult.quota), (13, WriteResult.blocked)]) {
        final outcome = await IOOverrides.runZoned(
          () => repo.write(valid),
          createFile: (path) {
            final file = _MockFile();
            when(() => file.path).thenReturn(path);
            when(() => file.writeAsBytes(any(), flush: true))
                .thenThrow(FileSystemException('write', path, OSError('injected', errno)));
            return file;
          },
        );
        expect(outcome, result, reason: 'errno $errno');
      }
      expect(recordFile.existsSync(), isFalse);
    });

    test('an error that is not a file system error propagates', () async {
      await expectLater(
        IOOverrides.runZoned(
          () => repo.write(valid),
          createFile: (path) {
            final file = _MockFile();
            when(() => file.path).thenReturn(path);
            when(() => file.writeAsBytes(any(), flush: true)).thenThrow(StateError('injected'));
            return file;
          },
        ),
        throwsStateError,
      );
    });
  });

  group('stored bytes', () {
    test('readStored, deleteAll, restore and deleteQuarantine', () async {
      recordFile
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      quarantineFile.writeAsBytesSync([2]);
      tmpFile.writeAsBytesSync([3]);
      quarantineTmpFile.writeAsBytesSync([4]);

      expect(
        await repo.readStored(),
        StoredBytes(record: Uint8List.fromList([1]), quarantine: Uint8List.fromList([2])),
      );

      await repo.deleteAll();
      expect(recordFile.existsSync(), isFalse);
      expect(quarantineFile.existsSync(), isFalse);
      expect(tmpFile.existsSync(), isFalse);
      expect(quarantineTmpFile.existsSync(), isFalse);
      await repo.deleteAll(); // not-found is fine
      expect(await repo.readStored(), const StoredBytes(record: null, quarantine: null));

      expect(
        await repo.restore(StoredBytes(record: Uint8List.fromList([1]), quarantine: Uint8List.fromList([2]))),
        const RestoreResult(write: WriteResult.saved, quarantineKept: true),
      );
      expect(recordFile.readAsBytesSync(), [1]);
      expect(quarantineFile.readAsBytesSync(), [2]);
      expect(tmpFile.existsSync(), isFalse);
      expect(quarantineTmpFile.existsSync(), isFalse);

      await repo.deleteQuarantine();
      expect(quarantineFile.existsSync(), isFalse);
      expect(recordFile.readAsBytesSync(), [1]);
      await repo.deleteQuarantine(); // not-found is fine
    });

    test('restore writes nothing for a null field', () async {
      await repo.restore(StoredBytes(record: null, quarantine: Uint8List.fromList([2])));
      expect(recordFile.existsSync(), isFalse);
      expect(quarantineFile.readAsBytesSync(), [2]);

      await repo.restore(StoredBytes(record: Uint8List.fromList([1]), quarantine: null));
      expect(recordFile.readAsBytesSync(), [1]);
      expect(quarantineFile.readAsBytesSync(), [2]);
    });

    test('readStored and deleteAll throw on an I/O error other than not-found', () async {
      Directory('${base.path}/record/record.json/inner').createSync(recursive: true); // a non-empty directory
      final ioError = throwsA(allOf(isA<FileSystemException>(), isNot(isA<PathNotFoundException>())));
      await expectLater(repo.readStored(), ioError);
      await expectLater(repo.deleteAll(), ioError); // RecordBloc turns this into a reset that did not happen (A41)
    });

    test('deleteQuarantine throws on an I/O error other than not-found, restore answers blocked', () async {
      Directory('${base.path}/record/record-quarantine.json/inner').createSync(recursive: true);
      final ioError = throwsA(allOf(isA<FileSystemException>(), isNot(isA<PathNotFoundException>())));
      expect(
        await repo.restore(StoredBytes(record: null, quarantine: Uint8List.fromList([2]))),
        const RestoreResult(write: WriteResult.blocked, quarantineKept: false), // a directory is not a kept file
      );
      await expectLater(repo.deleteQuarantine(), ioError);
    });

    test('restore answers quota for ENOSPC and blocked for any other file system error', () async {
      for (final (errno, result) in [(28, WriteResult.quota), (13, WriteResult.blocked)]) {
        final outcome = await IOOverrides.runZoned(
          () => repo.restore(StoredBytes(record: Uint8List.fromList([1]), quarantine: null)),
          createFile: (path) {
            final file = _MockFile();
            when(() => file.path).thenReturn(path);
            when(() => file.writeAsBytes(any(), flush: true))
                .thenThrow(FileSystemException('write', path, OSError('injected', errno)));
            when(file.exists).thenAnswer((_) async => false);
            return file;
          },
        );
        expect(outcome, RestoreResult(write: result, quarantineKept: false), reason: 'errno $errno');
      }
      expect(recordFile.existsSync(), isFalse);
    });

    test('a quarantine write that fails part way leaves no partial record-quarantine.json', () async {
      Directory('${base.path}/record').createSync(recursive: true);
      // Files made outside the override, so the stand-ins can reach the disk without calling the override again.
      final real = {
        for (final file in [recordFile, tmpFile, quarantineFile, quarantineTmpFile]) file.path: file,
      };
      final outcome = await IOOverrides.runZoned(
        () => repo.restore(StoredBytes(record: Uint8List.fromList([1]), quarantine: Uint8List.fromList([2, 2, 2]))),
        createFile: (path) {
          final file = real[path]!;
          if (!path.contains('record-quarantine.json')) return file;
          // The device fills up after the first byte of the set-aside record.
          final partial = _MockFile();
          when(() => partial.path).thenReturn(path);
          when(() => partial.writeAsBytes(any(), flush: true)).thenAnswer((_) async {
            file.writeAsBytesSync([2]);
            throw FileSystemException('write', path, const OSError('No space left on device', 28));
          });
          when(partial.exists).thenAnswer((_) => file.exists());
          when(() => partial.rename(any())).thenAnswer((call) => file.rename(call.positionalArguments.first as String));
          return partial;
        },
      );
      expect(outcome, const RestoreResult(write: WriteResult.quota, quarantineKept: false));
      expect(recordFile.readAsBytesSync(), [1]);
      expect(quarantineFile.existsSync(), isFalse);
    });
  });

  test('the record values compare by value', () {
    expect(
      StoredBytes(record: Uint8List.fromList([1]), quarantine: null),
      StoredBytes(record: Uint8List.fromList([1]), quarantine: null),
    );
    expect(const RecordLoadEmpty(quarantineKept: true), isNot(const RecordLoadEmpty(quarantineKept: false)));
    expect(
      const RecordLoadQuarantined(reason: QuarantineReason.newer, quarantineKept: true),
      isNot(const RecordLoadQuarantined(reason: QuarantineReason.malformed, quarantineKept: true)),
    );
  });
}
