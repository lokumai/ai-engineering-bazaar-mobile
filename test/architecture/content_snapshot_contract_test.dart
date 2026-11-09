@Tags(['widget'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vgc;

/// Spec 3.11: the bundled snapshot under assets/content/ holds the contract the reader relies on.
///
/// Every object is named by its sha256, every document parses, every diagram follows the web's SVG profile
/// (`scripts/lib/svg-profile.mjs`) and draws one text command per label, and every SVG and raster figure decodes.
/// Logos are held only to the decode check (Decision A29); every raster figure is decoded once (Decision A44).
const _contentRoot = 'assets/content';

/// The web's `FORBIDDEN_STRINGS`, `svg-profile.mjs:83-93`.
const forbiddenStrings = [
  '<style',
  '<marker',
  '<foreignObject',
  '<filter',
  'var(',
  'class=',
  'style=',
  'dominant-baseline',
  'alignment-baseline',
];

/// One start, end or self-closing tag, with its attributes captured whole (`svg-profile.mjs` `TAG`).
final _tag = RegExp(r'''<(\/?)([A-Za-z][\w:.-]*)((?:\s+[^\s=/>]+\s*=\s*(?:"[^"]*"|'[^']*'))*)\s*(\/?)>''');

/// One attribute of a tag's attribute text (`svg-profile.mjs` `ATTRIBUTE`).
final _attribute = RegExp(r'''\s+([^\s=/>]+)\s*=\s*("([^"]*)"|'([^']*)')''');

/// What may precede the root: an XML declaration or a comment (`svg-profile.mjs` `PROLOGUE`).
final _prologue = RegExp(r'<\?[\s\S]*?\?>|<!--[\s\S]*?-->');

/// `carries()`, `svg-profile.mjs:140-143`: a forbidden string ending in '=' matches only after whitespace, where an
/// attribute name starts.
bool _carries(String markup, String forbidden) =>
    forbidden.endsWith('=') ? RegExp(r'\s' + RegExp.escape(forbidden)).hasMatch(markup) : markup.contains(forbidden);

typedef _Tag = ({int start, int end, bool closing, String name, List<String> attributes, bool selfClosing});

/// Every tag in document order, and the offset of the first '<' that opens none (`tokenize`, `svg-profile.mjs`).
({List<_Tag> tags, int? unmatched}) _tokenize(String svg) {
  final tags = <_Tag>[];
  var at = 0;
  while (true) {
    final open = svg.indexOf('<', at);
    if (open == -1) return (tags: tags, unmatched: null);
    final prologue = _prologue.matchAsPrefix(svg, open);
    if (prologue != null) {
      at = prologue.end;
      continue;
    }
    final match = _tag.matchAsPrefix(svg, open);
    if (match == null) return (tags: tags, unmatched: open);
    tags.add((
      start: open,
      end: match.end,
      closing: match.group(1) == '/',
      name: match.group(2)!,
      attributes: [for (final attribute in _attribute.allMatches(match.group(3)!)) attribute.group(1)!],
      selfClosing: match.group(4) == '/',
    ));
    at = match.end;
  }
}

/// The SVG's markup without its label text (`svg-profile.mjs:249-259`): every tag, and past a '<' that opens no tag,
/// the rest of the file.
String _markup(String svg) {
  final (:tags, :unmatched) = _tokenize(svg);
  return tags.map((tag) => svg.substring(tag.start, tag.end)).join() +
      (unmatched == null ? '' : svg.substring(unmatched));
}

/// The first non-closing tag is `svg` and has a `viewBox` attribute.
bool _rootHasViewBox(String svg) {
  final root = _tokenize(svg).tags.where((tag) => !tag.closing).firstOrNull;
  return root != null && root.name == 'svg' && root.attributes.contains('viewBox');
}

/// The `text` and `tspan` elements that hold text directly and draw it: an opening, non-self-closing tag whose next
/// tag is its own closing tag, with a non-whitespace character between them.
int _textLeaves(String svg) {
  final tags = _tokenize(svg).tags;
  var leaves = 0;
  for (final (index, tag) in tags.indexed) {
    if (tag.closing || tag.selfClosing || (tag.name != 'text' && tag.name != 'tspan')) continue;
    if (index + 1 >= tags.length) continue;
    final next = tags[index + 1];
    if (!next.closing || next.name != tag.name) continue;
    if (svg.substring(tag.end, next.start).trim().isNotEmpty) leaves++;
  }
  return leaves;
}

/// One site path per distinct sha256 among [entries] that [include] accepts, in path order.
List<({String path, String sha256})> _distinct(Map<String, String> entries, bool Function(String path) include) {
  final seen = <String>{};
  return [
    for (final path in entries.keys.where(include).toList()..sort())
      if (seen.add(entries[path]!)) (path: path, sha256: entries[path]!),
  ];
}

String _object(String sha256) => File('$_contentRoot/objects/$sha256').readAsStringSync();

void main() {
  final index = ContentParser.parseIndex(File('$_contentRoot/index.json').readAsStringSync());
  final documentPaths = [
    for (final path in index.files.keys)
      if (path.startsWith('api/v1/levels/') || path.startsWith('api/v1/modules/')) path,
  ]..sort();
  final diagrams = _distinct(index.files, (path) => path.startsWith('api/v1/diagrams/'));
  final logos = _distinct(index.images, (path) => path.endsWith('.svg'));
  final rasters = _distinct(index.images, (path) => !path.endsWith('.svg'));

  test('the api index lists major 1', () {
    final majors = ContentParser.parseMajors(File('$_contentRoot/api_index.json').readAsStringSync());
    expect(majors.majors, contains(1));
  });

  test('the store holds exactly the indexed objects, each named by its sha256', () {
    final objects = Directory('$_contentRoot/objects').listSync().whereType<File>().toList();
    expect(
      {for (final object in objects) object.uri.pathSegments.last},
      {...index.files.values, ...index.images.values},
    );
    for (final object in objects) {
      expect(sha256.convert(object.readAsBytesSync()).toString(), object.uri.pathSegments.last, reason: object.path);
    }
  });

  for (final path in documentPaths) {
    test('parses $path', () {
      final json = _object(index.files[path]!);
      if (path.startsWith('api/v1/levels/')) {
        ContentParser.parseLevelDoc(json, index, path: path);
      } else {
        ContentParser.parseModuleDoc(json, index, path: path);
      }
    });
  }

  for (final (:path, :sha256) in diagrams) {
    test('diagram $path follows the profile', () {
      final text = _object(sha256);
      expect(_rootHasViewBox(text), isTrue);
      expect(forbiddenStrings.where((forbidden) => _carries(_markup(text), forbidden)), isEmpty);
      final draws = vgc
          .parseWithoutOptimizers(text, warningsAsErrors: true)
          .commands
          .where((command) => command.type == vgc.DrawCommandType.text)
          .length;
      expect(draws, _textLeaves(text));
    });
  }

  for (final (:path, :sha256) in [...diagrams, ...logos]) {
    testWidgets('decodes $path with flutter_svg', (tester) async {
      final text = _object(sha256);
      final info = await tester.runAsync(() => vg.loadPicture(SvgStringLoader(text), null));
      expect(tester.takeException(), isNull);
      expect(info, isNotNull);
      info!.picture.dispose();
    });
  }

  for (final (:path, :sha256) in rasters) {
    testWidgets('decodes $path', (tester) async {
      final bytes = File('$_contentRoot/objects/$sha256').readAsBytesSync();
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        codec.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }

  test('the snapshot has raster figures to decode', () => expect(rasters, isNotEmpty));

  group('the profile helpers', () {
    test(
      'style= inside font-style= is not carried',
      () => expect(_carries('<text font-style="normal">', 'style='), isFalse),
    );
    test('a style attribute is carried', () => expect(_carries('<g style="x">', 'style='), isTrue));
    test(
      'label text is not markup',
      () => expect(_markup('<svg viewBox="0 0 1 1"><text>var(</text></svg>'), isNot(contains('var('))),
    );
    test(
      'empty self-closing tspans are not leaves',
      () => expect(
        _textLeaves('<svg><text>a</text><text><tspan x="0"/></text><text> </text><text><tspan>b</tspan></text></svg>'),
        2,
      ),
    );
    test('a root without a viewBox, or a root that is not svg, fails', () {
      expect(_rootHasViewBox('<?xml version="1.0"?><!-- c --><svg viewBox="0 0 1 1"/>'), isTrue);
      expect(_rootHasViewBox('<svg width="1" height="1"/>'), isFalse);
      expect(_rootHasViewBox('<g viewBox="0 0 1 1"/>'), isFalse);
    });
    test('past a < that opens no tag, the rest of the file is markup', () {
      expect(_markup('<svg><text>a < b var(</text></svg>'), '<svg><text>< b var(</text></svg>');
    });
  });
}
