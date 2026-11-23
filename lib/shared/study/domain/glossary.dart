import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// One entry of the glossary (plan 13.8): a term as one or more modules' Key Terms hold it, under the same name.
final class GlossaryEntry extends Equatable {
  const GlossaryEntry({required this.name, required this.sortKey, required this.terms});

  /// The term's name, as the first module that holds it prints it.
  final String name;

  /// [name] as the search compares words, which orders the glossary A to Z.
  final String sortKey;

  /// The term in each module that holds it, in the course's order; the first gives the definition.
  final List<GlossaryTerm> terms;

  GlossaryTerm get first => terms.first;

  /// The key Practice's history keeps the term under in [track]: its first module's.
  String keyIn(Track track) => termKey(track, first.moduleKey, first.index);

  @override
  List<Object?> get props => [name, sortKey, terms];
}

/// Every Key Terms entry of [modules], one entry per name, A to Z as [lang] compares words.
List<GlossaryEntry> glossaryOf(List<ModuleNotes> modules, String lang) {
  final byName = <String, List<GlossaryTerm>>{};
  final names = <String, String>{};
  for (final notes in modules) {
    for (final term in notes.terms) {
      final key = normalise(term.name, lang);
      byName.putIfAbsent(key, () => []).add(term);
      names.putIfAbsent(key, () => term.name);
    }
  }
  return [
    for (final MapEntry(:key, value: terms) in byName.entries)
      GlossaryEntry(name: names[key]!, sortKey: key, terms: List.unmodifiable(terms)),
  ]..sort((a, b) => _compare(a, b, lang));
}

/// The first letter of [name] as the glossary heads its group: upper-cased by [lang]'s rules (Turkish i is İ).
String glossaryLetter(String name, String lang) {
  final first = name.runes.isEmpty ? '' : String.fromCharCode(name.runes.first);
  return switch ((lang, first)) {
    ('tr', 'i') => 'İ',
    ('tr', 'ı') => 'I',
    _ => first.toUpperCase(),
  };
}

/// Review 7, finding 16: the names sorted by code point, so Turkish ç came after z and split the C group in two once
/// folded, and Persian پ چ ژ ک گ came after ی. They sort by [lang]'s alphabet now; a tie falls back to the search key.
int _compare(GlossaryEntry a, GlossaryEntry b, String lang) {
  final byLetters = _collationKey(a.name, lang).compareTo(_collationKey(b.name, lang));
  return byLetters != 0 ? byLetters : a.sortKey.compareTo(b.sortKey);
}

const _turkishAlphabet = 'abcçdefgğhıijklmnoöpqrsştuüvwxyz';
const _persianAlphabet = 'اآبپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی';

/// [name] with each letter of [lang]'s alphabet written as its place in it, past every other character, so the order
/// of the text is the alphabet's.
String _collationKey(String name, String lang) {
  final (alphabet, lower) = switch (lang) {
    'tr' => (
      _turkishAlphabet,
      name
          .replaceAll('I', 'ı')
          .replaceAll('İ', 'i')
          .toLowerCase()
          .replaceAll('â', 'a')
          .replaceAll('î', 'i')
          .replaceAll('û', 'u'),
    ),
    'fa' => (
      _persianAlphabet,
      name
          .replaceAll(RegExp('[يى]'), 'ی')
          .replaceAll('ك', 'ک')
          .replaceAll('ة', 'ه')
          .replaceAll(RegExp('[أإ]'), 'ا')
          .replaceAll(RegExp('[\u200c\u0640\u064b-\u0652\u0670]'), '')
          .toLowerCase(),
    ),
    _ => ('', name.toLowerCase()),
  };
  if (alphabet.isEmpty) return lower;
  return String.fromCharCodes([
    for (final unit in lower.runes)
      switch (alphabet.indexOf(String.fromCharCode(unit))) {
        -1 => unit,
        final place => 0xE000 + place,
      },
  ]);
}

/// The entries of [entries] that [query] finds, as it is typed (the owner, 2026-11-18): one letter finds the names that
/// start with it; more find the names or definitions holding every word of [query] as the search matches words, those
/// whose name starts with the query first. All of them for an empty query.
List<GlossaryEntry> glossaryFind(List<GlossaryEntry> entries, String query, String lang) {
  final typed = normalise(query.trim(), lang);
  if (typed.isEmpty) return entries;
  final terms = searchTerms(query, lang);
  if (terms.isEmpty) {
    return [
      for (final entry in entries)
        if (entry.sortKey.startsWith(typed)) entry,
    ];
  }
  final found = [
    for (final entry in entries)
      if (_holdsAll('${entry.name} ${entry.first.definitionText}', terms, lang)) entry,
  ];
  return [
    ...found.where((entry) => entry.sortKey.startsWith(typed)),
    ...found.where((entry) => !entry.sortKey.startsWith(typed)),
  ];
}

bool _holdsAll(String text, List<String> terms, String lang) {
  final words = [for (final word in tokenize(text)) normalise(word, lang)];
  return terms.every((term) => words.any((word) => word.startsWith(term)));
}
