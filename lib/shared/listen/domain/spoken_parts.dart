import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/plain_text.dart';

/// One stretch of a module read aloud (plan 15.1): a block of its body, by its place in the body, and the words said.
final class SpokenPart extends Equatable {
  const SpokenPart({required this.block, required this.text});

  /// The block's place in the module's body, which the page marks while it is read.
  final int block;

  final String text;

  @override
  List<Object?> get props => [block, text];
}

/// The ids the References section takes in the three languages: reading stops at it, a list of links read aloud being
/// of no use.
const _references = {'references', 'kaynaklar', 'منابع'};

/// The parts of [body] a voice reads, in order (plan 15.1): its headings, paragraphs, lists, quotes and callouts, each
/// block one part; code, tables, pictures, diagrams and rules are passed over, and reading stops at the References. A
/// heading, and each item of a list, ends with a full stop where it has none, so the voice pauses after it.
List<SpokenPart> spokenParts(List<Block> body) {
  final end = body.indexWhere(
    (block) => block is HeadingBlock && block.depth == 2 && _references.contains(block.id.toLowerCase()),
  );
  return [
    for (final (index, block) in body.take(end < 0 ? body.length : end).indexed)
      if (_said(block) case final text? when text.isNotEmpty) SpokenPart(block: index, text: text),
  ];
}

String? _said(Block block) => switch (block) {
  ParagraphBlock() || QuoteBlock() => plainOf([block]),
  HeadingBlock(:final inlines) => _stopped(squashSpace(inlineText(inlines))),
  ListBlock(:final items) => [
    for (final item in items)
      if (_stopped(plainOf(item.blocks)) case final text when text.isNotEmpty) text,
  ].join(' '),
  CalloutBlock(:final title, :final blocks) => [
    if (title != null) _stopped(squashSpace(inlineText(title))),
    plainOf(blocks),
  ].where((text) => text.isNotEmpty).join(' '),
  CodeBlock() || TableBlock() || ImageBlock() || DiagramBlock() || RuleBlock() || UnknownBlock() => null,
};

/// [text] with a full stop at its end when it ends without a mark that makes a voice pause.
String _stopped(String text) => text.isEmpty || RegExp(r'[.!?:;…؟。]$').hasMatch(text) ? text : '$text.';
