import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Downloads the content bundle the app ships as its bundled snapshot (spec 3.4.6).
///
/// Pure Dart, no Flutter import, so `fvm dart run tool/refresh_content_snapshot.dart` runs it. Every refusal is a
/// [SnapshotException]; nothing is caught or retried. Objects land under their sha256 before either index is
/// replaced, so a failure leaves the snapshot the app reads as it was.

const usage =
    'usage: fvm dart run tool/refresh_content_snapshot.dart --base-url <https://site/> --content-version <64 hex>';

final _sitePath = RegExp(r'^[^/\s][^\s]*$');
final _sha256 = RegExp(r'^[0-9a-f]{64}$');

final class SnapshotException implements Exception {
  const SnapshotException(this.message);
  final String message;
  @override
  String toString() => 'SnapshotException: $message';
}

final class SnapshotReport {
  const SnapshotReport({required this.objects, required this.fetched, required this.removed, required this.bytes});

  /// Distinct sha256 values the index names.
  final int objects;

  /// Objects downloaded in this run.
  final int fetched;

  /// Files deleted from `assets/content/objects/`.
  final int removed;

  /// `index.json` + `api_index.json` + every named object.
  final int bytes;
}

/// Reads `--base-url <url>` and `--content-version <sha256>`, each exactly once, in either order.
({String baseUrl, String contentVersion}) parseSnapshotArgs(List<String> args) {
  final values = <String, String>{};
  for (var i = 0; i < args.length; i += 2) {
    final flag = args[i];
    if (flag != '--base-url' && flag != '--content-version') throw SnapshotException('unknown argument $flag\n$usage');
    if (values.containsKey(flag)) throw SnapshotException('$flag given twice\n$usage');
    if (i + 1 >= args.length) throw SnapshotException('$flag needs a value\n$usage');
    values[flag] = args[i + 1];
  }
  final baseUrl = values['--base-url'];
  final contentVersion = values['--content-version'];
  if (baseUrl == null || contentVersion == null) throw const SnapshotException('both flags are required\n$usage');
  _checkArguments(baseUrl, contentVersion);
  return (baseUrl: baseUrl, contentVersion: contentVersion);
}

/// The URL of [sitePath] under [baseUrl]: string concatenation, never `Uri.resolve`, with `?v=<sha256>` for an object.
Uri snapshotUri(String baseUrl, String sitePath, {String? sha256}) =>
    Uri.parse(baseUrl + sitePath + (sha256 == null ? '' : '?v=$sha256'));

/// Replaces `root/assets/content` and `root/test/fixtures/record_conformance/v1.json` with the site's bundle at
/// [contentVersion].
Future<SnapshotReport> refreshContentSnapshot({
  required http.Client client,
  required String baseUrl,
  required String contentVersion,
  required String root,
}) async {
  _checkArguments(baseUrl, contentVersion);

  final apiIndexBytes = await _get(client, snapshotUri(baseUrl, 'api/index.json'));
  final apiIndex = _decodeObject('api/index.json', apiIndexBytes);
  final majors = apiIndex['majors'];
  if (majors is! List || !majors.any((major) => major is int && major == 1)) {
    throw SnapshotException('api/index.json lists majors ${jsonEncode(majors)}, which do not contain 1');
  }

  final indexBytes = await _get(client, snapshotUri(baseUrl, 'api/v1/index.json'));
  final index = _decodeObject('api/v1/index.json', indexBytes);
  final served = index['contentVersion'];
  if (served != contentVersion) {
    throw SnapshotException('the site serves contentVersion $served, not $contentVersion');
  }
  final pathBySha = <String, String>{};
  for (final section in const ['files', 'images']) {
    for (final MapEntry(key: path, value: sha) in _entries(index, section)) {
      pathBySha.putIfAbsent(sha, () => path);
    }
  }

  final conformanceBytes = await _get(client, snapshotUri(baseUrl, 'api/v1/record-conformance.json'));
  _decodeObject('api/v1/record-conformance.json', conformanceBytes);

  final content = Directory('$root/assets/content');
  final objects = Directory('${content.path}/objects')..createSync(recursive: true);
  var fetched = 0;
  var bytes = indexBytes.length + apiIndexBytes.length;
  for (final MapEntry(key: sha, value: path) in pathBySha.entries) {
    final file = File('${objects.path}/$sha');
    if (file.existsSync()) {
      final onDisk = file.readAsBytesSync();
      if (sha256.convert(onDisk).toString() == sha) {
        bytes += onDisk.length;
        continue;
      }
    }
    final body = await _get(client, snapshotUri(baseUrl, path, sha256: sha));
    final actual = sha256.convert(body).toString();
    if (actual != sha) throw SnapshotException('$path: expected sha256 $sha, got $actual');
    _writeThroughTmp(file, body);
    fetched++;
    bytes += body.length;
  }

  _writeThroughTmp(File('${content.path}/index.json'), indexBytes);
  _writeThroughTmp(File('${content.path}/api_index.json'), apiIndexBytes);
  final fixture = File('$root/test/fixtures/record_conformance/v1.json');
  fixture.parent.createSync(recursive: true);
  _writeThroughTmp(fixture, conformanceBytes);

  var removed = 0;
  for (final file in objects.listSync().whereType<File>()) {
    if (!pathBySha.containsKey(file.uri.pathSegments.last)) {
      file.deleteSync();
      removed++;
    }
  }

  return SnapshotReport(objects: pathBySha.length, fetched: fetched, removed: removed, bytes: bytes);
}

void _checkArguments(String baseUrl, String contentVersion) {
  if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
    throw SnapshotException('the base URL $baseUrl must start with http:// or https://');
  }
  if (!baseUrl.endsWith('/')) throw SnapshotException('the base URL $baseUrl must end with /');
  if (!_sha256.hasMatch(contentVersion)) {
    throw SnapshotException('the content version $contentVersion is not 64 lowercase hex characters');
  }
}

Future<List<int>> _get(http.Client client, Uri uri) async {
  final response = await client.get(uri);
  if (response.statusCode != 200) throw SnapshotException('GET $uri answered ${response.statusCode}, not 200');
  return response.bodyBytes;
}

Map<String, Object?> _decodeObject(String sitePath, List<int> bytes) {
  final Object? value;
  try {
    value = jsonDecode(utf8.decode(bytes));
  } on FormatException catch (error) {
    throw SnapshotException('$sitePath is not JSON: ${error.message}');
  }
  if (value is! Map<String, Object?>) throw SnapshotException('$sitePath is not a JSON object');
  return value;
}

Iterable<MapEntry<String, String>> _entries(Map<String, Object?> index, String section) {
  final map = index[section];
  if (map is! Map<String, Object?>) throw SnapshotException('api/v1/index.json has no $section object');
  return [
    for (final MapEntry(:key, :value) in map.entries)
      if (!_sitePath.hasMatch(key))
        throw SnapshotException('$section names $key, which is not a site path')
      else if (value is! String || !_sha256.hasMatch(value))
        throw SnapshotException('$section gives $key the sha256 $value, which is not 64 lowercase hex characters')
      else
        MapEntry(key, value),
  ];
}

void _writeThroughTmp(File file, List<int> bytes) {
  final tmp = File('${file.path}.tmp')..writeAsBytesSync(bytes, flush: true);
  tmp.renameSync(file.path);
}
