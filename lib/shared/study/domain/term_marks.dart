/// Where a module's text uses a term of the glossary (plan 13.9): the first time in each section, so the reader can tap
/// it for its definition. Only plain text is marked: never code, a heading, a table, a link or bold text, and never the
/// Key Terms or the References themselves. Marking every use would tire the reader (the owner).
library;

import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// One use of [term] in a text, from [start] to [end].
final class TermMark extends Equatable {
  const TermMark({required this.start, required this.end, required this.term});

  final int start;
  final int end;
  final GlossaryTerm term;

  @override
  List<Object?> get props => [start, end, term];
}

/// The marks of each text of [body], by the text inline itself (by identity: two texts alike are two places).
///
/// [terms] are tried in order, so a module's own terms go first; a longer form is tried before a shorter one it holds,
/// and a form is matched whole, in any case. [skip] names the level-2 sections left unmarked, with their subsections.
Map<TextInline, List<TermMark>> termMarks(List<Block> body, List<GlossaryTerm> terms, {Set<String> skip = const {}}) {
  final forms = <(String, GlossaryTerm)>[];
  final taken = <String>{};
  for (final term in terms) {
    for (final form in term.forms) {
      final lower = _fold(form);
      if (lower.length >= 2 && taken.add(lower)) forms.add((lower, term));
    }
  }
  forms.sort((a, b) => b.$1.length.compareTo(a.$1.length));
  final marks = LinkedHashMap<TextInline, List<TermMark>>.identity();
  if (forms.isEmpty) return marks;

  var seen = <GlossaryTerm>{};
  var skipping = false;

  void markText(TextInline inline) {
    final lower = _fold(inline.text);
    final found = <TermMark>[];
    for (final (form, term) in forms) {
      if (seen.contains(term)) continue;
      for (var at = lower.indexOf(form); at >= 0; at = lower.indexOf(form, at + 1)) {
        final end = at + form.length;
        if (!_wordAt(lower, at, end) || found.any((mark) => mark.start < end && at < mark.end)) continue;
        found.add(TermMark(start: at, end: end, term: term));
        seen.add(term);
        break;
      }
    }
    if (found.isNotEmpty) marks[inline] = found..sort((a, b) => a.start.compareTo(b.start));
  }

  void markInlines(List<Inline> inlines) {
    for (final inline in inlines) {
      if (inline is TextInline) markText(inline);
      if (inline is EmphasisInline) markInlines(inline.inlines);
    }
  }

  void markBlocks(List<Block> blocks) {
    for (final block in blocks) {
      switch (block) {
        case HeadingBlock(:final depth, :final id):
          if (depth == 2) {
            seen = {};
            skipping = skip.contains(id);
          } else if (depth == 3) {
            seen = {};
          }
        case _ when skipping:
          break;
        case ParagraphBlock(:final inlines):
          markInlines(inlines);
        case ListBlock(:final items):
          for (final item in items) {
            markBlocks(item.blocks);
          }
        case QuoteBlock(:final blocks) || CalloutBlock(:final blocks):
          markBlocks(blocks);
        default:
          break;
      }
    }
  }

  markBlocks(body);
  return marks;
}

/// The sentence of a module that uses a term, and where in it the term stands (plan 13.3: a term card shows it, so the
/// reader meets the term as the module put it).
final class TermUsage extends Equatable {
  const TermUsage({required this.text, required this.start, required this.end});

  final String text;
  final int start;
  final int end;

  @override
  List<Object?> get props => [text, start, end];
}

/// The longest a usage runs; a longer sentence is cut around the term, with an ellipsis where it was cut.
const usageLength = 200;

/// The first sentence of the sections that teach [notes]' module (never its Key Terms, Summary or References) that
/// uses one of [term]'s forms as a whole word, in any case; null when none does. It is the module's own text, cut to
/// [usageLength] around the term when longer.
TermUsage? termUsage(ModuleNotes notes, GlossaryTerm term) {
  final forms = {
    for (final form in term.forms)
      if (form.length >= 2) _fold(form),
  }.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final section in notes.sections) {
    for (final part in section.text.split(_sentenceEnd)) {
      final sentence = part.trim();
      final lower = _fold(sentence);
      for (final form in forms) {
        for (var at = lower.indexOf(form); at >= 0; at = lower.indexOf(form, at + 1)) {
          if (_wordAt(lower, at, at + form.length)) return _cut(sentence, at, at + form.length);
        }
      }
    }
  }
  return null;
}

/// A sentence ends at a full stop, a question or an exclamation mark, Persian's question mark among them, before a space.
final _sentenceEnd = RegExp(r'(?<=[.!?؟])\s+');

TermUsage _cut(String sentence, int start, int end) {
  if (sentence.length <= usageLength) return TermUsage(text: sentence, start: start, end: end);
  var from = (start - (usageLength - (end - start)) ~/ 2).clamp(0, sentence.length - usageLength);
  var to = from + usageLength;
  // Whole words only: the cut moves in to the nearest space, never past the term.
  if (from > 0) {
    final space = sentence.indexOf(' ', from);
    if (space >= 0 && space < start) from = space + 1;
  }
  if (to < sentence.length) {
    final space = sentence.lastIndexOf(' ', to);
    if (space > end) to = space;
  }
  final head = from > 0 ? '… ' : '';
  final tail = to < sentence.length ? ' …' : '';
  return TermUsage(
    text: '$head${sentence.substring(from, to)}$tail',
    start: start - from + head.length,
    end: end - from + head.length,
  );
}

/// Whether [text] from [start] to [end] is a whole word: no letter or digit just before or after it.
bool _wordAt(String text, int start, int end) =>
    (start == 0 || !_letter.hasMatch(text[start - 1])) && (end == text.length || !_letter.hasMatch(text[end]));

final _letter = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// [text] in lower case, each character kept to its own length so a place in it is the same place in [text]: Turkish
/// İ, which lower-cases to two characters, becomes i.
String _fold(String text) {
  final folded = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final lower = char.toLowerCase();
    folded.write(lower.length == char.length ? lower : (char == 'İ' ? 'i' : char));
  }
  return folded.toString();
}
