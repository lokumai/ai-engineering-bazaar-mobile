import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/storage/flags/file_flag_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('flag_store_test_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('a flag is unset until it is set, then stays set for a new store over the same directory', () async {
    final store = FileFlagStore(baseDirectory: () async => root);

    expect(await store.isSet('welcome-seen'), isFalse);
    await store.set('welcome-seen');
    expect(await store.isSet('welcome-seen'), isTrue);
    expect(await FileFlagStore(baseDirectory: () async => root).isSet('welcome-seen'), isTrue);
    expect(await store.isSet('other'), isFalse, reason: 'each flag is its own file');
  });

  test('the flags live under flags/, apart from the record', () async {
    await FileFlagStore(baseDirectory: () async => root).set('welcome-seen');

    expect(File('${root.path}/flags/welcome-seen').existsSync(), isTrue);
    expect(Directory('${root.path}/record').existsSync(), isFalse);
  });

  test('a flag that cannot be written stays unset and throws nothing', () async {
    // A file where the flags directory should be makes every write fail.
    File('${root.path}/flags').writeAsStringSync('');
    final store = FileFlagStore(baseDirectory: () async => root);

    await store.set('welcome-seen');

    expect(await store.isSet('welcome-seen'), isFalse);
  });

  test('a base directory that cannot be resolved reads as unset and is asked again next time', () async {
    var calls = 0;
    final store = FileFlagStore(
      baseDirectory: () async {
        calls++;
        if (calls == 1) throw const FileSystemException('unavailable');
        return root;
      },
    );

    expect(await store.isSet('welcome-seen'), isFalse);
    await store.set('welcome-seen');
    expect(await store.isSet('welcome-seen'), isTrue);
  });
}
