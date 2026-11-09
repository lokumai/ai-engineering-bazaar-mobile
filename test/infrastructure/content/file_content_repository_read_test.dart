import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/content_fixture.dart';
import '../../support/content_refresh_cases.dart';
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

  group('a page open during a refresh keeps its files (spec 3.4.3 row 6)', () {
    const oldDark = 'api/v1/diagrams/9bb8502b0371cba0d2e5b7e98362455e.svg';
    const newDark = 'api/v1/diagrams/0123456789abcdef0123456789abcdef.svg';
    final redrawn = utf8.encode('<svg xmlns="http://www.w3.org/2000/svg" id="redrawn"/>');

    /// [site] with its index replaced by [index] with [changes] applied and [files] in place of its `files`.
    void publish(Map<String, List<int>> site, Map<String, Object?> changes, Map<String, Object?> files) {
      final index = jsonDecode(utf8.decode(site['api/v1/index.json']!)) as Map<String, Object?>;
      site['api/v1/index.json'] = utf8.encode(jsonEncode({...index, ...changes, 'files': files}));
    }

    Map<String, Object?> filesOf(Map<String, List<int>> site) =>
        (jsonDecode(utf8.decode(site['api/v1/index.json']!)) as Map<String, Object?>)['files']! as Map<String, Object?>;

    String darkOf(ModuleDoc doc) => doc.body!.whereType<DiagramBlock>().single.svgDark;

    /// The published site with `alpha/first`'s dark diagram redrawn: [oldDark] leaves `files`, [newDark] names the
    /// redrawn bytes, and the refreshed document points at [newDark].
    Map<String, List<int>> redrawnSite() {
      final site = publishedSite();
      final document = utf8.encode(utf8.decode(site[refreshedPath]!).replaceAll(oldDark, newDark));
      final files = {...filesOf(site)}..remove(oldDark);
      files[refreshedPath] = sha256.convert(document).toString();
      files[newDark] = sha256.convert(redrawn).toString();
      publish(site, const {}, files);
      return {...site, refreshedPath: document, newDark: redrawn};
    }

    test('the diagram path of the document on screen still reads after a refresh redraws it', () async {
      final repository = fixtureRepository(cacheRoot, site: serving(redrawnSite()));
      await repository.open();
      final shown = await repository.readModuleDoc(refreshedPath);
      expect(darkOf(shown), oldDark);

      expect(await repository.refresh(), isA<ContentUpdated>());

      expect(await repository.readObject(oldDark), fixtureObject(oldDark));
      final refreshed = await repository.readModuleDoc(refreshedPath);
      expect(darkOf(refreshed), newDark);
      expect(await repository.readObject(newDark), redrawn);
    });

    test('an object an earlier refresh downloaded still reads after a later refresh drops its path', () async {
      final site = redrawnSite();
      final repository = fixtureRepository(cacheRoot, site: serving(site));
      await repository.open();
      expect(await repository.refresh(), isA<ContentUpdated>());
      final files = {...filesOf(site)}..remove(newDark);
      publish(site, {'contentVersion': '3' * 64, 'publishedAt': '2026-03-01T00:00:00.000Z'}, files);
      expect(await repository.refresh(), isA<ContentUpdated>());

      expect(await repository.readObject(newDark), redrawn);
      expect(await repository.readObject(oldDark), fixtureObject(oldDark));
      await expectLater(
        repository.readObject('api/v1/none.json'),
        throwsA(const ContentMissingException('api/v1/none.json')),
      );
    });

    test('the current index wins over an earlier one for a path both list', () async {
      final site = redrawnSite();
      final repository = fixtureRepository(cacheRoot, site: serving(site));
      await repository.open();
      expect(await repository.refresh(), isA<ContentUpdated>());

      expect(
        ContentParser.parseIndex(utf8.decode(site['api/v1/index.json']!)).sha256Of(refreshedPath),
        isNot(fixtureIndex().sha256Of(refreshedPath)),
      );
      expect(await repository.readObject(refreshedPath), site[refreshedPath]);
    });

    test('a downloaded object read through an earlier index keeps the sha256 check and the corrupt marker', () async {
      final site = redrawnSite();
      final repository = fixtureRepository(cacheRoot, site: serving(site));
      await repository.open();
      expect(await repository.refresh(), isA<ContentUpdated>());
      final files = {...filesOf(site)}..remove(newDark);
      publish(site, {'contentVersion': '3' * 64, 'publishedAt': '2026-03-01T00:00:00.000Z'}, files);
      expect(await repository.refresh(), isA<ContentUpdated>());
      File('$content/objects/${sha256.convert(redrawn)}').writeAsBytesSync([1, 2, 3]);

      await expectLater(repository.readObject(newDark), throwsA(const ContentCorruptException(newDark)));
      expect(File('$content/corrupt').existsSync(), isTrue);
    });
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
