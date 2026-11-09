import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/content_fixture.dart';
import '../support/content_fixture.dart';

/// Every file under [root] as its path relative to [root] (with `/`) mapped to its bytes.
Map<String, List<int>> _tree(Directory root) => {
  for (final file in root.listSync(recursive: true).whereType<File>())
    file.path.substring(root.path.length + 1).replaceAll(r'\', '/'): file.readAsBytesSync(),
};

BundleIndex _fixtureIndex() => ContentParser.parseIndex(File('$contentFixtureBundle/index.json').readAsStringSync());

String _object(BundleIndex index, String sitePath) =>
    File('$contentFixtureBundle/objects/${index.sha256Of(sitePath)}').readAsStringSync();

/// A temporary source tree holding [files] (site path to text), removed after the test.
Directory _source(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('content_fixture_source');
  addTearDown(() => root.deleteSync(recursive: true));
  for (final MapEntry(:key, :value) in files.entries) {
    File('${root.path}/$key')
      ..createSync(recursive: true)
      ..writeAsStringSync(value);
  }
  return root;
}

Directory _output() {
  final out = Directory.systemTemp.createTempSync('content_fixture_output');
  addTearDown(() {
    if (out.existsSync()) out.deleteSync(recursive: true);
  });
  return out;
}

void main() {
  test('the committed bundle equals a fresh build of the sources', () {
    final out = _output();
    buildContentFixture(source: Directory('test/fixtures/content/src'), output: out);
    final fresh = _tree(out);
    final committed = _tree(Directory(contentFixtureBundle));
    expect(fresh.keys.toSet(), committed.keys.toSet());
    for (final path in fresh.keys) {
      expect(fresh[path], committed[path], reason: path);
    }
  });

  test('every object is named by the sha256 of its bytes', () {
    final objects = Directory('$contentFixtureBundle/objects').listSync().whereType<File>().toList();
    expect(objects, isNotEmpty);
    for (final object in objects) {
      expect(sha256.convert(object.readAsBytesSync()).toString(), object.uri.pathSegments.last);
    }
  });

  test('every sha256 the index names has an object, and every object is named', () {
    final index = _fixtureIndex();
    final named = {...index.files.values, ...index.images.values};
    final present = Directory('$contentFixtureBundle/objects').listSync().map((e) => e.uri.pathSegments.last).toSet();
    expect(present, named);
  });

  test('a source file outside api/ and course-images/ is refused', () {
    final source = _source({'api/index.json': '{"majors":[1]}', 'api/v1/index.json': _minimalIndex, 'notes.txt': 'x'});
    expect(
      () => buildContentFixture(source: source, output: _output()),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('notes.txt'))),
    );
  });

  test('a source index without files is refused', () {
    final index = jsonDecode(_minimalIndex) as Map<String, Object?>..remove('files');
    final source = _source({'api/index.json': '{"majors":[1]}', 'api/v1/index.json': jsonEncode(index)});
    expect(
      () => buildContentFixture(source: source, output: _output()),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('files'))),
    );
  });

  test('a source index without images is refused', () {
    final index = jsonDecode(_minimalIndex) as Map<String, Object?>..remove('images');
    final source = _source({'api/index.json': '{"majors":[1]}', 'api/v1/index.json': jsonEncode(index)});
    expect(
      () => buildContentFixture(source: source, output: _output()),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('images'))),
    );
  });

  test('a build replaces what the output held, and keeps the key order of the source index', () {
    final out = _output();
    File('${out.path}/stale.txt').writeAsStringSync('old');
    final source = _source({
      'api/index.json': '{"majors":[1]}',
      'api/v1/index.json': _minimalIndex,
      'api/v1/levels/b.json': '{"b":1}',
      'api/v1/levels/a.json': '{"a":1}',
      'course-images/x/one.svg': '<svg/>',
      'course-images/x/two.svg': '<svg/>',
    });
    buildContentFixture(source: source, output: out);
    expect(File('${out.path}/stale.txt').existsSync(), isFalse);
    expect(File('${out.path}/api_index.json').readAsStringSync(), '{"majors":[1]}');
    final text = File('${out.path}/index.json').readAsStringSync();
    expect(text.endsWith('}\n'), isTrue);
    final written = jsonDecode(text) as Map<String, Object?>;
    expect(written.keys, ['schemaVersion', 'files', 'images', 'after']);
    expect((written['files']! as Map).keys, ['api/v1/levels/a.json', 'api/v1/levels/b.json']);
    final svg = sha256.convert(utf8.encode('<svg/>')).toString();
    expect(written['images'], {'course-images/x/one.svg': svg, 'course-images/x/two.svg': svg});
    expect(Directory('${out.path}/objects').listSync(), hasLength(3));
  });

  test('the fixture parses with the production parser', () {
    final index = _fixtureIndex();
    for (final path in index.files.keys) {
      if (path.startsWith('api/v1/levels/')) {
        ContentParser.parseLevelDoc(_object(index, path), index, path: path);
      } else if (path.startsWith('api/v1/modules/')) {
        ContentParser.parseModuleDoc(_object(index, path), index, path: path);
      }
    }
    expect(index.modules.map((m) => m.key), ['alpha/first', 'alpha/second', 'beta/third']);
    expect(index.module('alpha/second')!.tracks[Track.everyone]!.docs, isEmpty);
    expect(ContentParser.parseMajors(File('$contentFixtureBundle/api_index.json').readAsStringSync()).majors, [1]);
  });

  test('the For Engineers alpha/first document holds one block of every type', () {
    final index = _fixtureIndex();
    const path = 'api/v1/modules/alpha/first/en.json';
    final doc = ContentParser.parseModuleDoc(_object(index, path), index, path: path);
    expect(
      doc.body!.map((b) => b.runtimeType).toSet(),
      containsAll(<Type>[
        ParagraphBlock,
        HeadingBlock,
        ListBlock,
        QuoteBlock,
        CalloutBlock,
        CodeBlock,
        TableBlock,
        ImageBlock,
        DiagramBlock,
        RuleBlock,
        UnknownBlock,
      ]),
    );
    expect(doc.quiz, hasLength(2));
  });
}

const _minimalIndex = '{"schemaVersion":1,"files":{"stale":"x"},"images":{},"after":true}';
