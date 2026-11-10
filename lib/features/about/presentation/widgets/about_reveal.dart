import 'package:flutter/widgets.dart';

/// Where one screen of the story stands: [seconds] since it came in, from which each piece works out how far it has
/// arrived, as the web's GSAP timelines place each tween at a time (`src/components/about/motion.ts`). When [still],
/// under reduced motion or a screen reader, every piece is in place from the start.
class RevealClock {
  const RevealClock(this.seconds, {this.still = false});

  final double seconds;
  final bool still;

  /// How far a piece that starts at [start] and takes [duration] seconds has come, 0 to 1, along [curve].
  double at(double start, double duration, [Curve curve = Curves.linear]) {
    if (still) return 1;
    final t = ((seconds - start) / duration).clamp(0.0, 1.0);
    return curve.transform(t);
  }
}

/// The web's `power4.out`, `power3.out`, `power2.inOut` and `back.out`.
abstract final class RevealCurves {
  static const rise = Curves.easeOutQuart;
  static const settle = Curves.easeOutCubic;
  static const draw = Curves.easeInOutQuad;
  static const pop = Curves.easeOutBack;
}

/// [child] rising into place from [from] of its height below, inside its own line, so it seems to come up from under
/// the text's baseline, as the web's split words and lines do (`.sw`, `.sln`); [fade] also brings it in from clear.
class Rise extends StatelessWidget {
  const Rise({super.key, required this.progress, required this.child, this.from = 1.18, this.fade = false});

  final double progress;
  final double from;
  final bool fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress >= 1) return child;
    Widget moved = FractionalTranslation(translation: Offset(0, (1 - progress) * from), child: child);
    if (fade) moved = Opacity(opacity: progress.clamp(0.0, 1.0), child: moved);
    return ClipRect(clipper: const _Slack(), child: moved);
  }
}

/// The word's own box with room for an italic's overhang and a descender, as the web pads its `.sw`.
class _Slack extends CustomClipper<Rect> {
  const _Slack();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.height * 0.2, -size.height * 0.2, size.width + size.height * 0.2, size.height * 1.1);

  @override
  bool shouldReclip(_Slack oldClipper) => false;
}

/// [text] set in [style], each word rising in turn: the first at [start], each next [stagger] later, each taking
/// [duration]; the words wrap as the text would. A screen reader reads it as one piece.
class RisingWords extends StatelessWidget {
  const RisingWords({
    super.key,
    required this.text,
    required this.style,
    required this.clock,
    required this.start,
    this.stagger = 0.045,
    this.duration = 1.05,
    this.from = 1.18,
    this.fade = false,
    this.textAlign = TextAlign.start,
    this.header = false,
  });

  final String text;
  final TextStyle style;
  final RevealClock clock;
  final double start;
  final double stagger;
  final double duration;
  final double from;
  final bool fade;
  final TextAlign textAlign;
  final bool header;

  @override
  Widget build(BuildContext context) {
    if (clock.still) {
      return Semantics(
        header: header,
        child: Text(text, style: style, textAlign: textAlign),
      );
    }
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      header: header,
      label: text,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: style,
            children: [
              for (final (i, word) in words.indexed) ...[
                if (i > 0) const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Rise(
                    progress: clock.at(start + i * stagger, duration, RevealCurves.rise),
                    from: from,
                    fade: fade,
                    // The span scales its widgets by the text scale itself.
                    child: Text(word, style: style, textScaler: TextScaler.noScaling),
                  ),
                ),
              ],
            ],
          ),
          textAlign: textAlign,
          textScaler: scaler,
        ),
      ),
    );
  }
}

/// A paragraph cut into the lines it wraps to at this width, each rising and coming clear in turn from [start],
/// [stagger] apart, as the web's `splitLines`. A screen reader reads the paragraph whole.
class RisingLines extends StatefulWidget {
  const RisingLines({
    super.key,
    required this.text,
    required this.style,
    required this.clock,
    required this.start,
    this.stagger = 0.07,
    this.duration = 0.95,
  });

  final String text;
  final TextStyle style;
  final RevealClock clock;
  final double start;
  final double stagger;
  final double duration;

  @override
  State<RisingLines> createState() => _RisingLinesState();
}

class _RisingLinesState extends State<RisingLines> {
  (String, double, TextScaler, TextDirection, TextStyle)? _cut;
  List<String> _lines = const [];

  List<String> _linesAt(double width, TextStyle style, TextScaler scaler, TextDirection direction) {
    final key = (widget.text, width, scaler, direction, style);
    if (_cut == key) return _lines;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: width);
    final text = widget.text;
    final lines = <String>[];
    var offset = 0;
    while (offset < text.length) {
      final range = painter.getLineBoundary(TextPosition(offset: offset));
      if (range.end <= offset) break;
      lines.add(text.substring(range.start, range.end).trimRight());
      offset = range.end;
      while (offset < text.length && text[offset] == ' ') {
        offset++;
      }
    }
    painter.dispose();
    _cut = key;
    return _lines = lines;
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    if (widget.clock.still) return Text(widget.text, style: style);
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lines = _linesAt(
              constraints.maxWidth,
              style,
              MediaQuery.textScalerOf(context),
              Directionality.of(context),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, line) in lines.indexed)
                  Rise(
                    progress: widget.clock.at(widget.start + i * widget.stagger, widget.duration, RevealCurves.settle),
                    from: 1,
                    fade: true,
                    child: Text(line, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
