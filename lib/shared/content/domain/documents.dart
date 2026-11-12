import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';

/// A level document (`api/v1/levels/<slug>.json`), parsed by `ContentParser.parseLevelDoc`.
final class LevelDoc extends Equatable {
  const LevelDoc({required this.slug, required this.title, required this.blocks});

  final String slug;
  final String title;
  final List<Block> blocks;

  @override
  List<Object?> get props => [slug, title, blocks];
}

/// The About page's story, `api/v1/story/<lang>.json` (web D115, D125), parsed by `ContentParser.parseStoryDoc`: the
/// web's `mini-courses/STORY.md` as the site's About page reads it, in plain strings.
final class StoryDoc extends Equatable {
  const StoryDoc({
    required this.lang,
    required this.dir,
    required this.title,
    required this.stalls,
    required this.motto,
  });

  final String lang;
  final TextDir dir;

  /// The story's own heading, or null when it has none.
  final String? title;

  /// One per section of the story, in order.
  final List<StoryStall> stalls;
  final StoryMotto? motto;

  @override
  List<Object?> get props => [lang, dir, title, stalls, motto];
}

/// One section of the story: its heading and its paragraphs.
final class StoryStall extends Equatable {
  const StoryStall({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;

  @override
  List<Object?> get props => [heading, paragraphs];
}

/// The story's closing motto: what introduces it and the quotation, one sentence per line.
final class StoryMotto extends Equatable {
  const StoryMotto({required this.lead, required this.lines});

  final String lead;
  final List<String> lines;

  @override
  List<Object?> get props => [lead, lines];
}

/// A module document in one track and language, parsed by `ContentParser.parseModuleDoc`.
///
/// [body] is null exactly when [draft] is not: a written module has a body, an unwritten one a draft.
final class ModuleDoc extends Equatable {
  const ModuleDoc({
    required this.key,
    required this.track,
    required this.lang,
    required this.dir,
    required this.title,
    this.words,
    required this.objectives,
    this.translatedObjectives,
    required this.prerequisites,
    required this.previous,
    required this.next,
    required this.toc,
    required this.body,
    required this.draft,
    required this.quiz,
  });

  /// The module key, `<level>/<module>`.
  final String key;
  final Track track;
  final String lang;
  final TextDir dir;

  /// The title in this document's track and language.
  final String title;

  /// The words its web page prints under the title (web D128); null on a draft and in a document from before it.
  final int? words;

  /// The objectives, always in English; empty on a draft.
  final List<String> objectives;

  /// The objectives in the document's own language, as its translation declares them (web D124); null in English and
  /// where the translation declares none.
  final List<String>? translatedObjectives;

  /// The objectives the reader shows: the translated ones when the document has them, else the English (web M19).
  List<String> get shownObjectives => translatedObjectives ?? objectives;
  final List<Ref> prerequisites;
  final Ref? previous;
  final Ref? next;
  final List<TocEntry> toc;
  final List<Block>? body;
  final Draft? draft;
  final List<QuizItem>? quiz;

  @override
  List<Object?> get props => [
    key,
    track,
    lang,
    dir,
    title,
    words,
    objectives,
    translatedObjectives,
    prerequisites,
    previous,
    next,
    toc,
    body,
    draft,
    quiz,
  ];

  /// Names the document only, so a logged state never prints a whole module.
  @override
  String toString() => 'ModuleDoc($key, ${track.id}, $lang)';
}

enum TextDir { ltr, rtl }

/// One entry of a module's table of contents.
final class TocEntry extends Equatable {
  const TocEntry({required this.id, required this.text, required this.depth, required this.mark});

  /// The id of the heading it names.
  final String id;
  final String text;

  /// 2 or 3.
  final int depth;

  /// The Roman numeral split off the heading, when it has one.
  final String? mark;

  @override
  List<Object?> get props => [id, text, depth, mark];
}

/// The plan of a module that is not written in its track yet.
final class Draft extends Equatable {
  const Draft({required this.summary, required this.parts, required this.written});

  final String? summary;

  /// The planned parts, in order.
  final List<String> parts;

  /// The sections already written, when there are any.
  final List<Block>? written;

  @override
  List<Object?> get props => [summary, parts, written];
}

final class QuizItem extends Equatable {
  const QuizItem({required this.question, required this.options, required this.answer, required this.explain});

  final String question;
  final List<String> options;

  /// The index of the right option in [options].
  final int answer;
  final String explain;

  @override
  List<Object?> get props => [question, options, answer, explain];
}

/// A reference to another module (a prerequisite, the previous or the next module).
final class Ref extends Equatable {
  const Ref({
    required this.key,
    required this.number,
    required this.title,
    required this.drawn,
    required this.track,
    required this.lang,
  });

  final String key;
  final int number;

  /// The English For Engineers title.
  final String title;

  /// Whether the module is written in the track the reference lands in.
  final bool drawn;

  /// The track the reference lands in; null for a track this app does not know, which makes the reference not
  /// openable (Decision A23).
  final Track? track;
  final String lang;

  @override
  List<Object?> get props => [key, number, title, drawn, track, lang];
}

/// Where a link goes (`LinkTarget.kind` in the bundle).
sealed class LinkTarget extends Equatable {
  const LinkTarget();
}

final class ModuleTarget extends LinkTarget {
  const ModuleTarget({required this.key, required this.track, required this.lang, required this.fragment});

  final String key;
  final Track track;
  final String lang;

  /// A heading id in the target document, already decoded and without `#`.
  final String? fragment;

  @override
  List<Object?> get props => [key, track, lang, fragment];
}

final class ExternalTarget extends LinkTarget {
  const ExternalTarget({required this.url});

  /// An `http` or `https` address.
  final String url;

  @override
  List<Object?> get props => [url];
}

/// A heading in the same document.
final class AnchorTarget extends LinkTarget {
  const AnchorTarget({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// The course catalog.
final class CatalogTarget extends LinkTarget {
  const CatalogTarget();

  @override
  List<Object?> get props => const [];
}

/// A target kind this app does not know, or a module target in a track it does not know; its inlines are drawn as
/// plain text (Decision A23).
final class UnknownTarget extends LinkTarget {
  const UnknownTarget({required this.kind});

  final String kind;

  @override
  List<Object?> get props => [kind];
}

/// A block of a document body (`Block.type` in the bundle).
sealed class Block extends Equatable {
  const Block();
}

final class ParagraphBlock extends Block {
  const ParagraphBlock({required this.inlines, required this.lead});

  final List<Inline> inlines;

  /// Drawn with the lead type step; false when the bundle does not say so.
  final bool lead;

  @override
  List<Object?> get props => [inlines, lead];
}

final class HeadingBlock extends Block {
  const HeadingBlock({required this.depth, required this.id, required this.mark, required this.inlines});

  /// 2, 3 or 4.
  final int depth;

  /// The anchor and table of contents target; may be non-ASCII.
  final String id;

  /// The Roman numeral split off the heading, when it has one.
  final String? mark;
  final List<Inline> inlines;

  @override
  List<Object?> get props => [depth, id, mark, inlines];
}

final class ListBlock extends Block {
  const ListBlock({required this.ordered, required this.start, required this.items});

  final bool ordered;

  /// The first number of an ordered list, when it is not 1.
  final int? start;
  final List<ListItem> items;

  @override
  List<Object?> get props => [ordered, start, items];
}

final class ListItem extends Equatable {
  const ListItem({required this.checked, this.taskIndex, required this.blocks});

  /// The task box of a task item; null when the item is not a task.
  final bool? checked;

  /// The task item's place in the module's one checklist, from 0 (web D129): the key of its tick in the record's
  /// `checklist`. Null when the item is not a task, and in a document from before the web added it.
  final int? taskIndex;
  final List<Block> blocks;

  @override
  List<Object?> get props => [checked, taskIndex, blocks];
}

final class QuoteBlock extends Block {
  const QuoteBlock({required this.label, required this.blocks});

  final String? label;
  final List<Block> blocks;

  @override
  List<Object?> get props => [label, blocks];
}

enum CalloutKind { note, tip, important, warning, caution }

final class CalloutBlock extends Block {
  const CalloutBlock({required this.kind, required this.title, required this.blocks, required this.action});

  final CalloutKind kind;
  final List<Inline>? title;
  final List<Block> blocks;
  final CalloutAction? action;

  @override
  List<Object?> get props => [kind, title, blocks, action];
}

/// The button of a callout.
final class CalloutAction extends Equatable {
  const CalloutAction({required this.target, required this.inlines});

  final LinkTarget target;
  final List<Inline> inlines;

  @override
  List<Object?> get props => [target, inlines];
}

final class CodeBlock extends Block {
  const CodeBlock({required this.language, required this.lines});

  /// Never empty.
  final String language;

  /// One list of tokens per line; an empty line is an empty list.
  final List<List<CodeToken>> lines;

  @override
  List<Object?> get props => [language, lines];
}

final class CodeToken extends Equatable {
  const CodeToken({required this.text, required this.role, required this.bold});

  final String text;

  /// The colour role; an open set, null for a plain token.
  final String? role;
  final bool bold;

  @override
  List<Object?> get props => [text, role, bold];
}

enum CellAlign { left, center, right }

final class TableBlock extends Block {
  const TableBlock({
    required this.number,
    required this.title,
    required this.rowHeaders,
    required this.align,
    required this.head,
    required this.rows,
  });

  /// The caption number as the bundle writes it (`4`, `6.1`).
  final String number;
  final String? title;

  /// The first cell of every body row is a row header.
  final bool rowHeaders;

  /// One entry per head cell; null means the default.
  final List<CellAlign?> align;
  final List<Cell> head;
  final List<List<Cell>> rows;

  @override
  List<Object?> get props => [number, title, rowHeaders, align, head, rows];
}

final class Cell extends Equatable {
  const Cell({required this.inlines});

  final List<Inline> inlines;

  @override
  List<Object?> get props => [inlines];
}

final class ImageBlock extends Block {
  const ImageBlock({
    required this.number,
    required this.title,
    required this.note,
    required this.src,
    required this.alt,
    required this.width,
    required this.height,
  });

  /// The caption number as the bundle writes it.
  final String number;
  final String? title;

  /// A sentence drawn on its own line below the caption.
  final String? note;

  /// A site path listed in the index's `images`.
  final String src;
  final String alt;

  /// The drawn size in pixels.
  final int width;
  final int height;

  @override
  List<Object?> get props => [number, title, note, src, alt, width, height];
}

final class DiagramBlock extends Block {
  const DiagramBlock({required this.number, required this.title, required this.svgLight, required this.svgDark});

  /// The caption number as the bundle writes it.
  final String number;
  final String? title;

  /// Site paths listed in the index's `files`.
  final String svgLight;
  final String svgDark;

  @override
  List<Object?> get props => [number, title, svgLight, svgDark];
}

final class RuleBlock extends Block {
  const RuleBlock();

  @override
  List<Object?> get props => const [];
}

/// A block type this app does not know; drawn as one row that points to the web (Decision A23).
final class UnknownBlock extends Block {
  const UnknownBlock({required this.type});

  final String type;

  @override
  List<Object?> get props => [type];
}

/// A run of text inside a block (`Inline.type` in the bundle).
sealed class Inline extends Equatable {
  const Inline();
}

final class TextInline extends Inline {
  const TextInline({required this.text});

  final String text;

  @override
  List<Object?> get props => [text];
}

final class CodeInline extends Inline {
  const CodeInline({required this.text});

  final String text;

  @override
  List<Object?> get props => [text];
}

/// A hard line break.
final class BreakInline extends Inline {
  const BreakInline();

  @override
  List<Object?> get props => const [];
}

final class StrongInline extends Inline {
  const StrongInline({required this.inlines});

  final List<Inline> inlines;

  @override
  List<Object?> get props => [inlines];
}

final class EmphasisInline extends Inline {
  const EmphasisInline({required this.inlines});

  final List<Inline> inlines;

  @override
  List<Object?> get props => [inlines];
}

/// Struck-through text.
final class DeleteInline extends Inline {
  const DeleteInline({required this.inlines});

  final List<Inline> inlines;

  @override
  List<Object?> get props => [inlines];
}

final class LinkInline extends Inline {
  const LinkInline({required this.target, required this.inlines});

  final LinkTarget target;
  final List<Inline> inlines;

  @override
  List<Object?> get props => [target, inlines];
}

/// A product mark drawn before its name.
final class LogoInline extends Inline {
  const LogoInline({required this.src, required this.alt, required this.mono});

  /// A site path listed in the index's `images`.
  final String src;
  final String alt;

  /// A one-colour mark, inverted on a dark ground.
  final bool mono;

  @override
  List<Object?> get props => [src, alt, mono];
}

/// An inline type this app does not know; its [inlines] are drawn, and it is empty when it has none (Decision A23).
final class UnknownInline extends Inline {
  const UnknownInline({required this.type, required this.inlines});

  final String type;
  final List<Inline> inlines;

  @override
  List<Object?> get props => [type, inlines];
}
