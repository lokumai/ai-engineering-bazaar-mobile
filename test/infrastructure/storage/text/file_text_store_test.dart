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
