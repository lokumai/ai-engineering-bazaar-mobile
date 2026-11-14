import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';

/// A course module's prose as the pocket model reads it (plan 9.6): sentences of lower-case words, each ending where
/// the module's sentence ends. Its prose is its paragraphs, headings, lists, quotes and callouts; its code, tables,
/// images and diagrams are left out, as a reader's eye passes over them. A sentence that means nothing without what is
/// left out, or that speaks of the course rather than of its subject, is left out too ([isAside]). After the prose come its quiz's questions,
/// each followed by its right answer as a sentence of its own; the wrong options are never read. A planned module, with
/// no body, has none.
///
/// The model only counts which word follows which in them; it shows none of the module's facts as facts.
List<List<String>> sentencesOf(ModuleDoc doc) => textOf(doc).sentences;

/// A module's text as the pocket model reads it: its [sentences], and the index of the first sentence of each of its
/// [sections], in order, the first always 0 (plan 9.10). A section is what stands under one of its headings, so it
/// keeps to one narrow subject; its quiz is a section of its own.
typedef ModuleText = ({List<List<String>> sentences, List<int> sections});

/// [sentences] as one section.
ModuleText oneSection(List<List<String>> sentences) => (sentences: sentences, sections: const [0]);

/// [doc]'s text ([sentencesOf]) and where its sections start. A heading starts a section once the one before it has
/// [shortestSection] sentences; a shorter one runs on under the next heading.
ModuleText textOf(ModuleDoc doc) {
  final body = doc.body;
  if (body == null) return (sentences: const [], sections: const [0]);
  final sentences = <List<String>>[];
  final sections = [0];
  void section() {
    if (sentences.length - sections.last >= shortestSection) sections.add(sentences.length);
  }

  void prose(String text) {
    for (final part in text.split(_sentenceEnd)) {
      if (isAside(part, doc.lang)) continue;
      final words = wordsOf(part, doc.lang);
      // A sentence too short to teach a pair is left out; a long one is cut, as the model's own are short.
      for (var at = 0; at < words.length; at += _longest) {
        final piece = words.sublist(at, (at + _longest).clamp(0, words.length));
        // A row of numbers, as a worked sum or a score, is not a sentence to learn from.
        final numbers = piece.where((word) => word.contains(_digit)).length;
        if (piece.length >= 3 && numbers * 3 <= piece.length) sentences.add(piece);
      }
    }
  }

  void visit(Block block) {
    switch (block) {
      case HeadingBlock(:final inlines):
        section();
        prose(_inlineText(inlines));
      case ParagraphBlock(:final inlines):
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
  section();
  for (final item in doc.quiz ?? const <QuizItem>[]) {
    prose(_withoutCode(item.question));
    if (item.answer >= 0 && item.answer < item.options.length) prose(_withoutCode(item.options[item.answer]));
  }
  // A last section too short to keep to runs on from the one before it.
  if (sections.length > 1 && sentences.length - sections.last < shortestSection) sections.removeLast();
  return (sentences: sentences, sections: sections);
}

/// The fewest sentences a section has.
const shortestSection = 4;

/// The words of [text] in [language], lower case (Turkish dotted and dotless i kept apart), with the marks between
/// them taken out; a word's own apostrophe, hyphen or zero-width non-joiner stays.
List<String> wordsOf(String text, String language) {
  final lower = _lower(text, language);
  return [
    for (final word in lower.split(_between))
      if (word.replaceAll(_edges, '') case final clean when clean.isNotEmpty) clean,
  ];
}

const _longest = 24;

final _digit = RegExp(r'\p{N}', unicode: true);

/// Whether the sentence [text] in [language] is an aside the robot does not learn from (the owner, 2026-11-14): one
/// that points to another module or out of the course (a link), one that leads into a list, a table, a picture or
/// code it does not read (it ends in a colon), or one that speaks of a figure, of what stands above or below it, or of
/// the course itself ("this module", "we said earlier").
bool isAside(String text, String language) {
  final sentence = text.trim();
  if (sentence.contains(_link) || sentence.endsWith(':') || sentence.endsWith('\uff1a')) return true;
  return (_asides[language] ?? _asides['en']!).hasMatch(_lower(sentence, language));
}

/// [text] in lower case. In Turkish an I is a dotless ı and an İ a dotted i, but not in a name in capitals from
/// English (NVIDIA, AI, LLM), which stays as English has it: nvidia, not nvıdıa.
String _lower(String text, String language) {
  if (language != 'tr') return text.toLowerCase();
  return text
      .replaceAllMapped(_capitals, (match) => match[0]!.toLowerCase())
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase();
}

/// Two or more capitals of the English alphabet together, a name or an abbreviation.
final _capitals = RegExp(r'\b[A-Z]{2,}[A-Za-z]*');

/// What a link's words are marked with, so the sentence it stands in is known for an aside.
const _link = '\u0001';

/// The words of an aside, by language: a figure or a diagram, what stands above or below, and the course speaking of
/// itself. Each was checked against the course's own sentences, so a word that also means something else ("şekilde",
/// in a manner; "بالا", high) is matched only in the phrase that points.
final Map<String, RegExp> _asides = {
  'en': RegExp(
    r'\b(figure|diagram|above|below|this module|next module|previous module|this series|this course|earlier|'
    r'we (said|saw|covered|described|looked at|learned)|you learned)\b',
  ),
  'tr': RegExp(
    r'(yukarıda|aşağıda|diyagram|şekil \d|bu modül|sonraki modül|önceki modül|seride|serideki|daha önce '
    r'(anlat|gör|söyle|bahset)|demiştik|görmüştük|tablodaki|tabloda)',
  ),
  'fa': RegExp(
    r'(شکل بالا|شکل زیر|نمودار|جدول بالا|بالاتر|پایین\u200cتر|این درس|این مجموعه|درس بعدی|درس قبلی|'
    r'گفتیم|دیدیم)',
  ),
};

final _sentenceEnd = RegExp(r'(?<=[.!?\u061f\u2026])\s+|\n+');

/// Anything that is not a letter, a digit, an apostrophe, a hyphen or a zero-width non-joiner.
final _between = RegExp(r"[^\p{L}\p{N}\p{M}'\u2019\-\u200c]+", unicode: true);

/// Apostrophes, hyphens and joiners at a word's ends.
final _edges = RegExp(r"^['\u2019\-\u200c]+|['\u2019\-\u200c]+$");

/// A quiz's plain text with its `code` spans taken out, as inline code is in the prose.
String _withoutCode(String text) => text.replaceAll(_codeSpan, ' ');

final _codeSpan = RegExp('`[^`]*`');

String _inlineText(List<Inline> inlines) => inlines.map(_inline).join();

String _inline(Inline inline) => switch (inline) {
  TextInline(:final text) => text,
  BreakInline() => ' ',
  StrongInline(:final inlines) ||
  EmphasisInline(:final inlines) ||
  DeleteInline(:final inlines) => _inlineText(inlines),
  // A link's words are marked: the sentence points elsewhere ([isAside]); a link within the page is read.
  LinkInline(:final target, :final inlines) =>
    target is AnchorTarget ? _inlineText(inlines) : '$_link${_inlineText(inlines)}',
  // Inline code is a name in code, not a word of the prose.
  _ => ' ',
};
