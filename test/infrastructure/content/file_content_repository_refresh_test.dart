import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/content_refresh_cases.dart';
import 'content_cache.dart';

void main() {
  late Directory cacheRoot;
  late String content;
  late Map<String, List<int>> published;

  setUp(() {
    cacheRoot = Directory.systemTemp.createTempSync('content_cache');
    content = '${cacheRoot.path}/content';
    published = publishedSite();
  });

  tearDown(() => cacheRoot.deleteSync(recursive: true));

  BundleIndex publishedIndex() => ContentParser.parseIndex(utf8.decode(published['api/v1/index.json']!));

  Future<FileContentRepository> opened(MockClientHandler site) async {
    final repository = fixtureRepository(cacheRoot, site: site);
    await repository.open();
    return repository;
  }

  /// The fixture index with [changes] applied, served as `api/v1/index.json`.
  void publishIndex(Map<String, Object?> changes) {
    final index = jsonDecode(utf8.decode(published['api/v1/index.json']!)) as Map<String, Object?>;
    published['api/v1/index.json'] = utf8.encode(jsonEncode({...index, ...changes}));
  }

  Future<String> moduleTitle(FileContentRepository repository) async =>
      (await repository.readModuleDoc(refreshedPath)).title;

  test('adopts a later bundle', () async {
    final requested = <Uri>[];
    final repository = await opened(serving(published, requested: requested));

    expect(await repository.refresh(), ContentUpdated(index: publishedIndex()));

    expect(File('$content/current').readAsStringSync(), publishedContentVersion);
    expect(File('$content/indexes/$publishedContentVersion.json').readAsBytesSync(), published['api/v1/index.json']);
    expect(requested, [
      Uri.parse('https://content.test/api/index.json'),
      Uri.parse('https://content.test/api/v1/index.json'),
      Uri.parse('https://content.test/$refreshedPath?v=${refreshedSha(published)}'),
    ]);
    expect(await moduleTitle(repository), 'Refreshed Module');
    expect(Directory(content).listSync(recursive: true).where((entry) => entry.path.endsWith('.tmp')), isEmpty);
    expect((await fixtureRepository(cacheRoot).open()).origin, ContentOrigin.downloaded);
  });

  test('majors without 1 is NeedsAppUpdate and fetches nothing else', () async {
    published['api/index.json'] = utf8.encode('{"majors":[2]}');
    final requested = <Uri>[];
    final repository = await opened(serving(published, requested: requested));

    expect(await repository.refresh(), const ContentNeedsAppUpdate());
    expect(requested, hasLength(1));
    expect(File('$content/current').existsSync(), isFalse);
  });

  group('up to date', () {
    final cases = {
      'the same contentVersion is UpToDate': {'contentVersion': '1' * 64},
      'the same publishedAt is UpToDate': {'publishedAt': '2026-01-02T03:04:05.000Z'},
      'an earlier publishedAt is UpToDate': {'publishedAt': '2025-12-31T00:00:00.000Z'},
    };
    for (final MapEntry(key: name, value: changes) in cases.entries) {
      test(name, () async {
        publishIndex(changes);
        final requested = <Uri>[];
        final repository = await opened(serving(published, requested: requested));

        expect(await repository.refresh(), const ContentUpToDate());
        expect(requested, hasLength(2));
        expect(File('$content/current').existsSync(), isFalse);
        expect(await moduleTitle(repository), 'First Module');
      });
    }
  });

  for (final failure in refreshFailureCases) {
    test('${failure.step} is ${failure.code.name}; the current content stays', () async {
      final repository = await opened(failure.handler(published));
      failure.arrange?.call(cacheRoot);

      expect(await repository.refresh(), ContentRefreshFailed(code: failure.code));

      if (failure.step == currentPointerStep) {
        expect(File('$content/indexes/$publishedContentVersion.json').existsSync(), isTrue);
      }
      expect(File('$content/current').existsSync(), isFalse);
      expect(await moduleTitle(repository), 'First Module');
      expect((await fixtureRepository(cacheRoot).open()).origin, ContentOrigin.bundled);
    });
  }

  test('Review Focus 2 over a downloaded current', () async {
    final site = Map.of(published);
    final repository = await opened(serving(site));
    expect(await repository.refresh(), ContentUpdated(index: publishedIndex()));

    site['api/v1/index.json'] = utf8.encode('<!doctype html><title>Sign in</title>');
    expect(await repository.refresh(), const ContentRefreshFailed(code: ContentErrorCode.format));

    expect(File('$content/current').readAsStringSync(), publishedContentVersion);
    expect(await moduleTitle(repository), 'Refreshed Module');
  });

  test('an object the cache already holds is not fetched again', () async {
    final site = Map.of(published);
    final requested = <Uri>[];
    final repository = await opened(serving(site, requested: requested));
    expect(await repository.refresh(), ContentUpdated(index: publishedIndex()));

    final index = jsonDecode(utf8.decode(site['api/v1/index.json']!)) as Map<String, Object?>;
    site['api/v1/index.json'] = utf8.encode(
      jsonEncode({...index, 'contentVersion': '3' * 64, 'publishedAt': '2026-03-01T00:00:00.000Z'}),
    );
    requested.clear();

    expect(await repository.refresh(), isA<ContentUpdated>());
    expect(requested.map((url) => url.path), ['/api/index.json', '/api/v1/index.json']);
    expect(File('$content/current').readAsStringSync(), '3' * 64);
  });

  test('object: bytes that do not match is checksum, without the corrupt marker (A25)', () async {
    final repository = await opened(answering(published, refreshedPath, () async => http.Response('stale', 200)));

    expect(await repository.refresh(), const ContentRefreshFailed(code: ContentErrorCode.checksum));
    expect(File('$content/corrupt').existsSync(), isFalse);
    expect(File('$content/objects/${refreshedSha(published)}').existsSync(), isFalse);
  });

  test('storage: the index cannot be written, and nothing is downloaded before it', () async {
    final requested = <Uri>[];
    final repository = await opened(serving(published, requested: requested));
    Directory(content).createSync(recursive: true);
    File('$content/indexes').writeAsStringSync('');

    expect(await repository.refresh(), const ContentRefreshFailed(code: ContentErrorCode.storage));
    expect(requested.map((url) => url.path), ['/api/index.json', '/api/v1/index.json']);
    expect(File('$content/objects/${refreshedSha(published)}').existsSync(), isFalse);
    expect(File('$content/current').existsSync(), isFalse);
  });

  group('a refresh cut off goes on where it stopped (review B4)', () {
    test('what it downloaded outlives a restart, and the next refresh fetches none of it again', () async {
      final first = await opened(serving(published));
      Directory('$content/current.tmp/x').createSync(recursive: true); // the last step fails, as a killed app would
      expect(await first.refresh(), const ContentRefreshFailed(code: ContentErrorCode.storage));
      expect(File('$content/pending').readAsStringSync(), publishedContentVersion);

      final requested = <Uri>[];
      final restarted = fixtureRepository(cacheRoot, site: serving(published, requested: requested));
      expect((await restarted.open()).origin, ContentOrigin.bundled, reason: 'the old content until the new is whole');
      expect(File('$content/objects/${refreshedSha(published)}').existsSync(), isTrue);
      expect(Directory('$content/current.tmp').existsSync(), isFalse, reason: 'the rest of the cache is cleared');

      expect(await restarted.refresh(), ContentUpdated(index: publishedIndex()));
      expect(requested.map((url) => url.path), ['/api/index.json', '/api/v1/index.json']);
      expect(File('$content/pending').existsSync(), isFalse);
      expect(await moduleTitle(restarted), 'Refreshed Module');
    });

    test('a pending refresh is kept beside a downloaded current, and dropped once it is no later', () async {
      final repository = await opened(serving(published));
      expect(await repository.refresh(), ContentUpdated(index: publishedIndex()));

      // A later refresh that stopped after one object of its own.
      final extra = utf8.encode('{"extra": true}');
      final extraSha = sha256.convert(extra).toString();
      void pendAt(String publishedAt) {
        final index = jsonDecode(utf8.decode(published['api/v1/index.json']!)) as Map<String, Object?>;
        final files = {...index['files']! as Map<String, Object?>, 'api/v1/extra.json': extraSha};
        File('$content/indexes/${'3' * 64}.json').writeAsStringSync(
          jsonEncode({...index, 'contentVersion': '3' * 64, 'publishedAt': publishedAt, 'files': files}),
        );
        File('$content/pending').writeAsStringSync('3' * 64);
        File('$content/objects/$extraSha').writeAsBytesSync(extra);
      }

      pendAt('2026-03-01T00:00:00.000Z');
      expect((await fixtureRepository(cacheRoot).open()).origin, ContentOrigin.downloaded);
      expect(File('$content/objects/$extraSha').existsSync(), isTrue);
      expect(File('$content/objects/${refreshedSha(published)}').existsSync(), isTrue);
      expect(File('$content/pending').existsSync(), isTrue);

      pendAt('2026-01-15T00:00:00.000Z'); // earlier than the current content
      expect((await fixtureRepository(cacheRoot).open()).origin, ContentOrigin.downloaded);
      expect(File('$content/objects/$extraSha').existsSync(), isFalse);
      expect(File('$content/pending').existsSync(), isFalse);
      expect(File('$content/indexes/${'3' * 64}.json').existsSync(), isFalse);
    });

    test('an unreadable pending pointer leaves the start as before', () async {
      final first = await opened(serving(published));
      Directory('$content/current.tmp/x').createSync(recursive: true);
      expect(await first.refresh(), const ContentRefreshFailed(code: ContentErrorCode.storage));
      File('$content/pending').writeAsStringSync('not a content version');

      expect((await fixtureRepository(cacheRoot).open()).origin, ContentOrigin.bundled);
      expect(Directory(content).existsSync(), isFalse);
    });
  });

  test('refresh before open() throws StateError', () {
    expect(fixtureRepository(cacheRoot).refresh(), throwsStateError);
  });
}
