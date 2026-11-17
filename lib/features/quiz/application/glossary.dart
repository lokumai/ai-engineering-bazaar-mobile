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

  /// Whether [key] is the key of one of its terms in [track].
  bool holds(Track track, String? key) => terms.any((term) => termKey(track, term.moduleKey, term.index) == key);

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
  ]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
}

/// The entries of [entries] whose name or definition holds every word of [query], as the search matches words;
/// all of them for an empty query.
List<GlossaryEntry> glossaryFind(List<GlossaryEntry> entries, String query, String lang) {
  final terms = searchTerms(query, lang);
  if (terms.isEmpty) return entries;
  return [
    for (final entry in entries)
      if (_holdsAll('${entry.name} ${entry.first.definitionText}', terms, lang)) entry,
  ];
}

bool _holdsAll(String text, List<String> terms, String lang) {
  final words = [for (final word in tokenize(text)) normalise(word, lang)];
  return terms.every((term) => words.any((word) => word.startsWith(term)));
}
