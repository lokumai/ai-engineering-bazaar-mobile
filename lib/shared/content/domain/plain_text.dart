/// A module document's words as a reader meets them, without its markup: the catalog's search matches them and Home's
/// daily card quotes them, so the two read a document alike.
library;

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';

/// The words of [blocks] a reader meets, one space between blocks and between list items (web `plain`).
String plainOf(List<Block> blocks) => squashSpace(blocks.map(_blockText).join(' '));

String _blockText(Block block) => switch (block) {
  ParagraphBlock(:final inlines) => inlineText(inlines),
  HeadingBlock(:final inlines) => inlineText(inlines),
  ListBlock(:final items) => items.map((item) => item.blocks.map(_blockText).join(' ')).join(' '),
  QuoteBlock(:final blocks) => blocks.map(_blockText).join(' '),
  CalloutBlock(:final title, :final blocks) => [
    if (title != null) inlineText(title),
    ...blocks.map(_blockText),
  ].join(' '),
  TableBlock(:final head, :final rows) => [
    for (final cell in head) inlineText(cell.inlines),
    for (final row in rows)
      for (final cell in row) inlineText(cell.inlines),
  ].join(' '),
  _ => '',
};

/// The text of [inlines] as read.
String inlineText(List<Inline> inlines) => inlines.map(_inlineText).join();

String _inlineText(Inline inline) => switch (inline) {
  TextInline(:final text) => text,
  CodeInline(:final text) => text,
  BreakInline() => ' ',
  StrongInline(:final inlines) => inlineText(inlines),
  EmphasisInline(:final inlines) => inlineText(inlines),
  DeleteInline(:final inlines) => inlineText(inlines),
  LinkInline(:final inlines) => inlineText(inlines),
  _ => '',
};

/// [text] with each run of white space made one space, and none at either end.
String squashSpace(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// The sections that list or recap rather than teach: a list of links, and a module's own recap (web D99). The search
/// ranks them low and the daily card leaves them out.
const recapSections = {'references', 'summary', 'kaynaklar', 'özet', 'منابع', 'خلاصه'};
