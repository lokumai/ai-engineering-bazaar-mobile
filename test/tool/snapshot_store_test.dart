import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../tool/src/snapshot_store.dart';

final cv = 'a' * 64;

String _sha(String text) => sha256.convert(utf8.encode(text)).toString();

/// A synthetic site: two indexes, the conformance file and three object paths naming two distinct sha256 values plus
/// the logo shared by two image paths. Each object answers only when the query is `v=<its sha256>`.
final class _Site {
  _Site({this.majors = '{"majors":[1]}', String? index, this.served = const {}, this.conformanceStatus = 200}) {
    indexBytes = utf8.encode(index ?? _defaultIndex);
    client = MockClient((request) async {
      requested.add(request.url);
      final path = request.url.path.substring(1);
      if (path == 'api/index.json') return http.Response.bytes(utf8.encode(majors), 200);
      if (path == 'api/v1/index.json') return http.Response.bytes(indexBytes, 200);
      if (path == 'api/v1/record-conformance.json') {
        return http.Response.bytes(utf8.encode('{"version":1}'), conformanceStatus);
      }
      final body = objects[path];
      if (body == null || request.url.query != 'v=${_sha(body)}') return http.Response('missing', 404);
      return http.Response.bytes(utf8.encode(served[path] ?? body), 200);
    });
  }

  static const objects = {
    'api/v1/tokens.json': '{"t":1}',
    'api/v1/levels/alpha.json': '{"l":1}',
    'course-images/alpha/logos/x.svg': '<svg/>',
    'course-images/beta/logos/x.svg': '<svg/>',
  };

  static final _defaultIndex = jsonEncode({
    'schemaVersion': 1,
    'contentVersion': 'a' * 64,
    'files': {'api/v1/tokens.json': _sha('{"t":1}'), 'api/v1/levels/alpha.json': _sha('{"l":1}')},
    'images': {'course-images/alpha/logos/x.svg': _sha('<svg/>'), 'course-images/beta/logos/x.svg': _sha('<svg/>')},
  });

  final String majors;
  final Map<String, String> served;
  final int conformanceStatus;
  late final List<int> indexBytes;
  late final MockClient client;
  final requested = <Uri>[];

  List<String> get distinctShas => [_sha('{"t":1}'), _sha('{"l":1}'), _sha('<svg/>')];
  int get objectBytes => ['{"t":1}', '{"l":1}', '<svg/>'].fold(0, (sum, text) => sum + utf8.encode(text).length);
}

List<String> objectNames(Directory root) {
  final dir = Directory('${root.path}/assets/content/objects');
  if (!dir.existsSync()) return const [];
  return [for (final file in dir.listSync().whereType<File>()) file.uri.pathSegments.last];
}

void main() {
  late Directory root;
  late _Site site;

  setUp(() {
    root = Directory.systemTemp.createTempSync('snapshot_store_test');
    addTearDown(() => root.deleteSync(recursive: true));
    site = _Site();
  });

  void seed(String relative, String text) {
    File('${root.path}/$relative')
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  Future<SnapshotReport> run(_Site site, {String? contentVersion}) => refreshContentSnapshot(
    client: site.client,
    baseUrl: 'https://example.org/',
    contentVersion: contentVersion ?? cv,
    root: root.path,
  );

  test('snapshotUri concatenates the base, the path and ?v=', () {
    expect(
      snapshotUri('https://ai-bazaar.lokum.dev/', 'api/v1/tokens.json', sha256: 'ab'),
      Uri.parse('https://ai-bazaar.lokum.dev/api/v1/tokens.json?v=ab'),
    );
    expect(
      snapshotUri('https://example.org/bazaar/', 'api/index.json'),
      Uri.parse('https://example.org/bazaar/api/index.json'),
    );
  });

  test('a base URL without a trailing slash is refused before any request', () async {
    await expectLater(
      refreshContentSnapshot(
        client: site.client,
        baseUrl: 'https://example.org/bazaar',
        contentVersion: cv,
        root: root.path,
      ),
      throwsA(isA<SnapshotException>().having((e) => e.message, 'message', contains('must end with /'))),
    );
    expect(site.requested, isEmpty);
  });

  test('writes both indexes as fetched, one object per distinct sha256 and the conformance fixture', () async {
    final report = await run(site);
    expect(File('${root.path}/assets/content/index.json').readAsBytesSync(), site.indexBytes);
    expect(File('${root.path}/assets/content/api_index.json').readAsStringSync(), '{"majors":[1]}');
    expect(objectNames(root), unorderedEquals(site.distinctShas));
    for (final sha in site.distinctShas) {
      expect(sha256.convert(File('${root.path}/assets/content/objects/$sha').readAsBytesSync()).toString(), sha);
    }
    expect(File('${root.path}/test/fixtures/record_conformance/v1.json').readAsStringSync(), '{"version":1}');
    expect(site.requested.where((u) => u.query.startsWith('v=')), hasLength(3));
    expect((report.objects, report.fetched, report.removed), (3, 3, 0));
    expect(report.bytes, site.indexBytes.length + 14 + site.objectBytes);
  });

  test('removes every file in objects/ the index does not name, a leftover .tmp included', () async {
    seed('assets/content/objects/${'b' * 64}', 'stale');
    seed('assets/content/objects/${'d' * 64}.tmp', 'half');
    final report = await run(site);
    expect(report.removed, 2);
    expect(objectNames(root), unorderedEquals(site.distinctShas));
  });

  test('keeps an object already on disk whose bytes match its name and does not fetch it', () async {
    seed('assets/content/objects/${_sha('{"t":1}')}', '{"t":1}');
    final report = await run(site);
    expect(report.fetched, 2);
    expect(site.requested.map((u) => u.path), isNot(contains('/api/v1/tokens.json')));
    expect(objectNames(root), unorderedEquals(site.distinctShas));
  });

  test('fetches again an object on disk whose bytes do not match its name', () async {
    seed('assets/content/objects/${_sha('{"t":1}')}', 'corrupt');
    final report = await run(site);
    expect(report.fetched, 3);
    expect(File('${root.path}/assets/content/objects/${_sha('{"t":1}')}').readAsStringSync(), '{"t":1}');
  });

  test('fails when majors does not contain 1, and writes nothing', () async {
    await expectLater(
      run(_Site(majors: '{"majors":[2]}')),
      throwsA(isA<SnapshotException>().having((e) => e.message, 'message', contains('majors'))),
    );
    expect(File('${root.path}/assets/content/index.json').existsSync(), isFalse);
    expect(Directory('${root.path}/assets').existsSync(), isFalse);
  });

  test('fails when the site serves another contentVersion', () async {
    final other = 'b' * 64;
    await expectLater(
      run(site, contentVersion: other),
      throwsA(isA<SnapshotException>().having((e) => e.message, 'message', allOf(contains(cv), contains(other)))),
    );
    expect(File('${root.path}/assets/content/index.json').existsSync(), isFalse);
  });

  test('fails on a sha256 mismatch, naming the path, and leaves the snapshot as it was', () async {
    seed('assets/content/index.json', 'old');
    seed('assets/content/objects/${'c' * 64}', 'unnamed');
    await expectLater(
      run(_Site(served: {'api/v1/tokens.json': '{"t":2}'})),
      throwsA(
        isA<SnapshotException>().having(
          (e) => e.message,
          'message',
          allOf(contains('api/v1/tokens.json'), contains(_sha('{"t":1}')), contains(_sha('{"t":2}'))),
        ),
      ),
    );
    expect(File('${root.path}/assets/content/index.json').readAsStringSync(), 'old');
    expect(File('${root.path}/assets/content/objects/${'c' * 64}').readAsStringSync(), 'unnamed');
  });

  test('fails on a status other than 200, naming the URL and the status', () async {
    await expectLater(
      run(_Site(conformanceStatus: 404)),
      throwsA(
        isA<SnapshotException>().having(
          (e) => e.message,
          'message',
          allOf(contains('https://example.org/api/v1/record-conformance.json'), contains('404')),
        ),
      ),
    );
    expect(File('${root.path}/assets/content/index.json').existsSync(), isFalse);
  });

  test('fails when the index is not JSON, as a captive portal answers', () async {
    await expectLater(
      run(_Site(index: '<html>')),
      throwsA(isA<SnapshotException>().having((e) => e.message, 'message', contains('api/v1/index.json'))),
    );
    expect(File('${root.path}/assets/content/index.json').existsSync(), isFalse);
  });

  test('fails when an index entry is not a site path with a sha256', () async {
    final bad = jsonEncode({
      'contentVersion': cv,
      'files': {'/api/v1/tokens.json': _sha('{"t":1}')},
      'images': <String, String>{},
    });
    await expectLater(
      run(_Site(index: bad)),
      throwsA(isA<SnapshotException>().having((e) => e.message, 'message', contains('/api/v1/tokens.json'))),
    );
    final upper = jsonEncode({
      'contentVersion': cv,
      'files': {'api/v1/tokens.json': _sha('{"t":1}').toUpperCase()},
      'images': <String, String>{},
    });
    await expectLater(run(_Site(index: upper)), throwsA(isA<SnapshotException>()));
  });

  test('parseSnapshotArgs takes both flags in either order and refuses anything else', () {
    expect(parseSnapshotArgs(['--base-url', 'https://x.dev/', '--content-version', cv]), (
      baseUrl: 'https://x.dev/',
      contentVersion: cv,
    ));
    expect(parseSnapshotArgs(['--content-version', cv, '--base-url', 'https://x.dev/']), (
      baseUrl: 'https://x.dev/',
      contentVersion: cv,
    ));
    expect(() => parseSnapshotArgs(['--base-url', 'https://x.dev/']), throwsA(isA<SnapshotException>()));
    expect(
      () => parseSnapshotArgs(['--base-url', 'https://x.dev/', '--content-version', 'abc']),
      throwsA(isA<SnapshotException>()),
    );
    expect(
      () => parseSnapshotArgs(['--base-url', 'https://x.dev/', '--content-version', cv, '--extra']),
      throwsA(isA<SnapshotException>()),
    );
  });
}
