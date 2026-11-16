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
}
