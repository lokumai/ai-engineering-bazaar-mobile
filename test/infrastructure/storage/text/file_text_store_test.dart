import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/storage/text/file_text_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('file_text_store_test_'));
  tearDown(() => root.deleteSync(recursive: true));

  FileTextStore store() => FileTextStore(baseDirectory: () async => root, path: 'quiz/scores.json');

  test('reads null before any write, then what was written, and null after a delete', () async {
    expect(await store().read(), isNull);

    await store().write('one');
    await store().write('two');
    expect(await store().read(), 'two');
    expect(File('${root.path}/quiz/scores.json.tmp').existsSync(), isFalse, reason: 'renamed over the file');

    await store().delete();
    expect(await store().read(), isNull);
    await store().delete();
  });

  // Review 7, finding 9: a direct write over the file passed every test. A write that cannot finish its temporary
  // copy must leave the text kept before it whole.
  test('a write that fails before its rename leaves the text kept before', () async {
    await store().write('kept');
    Directory('${root.path}/quiz/scores.json.tmp').createSync();

    await store().write('lost');
    expect(await store().read(), 'kept');
  });

  // Quick choices in the wardrobe wrote at once through the one `.tmp` file, and the outfit kept could be any of them.
  test('writes made at once land in the order made, the last one kept', () async {
    final one = store();
    final other = store();
    final writes = [
      for (var i = 0; i < 30; i++) (i.isEven ? one : other).write(List.filled(1 + (29 - i) * 400, '$i').join(',')),
    ];
    await Future.wait(writes);
    expect(await store().read(), List.filled(1, '29').join(','));
    expect(File('${root.path}/quiz/scores.json.tmp').existsSync(), isFalse);

    final last = [one.write('kept'), other.delete()];
    await Future.wait(last);
    expect(await store().read(), isNull, reason: 'the delete came after the write');
  });

  test('a write whose folder cannot be found fails alone: the next write to the file still runs', () async {
    var calls = 0;
    final flaky = FileTextStore(
      baseDirectory: () async => ++calls == 1 ? throw StateError('no folder yet') : root,
      path: 'quiz/scores.json',
    );
    final failed = flaky.write('lost');
    final next = flaky.write('kept');
    await expectLater(failed, throwsStateError);
    await next;
    expect(await store().read(), 'kept');
  });

  test('a file that is not UTF-8 text reads as null, not an error', () async {
    Directory('${root.path}/quiz').createSync();
    File('${root.path}/quiz/scores.json').writeAsBytesSync([0xff, 0xfe, 0xc3, 0x28]);

    expect(await store().read(), isNull);
  });

  test('a file that cannot be written or read is logged, not thrown', () async {
    File('${root.path}/quiz').writeAsStringSync('a file where the folder goes');

    await store().write('lost');
    expect(await store().read(), isNull);
    await store().delete();
  });

  // Plan 20.5: path_provider throws its own errors, not a FileSystemException, when the phone gives no folder.
  test('a base directory that fails with another error reads as null', () async {
    final none = FileTextStore(baseDirectory: () async => throw StateError('no folder'), path: 'quiz/scores.json');

    expect(await none.read(), isNull);
  });

  // Review 5, finding 2: a file there that could not be read started its feature fresh, and the next save replaced
  // what the reader had kept (the Apprentice's tokens and level).
  group('a file that could not be read is not written over', () {
    File kept() => File('${root.path}/quiz/scores.json')
      ..parent.createSync()
      ..writeAsStringSync('kept');

    test('until a read succeeds', () async {
      final file = kept();
      final scores = store();
      await Process.run('chmod', ['000', file.path]);
      addTearDown(() => Process.runSync('chmod', ['644', file.path]));

      expect(await scores.read(), isNull);
      await scores.write('fresh');
      await Process.run('chmod', ['644', file.path]);
      expect(file.readAsStringSync(), 'kept');

      expect(await scores.read(), 'kept');
      await scores.write('next');
      expect(file.readAsStringSync(), 'next');
    });

    test('until it is deleted, as an erase asks', () async {
      kept();
      var calls = 0;
      final scores = FileTextStore(
        baseDirectory: () async => ++calls == 1 ? throw StateError('no folder yet') : root,
        path: 'quiz/scores.json',
      );
      expect(await scores.read(), isNull);
      await scores.write('fresh');
      expect(await store().read(), 'kept');

      await scores.delete();
      await scores.write('after the erase');
      expect(await store().read(), 'after the erase');
    });

    test('but bytes that are not text are, as no read would ever succeed', () async {
      Directory('${root.path}/quiz').createSync();
      File('${root.path}/quiz/scores.json').writeAsBytesSync([0xff, 0xfe, 0xc3, 0x28]);
      final scores = store();

      expect(await scores.read(), isNull);
      await scores.write('fresh');
      expect(await store().read(), 'fresh');
    });
  });
}
