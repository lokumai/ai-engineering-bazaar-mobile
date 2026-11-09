import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:crypto/crypto.dart';

import '../../support/content_fixture.dart';

/// The site path the cache index adds to the fixture's index; its object is held by the cache only.
const cacheOnlyPath = 'api/v1/modules/alpha/first/tr.json';

/// The fixture's bundled index, parsed.
BundleIndex fixtureIndex() => ContentParser.parseIndex(File('$contentFixtureBundle/index.json').readAsStringSync());

/// The bytes of a fixture object, by site path.
List<int> fixtureObject(String sitePath) =>
    File('$contentFixtureBundle/objects/${fixtureIndex().sha256Of(sitePath)}').readAsBytesSync();

/// The object [cacheOnlyPath] names: the fixture's `alpha/first` English document with `lang` set to `tr`.
List<int> cacheOnlyObject() {
  final doc = jsonDecode(utf8.decode(fixtureObject('api/v1/modules/alpha/first/en.json'))) as Map<String, Object?>;
  return utf8.encode(jsonEncode({...doc, 'lang': 'tr'}));
}

/// The sha256 of [cacheOnlyObject].
String cacheOnlySha() => sha256.convert(cacheOnlyObject()).toString();

/// Writes a downloaded cache under `<cacheRoot>/content/`: the fixture index with [publishedAt] and [contentVersion]
/// replaced and one `files` entry [cacheOnlyPath] added, as `indexes/<contentVersion>.json`, the `current` pointer,
/// and (with [withObjects]) the object [cacheOnlyPath] names, plus [extraObjects] by file name.
void writeCache(
  Directory cacheRoot, {
  required String publishedAt,
  String contentVersion = '2222222222222222222222222222222222222222222222222222222222222222',
  bool withObjects = true,
  Map<String, List<int>> extraObjects = const {},
}) {
  final index = jsonDecode(File('$contentFixtureBundle/index.json').readAsStringSync()) as Map<String, Object?>;
  final files = {...index['files']! as Map<String, Object?>, cacheOnlyPath: cacheOnlySha()};
  final cacheIndex = {...index, 'contentVersion': contentVersion, 'publishedAt': publishedAt, 'files': files};
  final content = '${cacheRoot.path}/content';
  Directory('$content/indexes').createSync(recursive: true);
  Directory('$content/objects').createSync(recursive: true);
  File('$content/indexes/$contentVersion.json').writeAsStringSync(jsonEncode(cacheIndex));
  File('$content/current').writeAsStringSync(contentVersion);
  if (withObjects) File('$content/objects/${cacheOnlySha()}').writeAsBytesSync(cacheOnlyObject());
  for (final MapEntry(:key, :value) in extraObjects.entries) {
    File('$content/objects/$key').writeAsBytesSync(value);
  }
}

/// A later instant than the fixture's `2026-01-02T03:04:05.000Z`.
const laterPublishedAt = '2026-02-01T00:00:00.000Z';

FileContentRepository fixtureRepository(Directory cacheRoot, {Map<String, String> overrides = const {}}) =>
    FileContentRepository(
      bundled: BundledContent(bundle: FixtureAssetBundle(overrides: overrides)),
      cacheDirectory: () async => cacheRoot,
    );
