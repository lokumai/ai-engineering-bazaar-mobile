import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';

/// What the model said, in a speech bubble whose tail points at the robot on its end side. It pops out of its tail,
/// then the words stream a token at a time as a model writes, with a caret while it writes.
class SpeechBubble extends StatefulWidget {
  const SpeechBubble({super.key, required this.speech, this.delay = Duration.zero});

  final Babble speech;

  /// How long it waits before it pops out, while the robot thinks.
  final Duration delay;

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// How long the bubble takes to pop out, before the first token.
  static const _pop = 180;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = widget.delay + Duration(milliseconds: _pop + widget.speech.tokens.length * 110)
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final odd = widget.speech.hallucinating;
    final tokens = widget.speech.tokens;
    return Semantics(
      liveRegion: true,
      label: s.pocket_says(tokens.join(' ')),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final wait = widget.delay.inMilliseconds;
          final total = (_controller.duration?.inMilliseconds ?? _pop) - wait;
          final elapsed = _controller.value * (total + wait) - wait;
          if (elapsed < 0) return const SizedBox.shrink();
          final pop = Curves.easeOutBack.transform((elapsed / _pop).clamp(0.0, 1.0));
          final writing = (elapsed - _pop) / math.max(1, total - _pop);
          final shown = _controller.value >= 1
              ? tokens.length
              : (tokens.length * writing).ceil().clamp(0, tokens.length);
          return Transform.scale(
            scale: 0.6 + 0.4 * pop,
            alignment: AlignmentDirectional.bottomEnd.resolve(Directionality.of(context)),
            child: Opacity(
              opacity: pop.clamp(0.0, 1.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300, minWidth: 64),
                child: Container(
                  decoration: ShapeDecoration(
                    color: colors.surfaceRaised,
                    shape: SpeechBubbleBorder(
                      side: BorderSide(color: odd ? RobotColors.eyeOdd : colors.lineStrong, width: odd ? 1.6 : 1.2),
                    ),
                    shadows: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3))],
                  ),
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14 + SpeechBubbleBorder.tail, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (odd)
                        Text(
                          s.pocket_hallucinating,
                          style: theme.textTheme.labelSmall?.copyWith(color: RobotColors.eyeOdd),
                        ),
                      Text(
                        '${tokens.take(shown).join(' ')}${_controller.value < 1 ? ' |' : ''}',
                        // Held to five lines, so the longest sentence stays by the robot's head.
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceTitle,
                          fontStyle: odd ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A rounded bubble with a tail out of its end side near the bottom, curving down toward the speaker. The tail takes
/// [tail] pixels of the bubble's width on its end side; the bubble's padding keeps that room clear.
class SpeechBubbleBorder extends ShapeBorder {
  const SpeechBubbleBorder({this.side = BorderSide.none, this.radius = 16});

  final BorderSide side;
  final double radius;

  /// How far the tail reaches out of the bubble.
  static const tail = 12.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => SpeechBubbleBorder(side: side.scale(t), radius: radius * t);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // Drawn with the tail on the right, then turned for a right-to-left language.
    final body = Rect.fromLTRB(rect.left, rect.top, rect.right - tail, rect.bottom);
    final r = math.min(radius, math.min(body.width, body.height) / 2);
    final tailTop = math.max(body.top + r, body.bottom - r - 12);
    final path = Path()
      ..moveTo(body.left + r, body.top)
      ..lineTo(body.right - r, body.top)
      ..arcToPoint(Offset(body.right, body.top + r), radius: Radius.circular(r))
      ..lineTo(body.right, tailTop)
      // The tail: out and down to its tip, then back in to the bubble's corner.
      ..quadraticBezierTo(body.right + tail * 0.25, rect.bottom - 6, rect.right, rect.bottom - 1)
      ..quadraticBezierTo(body.right, body.bottom, body.right - r, body.bottom)
      ..lineTo(body.left + r, body.bottom)
      ..arcToPoint(Offset(body.left, body.bottom - r), radius: Radius.circular(r))
      ..lineTo(body.left, body.top + r)
      ..arcToPoint(Offset(body.left + r, body.top), radius: Radius.circular(r))
      ..close();
    if (textDirection != TextDirection.rtl) return path;
    final centre = rect.center.dx;
    return path.transform(Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, centre * 2, 0, 0, 1]));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      Paint()
        ..color = side.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool operator ==(Object other) => other is SpeechBubbleBorder && other.side == side && other.radius == radius;

  @override
  int get hashCode => Object.hash(side, radius);
}
