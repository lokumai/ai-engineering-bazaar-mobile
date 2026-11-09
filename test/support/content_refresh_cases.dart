/// The site a refresh reads in tests, and the steps at which a refresh fails (spec 3.4.4, 3.11), shared by the
/// repository's refresh test and the `ContentBloc` test so both run the same failures over the real repository.
library;

import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'content_fixture.dart';

/// The site path of the document the published bundle changes.
const refreshedPath = 'api/v1/modules/alpha/first/en.json';

/// The content version of the published bundle.
const publishedContentVersion = '2222222222222222222222222222222222222222222222222222222222222222';

/// What the site publishes, by site path: `api/index.json` with major 1, and `api/v1/index.json`, the fixture index
/// with `publishedAt` `2026-02-01T00:00:00.000Z`, [publishedContentVersion], and [refreshedPath] pointing at the
/// fixture document retitled `Refreshed Module`, whose bytes are served under that path too.
Map<String, List<int>> publishedSite() {
  final index = jsonDecode(File('$contentFixtureBundle/index.json').readAsStringSync()) as Map<String, Object?>;
  final files = index['files']! as Map<String, Object?>;
  final document = jsonDecode(File('$contentFixtureBundle/objects/${files[refreshedPath]}').readAsStringSync());
  final refreshed = utf8.encode(jsonEncode({...document as Map<String, Object?>, 'title': 'Refreshed Module'}));
  final published = {
    ...index,
    'contentVersion': publishedContentVersion,
    'publishedAt': '2026-02-01T00:00:00.000Z',
    'files': {...files, refreshedPath: sha256.convert(refreshed).toString()},
  };
  return {
    'api/index.json': utf8.encode('{"majors":[1]}'),
    'api/v1/index.json': utf8.encode(jsonEncode(published)),
    refreshedPath: refreshed,
  };
}

/// The sha256 [refreshedPath] has in the published index.
String refreshedSha(Map<String, List<int>> published) => sha256.convert(published[refreshedPath]!).toString();

/// A handler that serves [site] by site path and 404 for anything else, recording each requested URL in [requested].
MockClientHandler serving(Map<String, List<int>> site, {List<Uri>? requested}) => (request) async {
  requested?.add(request.url);
  final bytes = site[request.url.path.substring(1)];
  return bytes == null ? http.Response('', 404) : http.Response.bytes(bytes, 200);
};

/// [serving] with the answer for [sitePath] replaced by [answer].
MockClientHandler answering(Map<String, List<int>> site, String sitePath, Future<http.Response> Function() answer) {
  final served = serving(site);
  return (request) => request.url.path.substring(1) == sitePath ? answer() : served(request);
}

/// One failing step of a refresh: the handler serving the published site with that step broken, the code the refresh
/// fails with, and [arrange], which a test runs on the cache root after `open()` and before the refresh.
typedef RefreshFailureCase = ({
  String step,
  ContentErrorCode code,
  MockClientHandler Function(Map<String, List<int>> published) handler,
  void Function(Directory cacheRoot)? arrange,
});

/// The step of [refreshFailureCases] at which the new index is written but `current` cannot be replaced.
const currentPointerStep = 'storage: the current pointer cannot be replaced';

const _html = '<!doctype html><title>Sign in</title>';

final refreshFailureCases = <RefreshFailureCase>[
  (
    step: 'majors: network error',
    code: ContentErrorCode.network,
    handler: (published) => answering(published, 'api/index.json', () async => throw http.ClientException('offline')),
    arrange: null,
  ),
  (
    step: 'majors: TLS handshake fails',
    code: ContentErrorCode.network,
    handler: (published) =>
        answering(published, 'api/index.json', () async => throw const HandshakeException('CERTIFICATE_VERIFY_FAILED')),
    arrange: null,
  ),
  (
    step: 'majors: status 503',
    code: ContentErrorCode.httpStatus,
    handler: (published) => answering(published, 'api/index.json', () async => http.Response('', 503)),
    arrange: null,
  ),
  (
    step: 'majors: not JSON',
    code: ContentErrorCode.format,
    handler: (published) => answering(published, 'api/index.json', () async => http.Response(_html, 200)),
    arrange: null,
  ),
  (
    step: 'index: status 404',
    code: ContentErrorCode.httpStatus,
    handler: (published) => answering(published, 'api/v1/index.json', () async => http.Response('', 404)),
    arrange: null,
  ),
  (
    step: 'Review Focus 2: index answered 200 with HTML',
    code: ContentErrorCode.format,
    handler: (published) => answering(published, 'api/v1/index.json', () async => http.Response(_html, 200)),
    arrange: null,
  ),
  (
    step: 'index: bytes that are not UTF-8',
    code: ContentErrorCode.format,
    handler: (published) =>
        answering(published, 'api/v1/index.json', () async => http.Response.bytes([0xff, 0xfe, 0x3c], 200)),
    arrange: null,
  ),
  (
    step: 'object: network error',
    code: ContentErrorCode.network,
    handler: (published) => answering(published, refreshedPath, () async => throw http.ClientException('offline')),
    arrange: null,
  ),
  (
    step: 'object: status 404',
    code: ContentErrorCode.httpStatus,
    handler: (published) => answering(published, refreshedPath, () async => http.Response('', 404)),
    arrange: null,
  ),
  (
    step: 'object: bytes that do not match',
    code: ContentErrorCode.checksum,
    handler: (published) => answering(published, refreshedPath, () async => http.Response('stale', 200)),
    arrange: null,
  ),
  (
    step: 'storage: the index cannot be written',
    code: ContentErrorCode.storage,
    handler: serving,
    arrange: (cacheRoot) {
      Directory('${cacheRoot.path}/content').createSync(recursive: true);
      File('${cacheRoot.path}/content/indexes').writeAsStringSync('');
    },
  ),
  (
    step: 'storage: an object cannot be written',
    code: ContentErrorCode.storage,
    handler: serving,
    arrange: (cacheRoot) =>
        Directory('${cacheRoot.path}/content/objects/${refreshedSha(publishedSite())}.tmp/x')
            .createSync(recursive: true),
  ),
  (
    step: currentPointerStep,
    code: ContentErrorCode.storage,
    handler: serving,
    arrange: (cacheRoot) => Directory('${cacheRoot.path}/content/current.tmp/x').createSync(recursive: true),
  ),
];
