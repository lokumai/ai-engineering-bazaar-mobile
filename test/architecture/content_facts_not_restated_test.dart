import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dart_code.dart';

/// Guards spec 3.11: no string literal in `lib/`, `test/` or `integration_test/` restates a fact about the course.
///
/// The facts come from the bundled snapshot: every module key, every key and value of `moved.modules`, and every
/// module title (both tracks) and level title of two or more words. Tests read the synthetic fixture under
/// `test/fixtures/content/` instead, and code reads the bundle, so a refreshed snapshot never breaks a test or a
/// screen that wrote one of these down.

/// A fact that may appear in a literal, mapped to the reason it must stay.
const Map<String, String> _allowed = {};

final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
final _whitespace = RegExp(r'\s+');

RegExp _keyPattern(String key) => RegExp('(?<![\\w-])${RegExp.escape(key)}(?![\\w-])');

RegExp _titlePattern(String title) => RegExp('(?<!\\w)${RegExp.escape(title)}(?!\\w)', caseSensitive: false);

/// Every fact of [keys] and [titles] that a string literal of [source] holds, as `<line>: <fact>`, in source order.
List<String> _factsIn(String source, {required Set<String> keys, required Set<String> titles}) {
  final patterns = [
    for (final key in keys) (fact: key, pattern: _keyPattern(key)),
    for (final title in titles) (fact: title, pattern: _titlePattern(title)),
  ];
  return [
    for (final literal in stringLiterals(source))
      for (final (:fact, :pattern) in patterns)
        if (pattern.hasMatch(literal.text.replaceAll(_interpolation, ''))) '${literal.line}: $fact',
  ];
}

void main() {
  final index = ContentParser.parseIndex(File('assets/content/index.json').readAsStringSync());
  final keys = {
    for (final module in index.modules) module.key,
    ...index.moved.modules.keys,
    ...index.moved.modules.values,
  };
  bool manyWords(String title) => title.trim().split(_whitespace).length >= 2;
  final titles = {
    for (final module in index.modules)
      for (final track in module.tracks.values)
        if (manyWords(track.title)) track.title,
    for (final level in index.levels)
      if (manyWords(level.title)) level.title,
  };

  final files = [
    for (final root in const ['lib', 'test', 'integration_test'])
      ...Directory(root).listSync(recursive: true).whereType<File>().where((file) {
        final path = file.path.replaceAll(r'\', '/');
        return path.endsWith('.dart') && !path.startsWith('lib/generated/');
      }),
  ]..sort((a, b) => a.path.compareTo(b.path));

  // Every match before the allowlist applies, as `<path>:<line>: <fact>`.
  final matches = [
    for (final file in files)
      for (final found in _factsIn(file.readAsStringSync(), keys: keys, titles: titles))
        '${file.path.replaceAll(r'\', '/')}:$found',
  ];
  String factOf(String match) => match.substring(match.indexOf(': ') + 2);
  final violations = [
    for (final match in matches)
      if (!_allowed.containsKey(factOf(match))) match,
  ];

  test('the matcher finds keys and titles inside literals only', () {
    const source =
        "// alpha/first\nfinal a = 'opens alpha/first now'; final b = \"FIRST MODULE\"; final c = 'alpha/first-draft';";
    expect(_factsIn(source, keys: {'alpha/first'}, titles: {'First Module'}), ['2: alpha/first', '2: First Module']);
  });

  test('the matcher finds a key inside a route, a URL or a bundle path', () {
    const source =
        "final a = '/courses/alpha/first'; final b = 'https://x.dev/everyone/courses/alpha/first/'; "
        "final c = 'api/v1/modules/alpha/first/en.json';";
    expect(_factsIn(source, keys: {'alpha/first'}, titles: {}), ['1: alpha/first', '1: alpha/first', '1: alpha/first']);
  });

  test('the matcher ignores interpolations and words that only contain a title', () {
    const source = r"final a = 'alpha/$first'; final b = 'Firsts Module'; final c = '${x} first module';";
    expect(_factsIn(source, keys: {'alpha/first'}, titles: {'First Module'}), ['1: First Module']);
  });

  test('the snapshot yields facts to look for', () {
    expect(keys, isNotEmpty);
    expect(titles, isNotEmpty);
    expect(files, isNotEmpty);
    expect(
      files.any((file) => file.path.replaceAll(r'\', '/').startsWith('integration_test/')),
      isTrue,
      reason: 'the guard read no device test',
    );
  });

  test(
    'no literal in lib/, test/ or integration_test/ restates a course fact',
    () => expect(violations, isEmpty, reason: violations.join('\n')),
  );

  test('every allowlist entry has a reason and still matches', () {
    for (final MapEntry(key: fact, value: reason) in _allowed.entries) {
      expect(reason.trim(), isNotEmpty, reason: '$fact has no reason');
      expect(keys.contains(fact) || titles.contains(fact), isTrue, reason: '$fact is no longer a course fact');
      expect(matches.map(factOf), contains(fact), reason: '$fact no longer appears in a literal');
    }
  });
}
