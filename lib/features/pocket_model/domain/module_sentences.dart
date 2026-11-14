import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';

/// A course module's prose as the pocket model reads it (plan 9.6): sentences of lower-case words, each ending where
/// the module's sentence ends. Its prose is its paragraphs, headings, lists, quotes and callouts; its code, tables,
/// images and diagrams are left out, as a reader's eye passes over them. A planned module, with no body, has none.
///
/// The model only counts which word follows which in them; it shows none of the module's facts as facts.
List<List<String>> sentencesOf(ModuleDoc doc) {
  final body = doc.body;
  if (body == null) return const [];
  final sentences = <List<String>>[];
  void prose(String text) {
    for (final part in text.split(_sentenceEnd)) {
      final words = wordsOf(part, doc.lang);
      // A sentence too short to teach a pair is left out; a long one is cut, as the model's own are short.
      for (var at = 0; at < words.length; at += _longest) {
        final piece = words.sublist(at, (at + _longest).clamp(0, words.length));
        if (piece.length >= 3) sentences.add(piece);
      }
    }
  }

  void visit(Block block) {
    switch (block) {
      case ParagraphBlock(:final inlines) || HeadingBlock(:final inlines):
        prose(_inlineText(inlines));
      case ListBlock(:final items):
        for (final item in items) {
          item.blocks.forEach(visit);
        }
      case QuoteBlock(:final blocks):
        blocks.forEach(visit);
      case CalloutBlock(:final title, :final blocks):
        if (title != null) prose(_inlineText(title));
        blocks.forEach(visit);
      default:
    }
  }

  body.forEach(visit);
  return sentences;
}

/// The words of [text] in [language], lower case (Turkish dotted and dotless i kept apart), with the marks between
/// them taken out; a word's own apostrophe, hyphen or zero-width non-joiner stays.
List<String> wordsOf(String text, String language) {
  final lower = language == 'tr' ? text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase() : text.toLowerCase();
  return [
    for (final word in lower.split(_between))
      if (word.replaceAll(_edges, '') case final clean when clean.isNotEmpty) clean,
  ];
}

const _longest = 24;

final _sentenceEnd = RegExp(r'(?<=[.!?\u061f\u2026])\s+|\n+');

/// Anything that is not a letter, a digit, an apostrophe, a hyphen or a zero-width non-joiner.
final _between = RegExp(r"[^\p{L}\p{N}\p{M}'\u2019\-\u200c]+", unicode: true);

/// Apostrophes, hyphens and joiners at a word's ends.
final _edges = RegExp(r"^['\u2019\-\u200c]+|['\u2019\-\u200c]+$");

String _inlineText(List<Inline> inlines) => inlines.map(_inline).join();

String _inline(Inline inline) => switch (inline) {
  TextInline(:final text) => text,
  BreakInline() => ' ',
  StrongInline(:final inlines) ||
  EmphasisInline(:final inlines) ||
  DeleteInline(:final inlines) => _inlineText(inlines),
  LinkInline(:final inlines) => _inlineText(inlines),
  // Inline code is a name in code, not a word of the prose.
  _ => ' ',
};
