import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  test('readObject returns bundled bytes for a bundled path', () async {
    final repository = fixtureRepository(cacheRoot);
    await repository.open();

    expect(await repository.readObject('api/v1/levels/alpha.json'), fixtureObject('api/v1/levels/alpha.json'));
    expect(
      await repository.readObject('course-images/alpha/figure.png'),
      fixtureObject('course-images/alpha/figure.png'),
    );
  });

  test('readObject of a path the index does not list throws ContentMissingException', () async {
    final repository = fixtureRepository(cacheRoot);
    await repository.open();

    await expectLater(
      repository.readObject('api/v1/none.json'),
      throwsA(const ContentMissingException('api/v1/none.json')),
    );
  });

  test('readObject of a bundled object the asset bundle does not hold throws ContentMissingException', () async {
    final sha = fixtureIndex().sha256Of('api/v1/levels/alpha.json')!;
    final repository = FileContentRepository(
      bundled: BundledContent(bundle: _WithoutAsset('${BundledContent.objectsPrefix}$sha')),
      cacheDirectory: () async => cacheRoot,
      http: siteHttp(),
    );
    await repository.open();

    await expectLater(
      repository.readObject('api/v1/levels/alpha.json'),
      throwsA(const ContentMissingException('api/v1/levels/alpha.json')),
    );
  });

  test('readModuleDoc parses through the current index', () async {
    final repository = fixtureRepository(cacheRoot);
    await repository.open();

    final doc = await repository.readModuleDoc('api/v1/modules/alpha/first/en.json');

    expect(doc.key, 'alpha/first');
    expect(doc.track, Track.engineers);
  });

  test('readModuleDoc reads a cached document through the cache index', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);
    final repository = fixtureRepository(cacheRoot);
    await repository.open();

    final doc = await repository.readModuleDoc(cacheOnlyPath);

    expect(doc.key, 'alpha/first');
    expect(doc.lang, 'tr');
  });

  test('readLevelDoc parses the level document', () async {
    final repository = fixtureRepository(cacheRoot);
    await repository.open();

    expect((await repository.readLevelDoc('api/v1/levels/alpha.json')).slug, 'alpha');
  });

  test('a cached object whose bytes no longer match raises ContentCorruptException and writes the marker', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);
    final repository = fixtureRepository(cacheRoot);
    expect((await repository.open()).origin, ContentOrigin.downloaded);
    File('$content/objects/${cacheOnlySha()}').writeAsBytesSync([1, 2, 3]);

    await expectLater(repository.readObject(cacheOnlyPath), throwsA(const ContentCorruptException(cacheOnlyPath)));
    expect(File('$content/corrupt').existsSync(), isTrue);

    final next = await fixtureRepository(cacheRoot).open();
    expect(next.origin, ContentOrigin.bundled);
    expect(next.notice, isNull);
    expect(Directory(content).existsSync(), isFalse);
  });

  test('Review Focus 5: a cached object the OS deleted after startup', () async {
    writeCache(cacheRoot, publishedAt: laterPublishedAt);
    final repository = fixtureRepository(cacheRoot);
    expect((await repository.open()).origin, ContentOrigin.downloaded);
    File('$content/objects/${cacheOnlySha()}').deleteSync();

    await expectLater(repository.readObject(cacheOnlyPath), throwsA(const ContentMissingException(cacheOnlyPath)));
    expect(File('$content/corrupt').existsSync(), isFalse);

    final next = await fixtureRepository(cacheRoot).open();
    expect(next.origin, ContentOrigin.bundled);
  });

  test('FixtureAssetBundle serves the fixture bundle and its overrides, and nothing else', () async {
    final bundle = FixtureAssetBundle(overrides: {BundledContent.apiIndexKey: '{"majors":[2]}'});

    expect(
      await bundle.loadString(BundledContent.indexKey),
      File('$contentFixtureBundle/index.json').readAsStringSync(),
    );
    expect(await bundle.loadString(BundledContent.apiIndexKey), '{"majors":[2]}');
    await expectLater(bundle.load('assets/other.json'), throwsA(isA<FlutterError>()));
    await expectLater(bundle.load('assets/content/objects/none'), throwsA(isA<FlutterError>()));
  });
}

/// The fixture bundle without one asset, as an asset bundle that lost a file would answer.
final class _WithoutAsset extends CachingAssetBundle {
  _WithoutAsset(this.missingKey);

  final String missingKey;
  final _fixture = FixtureAssetBundle();

  @override
  Future<ByteData> load(String key) =>
      key == missingKey ? Future.error(FlutterError('Unable to load asset: "$key".')) : _fixture.load(key);
}
