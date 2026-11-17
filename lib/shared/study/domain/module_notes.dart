/// What Practice takes from a module's document (plan 13.7, 13.8): its Key Terms and its Summary, as the document
/// carries them, and its quiz. Nothing is written for the app: both are sections the web's modules already end with.
library;

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/plain_text.dart';

/// One entry of a module's Key Terms (For Everyone: Words You Now Know): `**term**: definition`.
final class GlossaryTerm extends Equatable {
  const GlossaryTerm({
    required this.moduleKey,
    required this.index,
    required this.name,
    required this.forms,
    required this.definition,
  });

  /// The module whose Key Terms hold it.
  final String moduleKey;

  /// Its 0-based place in that list.
  final int index;

  /// The entry's words before its definition, as the list prints them: `Recall and precision`,
  /// `Working memory (short-term memory)`.
  final String name;

  /// The words the entry sets in bold, which a module's text may use: `Recall`, `precision`.
  final List<String> forms;

  /// The definition, the words after the first `: `.
  final List<Inline> definition;

  /// [definition] as plain text.
  String get definitionText => inlineText(definition).trim();

  @override
  List<Object?> get props => [moduleKey, index, name, forms, definition];
}

/// A section of a module's text, a level-2 or level-3 heading and the words under it, up to the next such heading.
final class NoteSection extends Equatable {
  const NoteSection({required this.id, required this.title, required this.text});

  /// The heading's id, to open the module at it.
  final String id;

  /// The heading's words.
  final String title;

  /// The words under it, as a reader meets them.
  final String text;

  @override
  List<Object?> get props => [id, title, text];
}

/// A module's Key Terms, Summary and quiz, as Practice uses them, and the sections that teach it.
final class ModuleNotes extends Equatable {
  const ModuleNotes({
    required this.moduleKey,
    this.lang = 'en',
    this.sections = const [],
    this.terms = const [],
    this.termsHeading,
    this.summary = const [],
    this.summaryHeading,
    this.quiz = const [],
  });

  final String moduleKey;

  /// The language the document is written in: the reader's, or English where the module is not translated.
  final String lang;

  /// The sections that teach the module, in order: every one but the Key Terms, the Summary and the References, which
  /// restate it, and their subsections.
  final List<NoteSection> sections;

  /// The Key Terms, in the document's order; empty when the module has none.
  final List<GlossaryTerm> terms;

  /// The id of the Key Terms heading, to open the module at it.
  final String? termsHeading;

  /// The Summary's blocks, its paragraphs and lists; empty when the module has none.
  final List<Block> summary;

  /// The id of the Summary heading.
  final String? summaryHeading;

  /// The module's quiz; empty when it has none.
  final List<QuizItem> quiz;

  @override
  List<Object?> get props => [moduleKey, lang, sections, terms, termsHeading, summary, summaryHeading, quiz];
}

/// The notes of [doc], the module [moduleKey].
///
/// The sections are found by their place and shape, not by their name, which differs by track and language (Key Terms,
/// Words You Now Know, Temel Terimler, ...): a module ends with its Key Terms, its Summary and its References, so the
/// Key Terms are the last of the last three level-2 headings that is followed by a list whose every item starts with
/// a term in bold, then `: ` and its definition. A list of that shape earlier in a module is part of its text. The
/// Summary is the heading right after the Key Terms, when one follows that is not the last (the References).
ModuleNotes notesOf(String moduleKey, ModuleDoc doc) {
  final body = doc.body ?? const <Block>[];
  final headings = [
    for (final (position, block) in body.indexed)
      if (block case HeadingBlock(depth: 2)) position,
  ];
  final last = headings.length > 3 ? headings.sublist(headings.length - 3) : headings;
  int? termsAt;
  List<GlossaryTerm> terms = const [];
  for (final position in last.reversed) {
    final next = position + 1 < body.length ? body[position + 1] : null;
    if (next is ListBlock) {
      if (_termsOf(moduleKey, next) case final found?) {
        termsAt = position;
        terms = found;
        break;
      }
    }
  }
  int? summaryAt;
  if (termsAt != null) {
    final next = headings.indexOf(termsAt) + 1;
    if (next < headings.length - 1) summaryAt = headings[next];
  }
  final left = {?termsAt, ?summaryAt, if (headings.isNotEmpty) headings.last};
  return ModuleNotes(
    moduleKey: moduleKey,
    lang: doc.lang,
    sections: _teaching(body, left),
    terms: terms,
    termsHeading: termsAt == null ? null : (body[termsAt] as HeadingBlock).id,
    summary: summaryAt == null ? const [] : _sectionAt(body, summaryAt),
    summaryHeading: summaryAt == null ? null : (body[summaryAt] as HeadingBlock).id,
    quiz: doc.quiz ?? const [],
  );
}

/// The sections of [body] under its level-2 and level-3 headings, leaving out the level-2 sections at the places
/// [left] and their subsections; a section with no words is left out too.
List<NoteSection> _teaching(List<Block> body, Set<int> left) {
  final sections = <NoteSection>[];
  HeadingBlock? open;
  var blocks = <Block>[];
  void close() {
    final text = plainOf(blocks);
    if (open case final heading? when text.isNotEmpty) {
      sections.add(NoteSection(id: heading.id, title: squashSpace(inlineText(heading.inlines)), text: text));
    }
  }

  var skipping = false;
  for (final (position, block) in body.indexed) {
    if (block case HeadingBlock(:final depth) when depth <= 3) {
      close();
      if (depth == 2) skipping = left.contains(position);
      open = skipping ? null : block;
      blocks = [];
    } else {
      blocks.add(block);
    }
  }
  close();
  return sections;
}

/// The blocks under the heading at [position], up to the next heading of its level or above.
List<Block> _sectionAt(List<Block> body, int position) {
  final depth = (body[position] as HeadingBlock).depth;
  return [
    for (final block in body.skip(position + 1).takeWhile((block) => block is! HeadingBlock || block.depth > depth))
      block,
  ];
}

/// The terms of [list] when every item is `**term**: definition`, else null.
List<GlossaryTerm>? _termsOf(String moduleKey, ListBlock list) {
  if (list.items.isEmpty) return null;
  final terms = <GlossaryTerm>[];
  for (final (index, item) in list.items.indexed) {
    final term = switch (item.blocks) {
      [ParagraphBlock(:final inlines)] => _termOf(moduleKey, index, inlines),
      _ => null,
    };
    if (term == null) return null;
    terms.add(term);
  }
  return terms;
}

/// `**term**: definition`, or `**one** and **two**: definition`, or `**term** (other name): definition`.
GlossaryTerm? _termOf(String moduleKey, int index, List<Inline> inlines) {
  if (inlines.firstOrNull is! StrongInline) return null;
  final head = <Inline>[];
  for (final (position, inline) in inlines.indexed) {
    if (inline case TextInline(:final text) when text.contains(': ')) {
      final cut = text.indexOf(': ');
      final name = squashSpace(inlineText([...head, TextInline(text: text.substring(0, cut))]));
      final rest = text.substring(cut + 2);
      final definition = [if (rest.trim().isNotEmpty) TextInline(text: rest.trimLeft()), ...inlines.skip(position + 1)];
      final forms = [
        for (final part in head.whereType<StrongInline>())
          if (squashSpace(inlineText(part.inlines)) case final form when form.isNotEmpty) form,
      ];
      if (name.isEmpty || forms.isEmpty || definition.isEmpty) return null;
      return GlossaryTerm(moduleKey: moduleKey, index: index, name: name, forms: forms, definition: definition);
    }
    head.add(inline);
  }
  return null;
}
