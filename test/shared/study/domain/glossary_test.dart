import 'package:ai_engineering_bazaar/shared/study/domain/glossary.dart';
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

  test('finds as it is typed: one letter finds the names that start with it (the owner, 2026-11-18)', () {
    final entries = glossaryOf(modules, 'en');
    expect([for (final entry in glossaryFind(entries, 'w', 'en')) entry.name], ['Wick'], reason: 'not Glass by "wind"');
    expect([for (final entry in glossaryFind(entries, 'L', 'en')) entry.name], ['Lantern']);
    expect(glossaryFind(entries, 'x', 'en'), isEmpty);
  });

  test('a name that starts with the query comes before a definition that holds it', () {
    final entries = glossaryOf(modules, 'en');
    expect([for (final entry in glossaryFind(entries, 'wi', 'en')) entry.name], ['Wick', 'Glass']);
  });

  test('Turkish names sort and match by the search rules', () {
    final tr = glossaryOf([
      ModuleNotes(moduleKey: 'a/b', terms: [_term('a/b', 0, 'Şema', 'yapı.'), _term('a/b', 1, 'Çıktı', 'sonuç.')]),
    ], 'tr');
    expect([for (final entry in glossaryFind(tr, 'cikti', 'tr')) entry.name], ['Çıktı']);
    expect([for (final entry in glossaryFind(tr, 'ş', 'tr')) entry.name], ['Şema'], reason: 'one letter, folded');
  });

  // Review 7, finding 16: by code point, Turkish ç came after z, and once folded it split the C group; Persian
  // پ چ ژ ک گ came after ی.
  test('Turkish names sort by the Turkish alphabet, each letter heading its own group', () {
    List<String> names(List<String> terms) => [
      for (final entry in glossaryOf([
        ModuleNotes(moduleKey: 'a/b', terms: [for (final (i, term) in terms.indexed) _term('a/b', i, term, 'x.')]),
      ], 'tr'))
        entry.name,
    ];
    expect(names(['Zaman', 'Çıktı', 'Cevap', 'Ceket', 'Ilık', 'İz', 'Şema', 'Sıra', 'Ölçek', 'Oran', 'Ğ']), [
      'Ceket',
      'Cevap',
      'Çıktı',
      'Ğ',
      'Ilık',
      'İz',
      'Oran',
      'Ölçek',
      'Sıra',
      'Şema',
      'Zaman',
    ]);
    expect(glossaryLetter('ilk', 'tr'), 'İ');
    expect(glossaryLetter('ılık', 'tr'), 'I');
    expect(glossaryLetter('çay', 'tr'), 'Ç');
    expect(glossaryLetter('ilk', 'en'), 'I');
  });

  test('Persian names sort by the Persian alphabet', () {
    final names = [
      for (final entry in glossaryOf([
        ModuleNotes(
          moduleKey: 'a/b',
          terms: [
            for (final (i, term) in ['یادگیری', 'گراف', 'کد', 'ژن', 'چت', 'پایه', 'بردار', 'زبان'].indexed)
              _term('a/b', i, term, 'x.'),
          ],
        ),
      ], 'fa'))
        entry.name,
    ];
    expect(names, ['بردار', 'پایه', 'چت', 'زبان', 'ژن', 'کد', 'گراف', 'یادگیری']);
  });
}
