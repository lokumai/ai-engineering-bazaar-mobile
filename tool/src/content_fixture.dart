import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Builds the synthetic content bundle the tests read (spec 3.11) from its hand-written sources.
///
/// [source] holds the bundle in site layout: `api/index.json`, `api/v1/index.json` (whose `files` and `images` are
/// placeholders), the documents and diagrams under `api/v1/`, and the images under `course-images/`. [output] receives
/// what `assets/content/` holds for the real snapshot: `api_index.json`, `index.json` with `files` and `images` filled
/// in (site path to sha256, sorted by path), and `objects/<sha256>`, each distinct object once. Whatever [output] held
/// before is deleted. Pure Dart, so `fvm dart run tool/build_content_fixture.dart` runs it.
void buildContentFixture({required Directory source, required Directory output}) {
  final root = source.absolute.path;
  final files = <String, String>{};
  final images = <String, String>{};
  final objects = <String, List<int>>{};
  final sources = source.listSync(recursive: true).whereType<File>().toList();
  for (final file in sources) {
    final path = file.absolute.path.substring(root.length + 1).replaceAll(r'\', '/');
    if (path == 'api/index.json' || path == 'api/v1/index.json') continue;
    final Map<String, String> target;
    if (path.startsWith('api/v1/')) {
      target = files;
    } else if (path.startsWith('course-images/')) {
      target = images;
    } else {
      throw StateError('$path: a fixture source must be under api/ or course-images/');
    }
    final bytes = file.readAsBytesSync();
    final sha = sha256.convert(bytes).toString();
    target[path] = sha;
    objects[sha] = bytes;
  }

  final indexFile = File('$root/api/v1/index.json');
  final index = jsonDecode(indexFile.readAsStringSync());
  if (index is! Map<String, Object?>) throw StateError('api/v1/index.json: not a JSON object');
  for (final key in const ['files', 'images']) {
    if (!index.containsKey(key)) throw StateError('api/v1/index.json: no $key');
  }
  index['files'] = _sorted(files);
  index['images'] = _sorted(images);

  if (output.existsSync()) output.deleteSync(recursive: true);
  Directory('${output.path}/objects').createSync(recursive: true);
  File('$root/api/index.json').copySync('${output.path}/api_index.json');
  File('${output.path}/index.json').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(index)}\n');
  for (final MapEntry(key: sha, value: bytes) in objects.entries) {
    File('${output.path}/objects/$sha').writeAsBytesSync(bytes);
  }
}

Map<String, String> _sorted(Map<String, String> entries) => {
  for (final key in entries.keys.toList()..sort()) key: entries[key]!,
};
