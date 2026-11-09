import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/content_fixture.dart';
import 'content_cache.dart';

void main() {
  late Directory cacheRoot;
  late String content;

  setUp(() {
    cacheRoot = Directory.systemTemp.createTempSync('content_cache');
    content = '${cacheRoot.path}/content';
  });

  tearDown(() => cacheRoot.deleteSync(recursive: true));

  final bundledOpening = ContentOpening(index: fixtureIndex(), origin: ContentOrigin.bundled, notice: null);

  test('row 1: a bundled index that fails the parser throws ContentFormatException', () async {
    final repository = fixtureRepository(cacheRoot, overrides: {BundledContent.indexKey: '<html></html>'});

    await expectLater(repository.open(), throwsA(isA<ContentFormatException>()));
  });

  test('no cache: the bundled snapshot opens', () async {
    expect(await fixtureRepository(cacheRoot).open(), bundledOpening);
  });

  test('row 2: a corrupt marker deletes the cache and opens bundled', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);
    File('$content/corrupt').writeAsStringSync('');

    expect(await fixtureRepository(cacheRoot).open(), bundledOpening);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 3: current names a missing index: cache deleted, notice set', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);
    File('$content/current').writeAsStringSync('3333333333333333333333333333333333333333333333333333333333333333');

    final opening = await fixtureRepository(cacheRoot).open();

    expect(
      opening,
      ContentOpening(index: fixtureIndex(), origin: ContentOrigin.bundled, notice: ContentNotice.cacheDiscarded),
    );
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 3: current names an index that fails the parser: cache deleted, notice set', () async {
    const version = '2222222222222222222222222222222222222222222222222222222222222222';
    writeCache(cacheRoot, publishedAt: laterPublishedAt, contentVersion: version);
    File('$content/indexes/$version.json').writeAsStringSync('<html></html>');

    final opening = await fixtureRepository(cacheRoot).open();

    expect(opening.notice, ContentNotice.cacheDiscarded);
    expect(opening.origin, ContentOrigin.bundled);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 3: current that is not a content version is unreadable: cache deleted, notice set', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);
    File('$content/current').writeAsStringSync('../outside');

    final opening = await fixtureRepository(cacheRoot).open();

    expect(opening.notice, ContentNotice.cacheDiscarded);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 4: a cache published at the same instant loses and is deleted', () async {
    writeCache(cacheRoot, publishedAt: fixtureIndex().publishedAt);

    expect(await fixtureRepository(cacheRoot).open(), bundledOpening);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 4: a cache published earlier loses and is deleted', () async {
    writeCache(cacheRoot, publishedAt: '2025-12-31T23:59:59.999Z');

    expect(await fixtureRepository(cacheRoot).open(), bundledOpening);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 5: a later cache with a missing object is deleted and bundled opens', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt, withObjects: false);

    expect(await fixtureRepository(cacheRoot).open(), bundledOpening);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('row 5: objects the bundle holds need no copy in the cache', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);

    final opening = await fixtureRepository(cacheRoot).open();

    expect(opening.origin, ContentOrigin.downloaded);
    expect(Directory('$content/objects').listSync().map((entry) => entry.uri.pathSegments.last), [cacheOnlySha()]);
  });

  test('row 6: a later complete cache wins and is garbage collected', () async {
    const version = '2222222222222222222222222222222222222222222222222222222222222222';
    const otherVersion = '3333333333333333333333333333333333333333333333333333333333333333';
    const unreferenced = '4444444444444444444444444444444444444444444444444444444444444444';
    writeCache(
      cacheRoot,
      publishedAt: laterPublishedAt,
      contentVersion: version,
      extraObjects: {
        unreferenced: [1, 2, 3],
        '${cacheOnlySha()}.tmp': [4, 5, 6],
      },
    );
    File('$content/indexes/$otherVersion.json').writeAsStringSync('{}');

    final opening = await fixtureRepository(cacheRoot).open();

    expect(opening.origin, ContentOrigin.downloaded);
    expect(opening.notice, isNull);
    expect(opening.index.contentVersion, version);
    expect(opening.index.sha256Of(cacheOnlyPath), cacheOnlySha());
    expect(File('$content/indexes/$version.json').existsSync(), isTrue);
    expect(File('$content/indexes/$otherVersion.json').existsSync(), isFalse);
    expect(File('$content/objects/$unreferenced').existsSync(), isFalse);
    expect(File('$content/objects/${cacheOnlySha()}.tmp').existsSync(), isFalse);
    expect(File('$content/objects/${cacheOnlySha()}').existsSync(), isTrue);
    expect(File('$content/current').readAsStringSync(), version);
  });

  test('objects without a current pointer are deleted', () async {
    Directory('$content/objects').createSync(recursive: true);
    File('$content/objects/${cacheOnlySha()}').writeAsBytesSync(cacheOnlyObject());

    expect(await fixtureRepository(cacheRoot).open(), bundledOpening);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('cacheDirectory is called once, by open()', () async {
    var calls = 0;
    final repository = FileContentRepository(
      bundled: BundledContent(bundle: FixtureAssetBundle()),
      cacheDirectory: () async {
        calls++;
        return cacheRoot;
      },
      http: siteHttp(),
    );
    expect(calls, 0);

    await repository.open();
    expect(calls, 1);

    await repository.readObject('api/v1/levels/alpha.json');
    expect(calls, 1);
  });

  test('a read before open() throws StateError', () async {
    final repository = fixtureRepository(cacheRoot);

    await expectLater(repository.readObject('api/v1/levels/alpha.json'), throwsStateError);
    await expectLater(repository.readModuleDoc('api/v1/modules/alpha/first/en.json'), throwsStateError);
    await expectLater(repository.readLevelDoc('api/v1/levels/alpha.json'), throwsStateError);
    await expectLater(repository.refresh(), throwsStateError);
  });

  test('ContentOpening and the refresh outcomes compare by value', () {
    final index = fixtureIndex();

    expect(
      ContentOpening(index: index, origin: ContentOrigin.downloaded, notice: null),
      ContentOpening(index: fixtureIndex(), origin: ContentOrigin.downloaded, notice: null),
    );
    expect(
      ContentOpening(index: index, origin: ContentOrigin.downloaded, notice: null),
      isNot(ContentOpening(index: index, origin: ContentOrigin.bundled, notice: null)),
    );
    expect(const ContentUpToDate(), const ContentUpToDate());
    expect(const ContentNeedsAppUpdate(), const ContentNeedsAppUpdate());
    expect(ContentUpdated(index: index), ContentUpdated(index: fixtureIndex()));
    expect(
      const ContentRefreshFailed(code: ContentErrorCode.network),
      isNot(const ContentRefreshFailed(code: ContentErrorCode.checksum)),
    );
  });
}
