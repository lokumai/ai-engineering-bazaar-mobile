import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/logo_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/text_find.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// What a tap on a link does with its target.
typedef LinkHandler = void Function(LinkTarget target);

/// The word joiner: no line break may fall where it stands.
const _wordJoiner = '\u2060';

/// A run of inline content drawn as one piece of rich text in [style].
///
/// Strong is weight 600 (Decision A17), a link weight 500 with an ornament underline, and an external link carries the
/// web's trailing arrow, word-joined to the link and hidden from semantics. A link whose target this app does not know
/// is drawn as plain text and is not tappable (Decision A23), as is an inline of a kind it does not know. A logo is
/// drawn at text height and held to the next word, as the web's `.bz-logo-pair` does.
///
/// Under a [TextFindScope] the words that answer the search are marked, the current one more strongly (plan 7.1).
class InlineText extends StatefulWidget {
  const InlineText({
    super.key,
    required this.inlines,
    required this.style,
    required this.onLink,
    this.textAlign = TextAlign.start,
  });

  final List<Inline> inlines;

  /// The base style; its font size also sizes the logos.
  final TextStyle style;
  final LinkHandler onLink;
  final TextAlign textAlign;

  @override
  State<InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<InlineText> implements TextFindTarget {
  TextFinder? _finder;

  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _finder?.forget(this);
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final finder = TextFindScope.of(context);
    if (finder != _finder) {
      _finder?.forget(this);
      _finder = finder;
    }
    final marker = finder == null || finder.terms.isEmpty ? null : _Marker(finder, this);
    _marker = marker;
    final spans = _SpanBuilder(
      colors: context.bazaarColors,
      fontSize: widget.style.fontSize!,
      ink: widget.style.color ?? context.bazaarColors.onSurface,
      onLink: widget.onLink,
      recognizers: _recognizers,
      marker: marker,
    ).build(widget.inlines, null);
    finder?.report(this, marker?.count ?? 0);
    final root = _root = TextSpan(style: widget.style, children: spans);
    return Text.rich(root, textAlign: widget.textAlign);
  }

  /// The marker and the text of the last build, to find where a mark is drawn.
  _Marker? _marker;
  TextSpan? _root;

  @override
  Rect? markRect(int index) {
    final mark = _marker?.marks.elementAtOrNull(index);
    final root = _root;
    final paragraph = _paragraphOf(context.findRenderObject());
    if (mark == null || root == null || paragraph == null || !paragraph.attached || !paragraph.hasSize) return null;
    // The mark's place in the text as laid out: a widget span, a logo, stands for one character.
    var offset = 0;
    int? start;
    root.visitChildren((span) {
      if (identical(span, mark)) {
        start = offset;
        return false;
      }
      if (span is TextSpan) offset += span.text?.length ?? 0;
      if (span is PlaceholderSpan) offset += 1;
      return true;
    });
    final from = start;
    if (from == null) return null;
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: from, extentOffset: from + mark.text!.length),
    );
    if (boxes.isEmpty) return null;
    final rect = boxes.map((box) => box.toRect()).reduce((a, b) => a.expandToInclude(b));
    return rect.shift(paragraph.localToGlobal(Offset.zero));
  }

  /// The paragraph [object] is or holds.
  static RenderParagraph? _paragraphOf(RenderObject? object) {
    if (object == null || object is RenderParagraph) return object as RenderParagraph?;
    RenderParagraph? found;
    object.visitChildren((child) => found ??= _paragraphOf(child));
    return found;
  }
}

/// Marks the words of a text that answer a [TextFinder], counting them in order.
class _Marker {
  _Marker(this.finder, this.target);

  final TextFinder finder;
  final TextFindTarget target;

  /// The marks made so far.
  int count = 0;

  /// The spans of the marks made so far, in order, to find where each is drawn.
  final marks = <TextSpan>[];

  /// The spans of [text], its matching words marked.
  List<TextSpan> spans(String text, TapGestureRecognizer? recognizer) {
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in markRanges(text, finder.terms, finder.lang)) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start), recognizer: recognizer));
      final current = finder.isCurrent(target, count++);
      final mark = TextSpan(
        text: text.substring(start, end),
        recognizer: recognizer,
        style: current ? _currentStyle : _markStyle,
      );
      marks.add(mark);
      spans.add(mark);
      at = end;
    }
    if (spans.isEmpty) return [TextSpan(text: text, recognizer: recognizer)];
    if (at < text.length) spans.add(TextSpan(text: text.substring(at), recognizer: recognizer));
    return spans;
  }
}

/// The ground of a marked word, and of the current one: the caution hue, faint and full.
final _markStyle = TextStyle(background: Paint()..color = BazaarFixedColors.caution.withAlpha(0x55));
final _currentStyle = TextStyle(
  color: BazaarFixedColors.onCaution,
  background: Paint()..color = BazaarFixedColors.caution,
);

class _SpanBuilder {
  _SpanBuilder({
    required this.colors,
    required this.fontSize,
    required this.ink,
    required this.onLink,
    required this.recognizers,
    this.marker,
  });

  /// Marks the words searched; null when nothing is searched.
  final _Marker? marker;

  final BazaarColors colors;
  final double fontSize;

  /// The colour of the text, which the external mark takes.
  final Color ink;
  final LinkHandler onLink;
  final List<TapGestureRecognizer> recognizers;

  /// The spans of [inlines]; every text leaf carries [recognizer], since a span's recognizer reaches only its own text.
  List<InlineSpan> build(List<Inline> inlines, TapGestureRecognizer? recognizer) => [
    for (final inline in inlines) ..._spansOf(inline, recognizer),
  ];

  List<InlineSpan> _spansOf(Inline inline, TapGestureRecognizer? recognizer) => switch (inline) {
    TextInline(:final text) => marker?.spans(text, recognizer) ?? [TextSpan(text: text, recognizer: recognizer)],
    // Code in a line is searched, so its words are marked too.
    CodeInline(:final text) => [
      TextSpan(
        text: marker == null ? text : null,
        children: marker?.spans(text, recognizer),
        recognizer: marker == null ? recognizer : null,
        style: TextStyle(
          fontFamily: monoFamily(defaultTargetPlatform),
          fontSize: BazaarType.meta.size,
          background: Paint()..color = colors.surfaceSunken,
        ),
      ),
    ],
    BreakInline() => [TextSpan(text: '\n', recognizer: recognizer)],
    StrongInline(:final inlines) => [
      TextSpan(
        style: const TextStyle(fontWeight: FontWeight.w600),
        children: build(inlines, recognizer),
      ),
    ],
    EmphasisInline(:final inlines) => [
      TextSpan(
        style: const TextStyle(fontStyle: FontStyle.italic),
        children: build(inlines, recognizer),
      ),
    ],
    DeleteInline(:final inlines) => [
      TextSpan(
        style: const TextStyle(decoration: TextDecoration.lineThrough),
        children: build(inlines, recognizer),
      ),
    ],
    LinkInline(target: UnknownTarget(), :final inlines) => build(inlines, recognizer),
    LinkInline(:final target, :final inlines) => _link(target, inlines),
    LogoInline(:final src, :final mono) => [
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: 0.3 * fontSize),
          child: Transform.translate(
            offset: Offset(0, 0.18 * fontSize),
            child: LogoView(src: src, mono: mono, fontSize: fontSize),
          ),
        ),
      ),
      // No recognizer and no label: a span with a recognizer is a link node of its own, and the joiner has no name.
      const TextSpan(text: _wordJoiner, semanticsLabel: ''),
    ],
    UnknownInline(:final inlines) => build(inlines, recognizer),
  };

  List<InlineSpan> _link(LinkTarget target, List<Inline> inlines) {
    final recognizer = TapGestureRecognizer()..onTap = () => onLink(target);
    recognizers.add(recognizer);
    return [
      TextSpan(
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: BazaarFixedColors.ornament,
          decorationThickness: 1,
        ),
        children: build(inlines, recognizer),
      ),
      // The mark that the link leaves the app, drawn as an icon in the text's colour: no text face carries the arrow,
      // so as a character it fell back to the colour emoji. The joiner keeps it on the line of the link's last word.
      if (target is ExternalTarget) ...[
        const TextSpan(text: _wordJoiner, semanticsLabel: ''),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: ExternalMark(size: fontSize, color: ink),
        ),
      ],
    ];
  }
}

/// The text of [inlines] for a semantics label: text and code as written, a break as a space, a logo as nothing.
String inlinePlainText(List<Inline> inlines) {
  final buffer = StringBuffer();
  void write(List<Inline> inlines) {
    for (final inline in inlines) {
      switch (inline) {
        case TextInline(:final text) || CodeInline(:final text):
          buffer.write(text);
        case BreakInline():
          buffer.write(' ');
        case LogoInline():
          break;
        case StrongInline(:final inlines) ||
            EmphasisInline(:final inlines) ||
            DeleteInline(:final inlines) ||
            LinkInline(:final inlines) ||
            UnknownInline(:final inlines):
          write(inlines);
      }
    }
  }

  write(inlines);
  return buffer.toString();
}

/// The mark after a link that leaves the app: a small north-east arrow in [color], or the surrounding icon colour when
/// null, sized to text of [size]. Decoration: the link says where it goes.
class ExternalMark extends StatelessWidget {
  const ExternalMark({super.key, required this.size, this.color});

  /// The font size of the text it follows.
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: size * 0.08),
        child: Icon(Icons.north_east, size: size * 0.8, color: color),
      ),
    );
  }
}
