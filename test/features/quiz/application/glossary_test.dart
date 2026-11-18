import 'package:ai_engineering_bazaar/features/quiz/application/glossary.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

GlossaryTerm _term(String module, int index, String name, String definition) => GlossaryTerm(
  moduleKey: module,
  index: index,
  name: name,
  forms: [name],
  definition: [TextInline(text: definition)],
);

void main() {
  final modules = [
    ModuleNotes(
      moduleKey: 'alpha/first',
      terms: [_term('alpha/first', 0, 'Wick', 'what burns.'), _term('alpha/first', 1, 'Lantern', 'a light you carry.')],
    ),
    ModuleNotes(
      moduleKey: 'alpha/second',
      terms: [_term('alpha/second', 0, 'wick', 'the cord.'), _term('alpha/second', 1, 'Glass', 'keeps wind out.')],
    ),
  ];

  test('one entry per name, A to Z, the first module giving the definition', () {
    final entries = glossaryOf(modules, 'en');
    expect([for (final entry in entries) entry.name], ['Glass', 'Lantern', 'Wick']);
    final wick = entries.last;
    expect([for (final term in wick.terms) term.moduleKey], ['alpha/first', 'alpha/second']);
    expect(wick.first.definitionText, 'what burns.');
    expect(wick.keyIn(Track.engineers), 'term:engineers/alpha/first#0');
  });

  test('finds by the start of a word of the name or the definition', () {
    final entries = glossaryOf(modules, 'en');
    expect([for (final entry in glossaryFind(entries, 'lan', 'en')) entry.name], ['Lantern']);
    expect([for (final entry in glossaryFind(entries, 'wind', 'en')) entry.name], ['Glass']);
    expect(glossaryFind(entries, '  ', 'en'), entries);
    expect(glossaryFind(entries, 'nothing', 'en'), isEmpty);
  });

  test('Turkish names sort and match by the search rules', () {
    final tr = glossaryOf([
      ModuleNotes(moduleKey: 'a/b', terms: [_term('a/b', 0, 'Şema', 'yapı.'), _term('a/b', 1, 'Çıktı', 'sonuç.')]),
    ], 'tr');
    expect([for (final entry in glossaryFind(tr, 'cikti', 'tr')) entry.name], ['Çıktı']);
  });
}
