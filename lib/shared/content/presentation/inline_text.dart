import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/logo_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// What a tap on a link does with its target.
typedef LinkHandler = void Function(LinkTarget target);

/// The word joiner: no line break may fall where it stands.
const _wordJoiner = '⁠';

/// A run of inline content drawn as one piece of rich text in [style].
///
/// Strong is weight 600 (Decision A17), a link weight 500 with an ornament underline, and an external link carries the
/// web's trailing arrow, word-joined to the link and hidden from semantics. A link whose target this app does not know
/// is drawn as plain text and is not tappable (Decision A23), as is an inline of a kind it does not know. A logo is
/// drawn at text height and held to the next word, as the web's `.bz-logo-pair` does.
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

class _InlineTextState extends State<InlineText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = _SpanBuilder(
      colors: context.bazaarColors,
      fontSize: widget.style.fontSize!,
      onLink: widget.onLink,
      recognizers: _recognizers,
    ).build(widget.inlines, null);
    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      textAlign: widget.textAlign,
    );
  }
}

class _SpanBuilder {
  _SpanBuilder({required this.colors, required this.fontSize, required this.onLink, required this.recognizers});

  final BazaarColors colors;
  final double fontSize;
  final LinkHandler onLink;
  final List<TapGestureRecognizer> recognizers;

  /// The spans of [inlines]; every text leaf carries [recognizer], since a span's recognizer reaches only its own text.
  List<InlineSpan> build(List<Inline> inlines, TapGestureRecognizer? recognizer) => [
    for (final inline in inlines) ..._spansOf(inline, recognizer),
  ];

  List<InlineSpan> _spansOf(Inline inline, TapGestureRecognizer? recognizer) => switch (inline) {
    TextInline(:final text) => [TextSpan(text: text, recognizer: recognizer)],
    CodeInline(:final text) => [
      TextSpan(
        text: text,
        recognizer: recognizer,
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
          padding: EdgeInsets.only(right: 0.3 * fontSize),
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
      if (target is ExternalTarget)
        TextSpan(
          text: '$_wordJoiner↗',
          semanticsLabel: '',
          style: TextStyle(color: colors.onSurfaceFaint, fontSize: BazaarType.mark.size),
        ),
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
