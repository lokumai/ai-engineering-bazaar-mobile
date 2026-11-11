import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The part of [path] from its start to [t] of each of its contours' length.
Path _drawn(Path path, double t) {
  if (t >= 1) return path;
  final part = Path();
  if (t <= 0) return part;
  for (final metric in path.computeMetrics()) {
    part.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
  }
  return part;
}

/// The gate arch the title stands in, and the motto again, drawing itself: the web's `Arch` (`AboutStory.tsx`) in its
/// viewBox `250 70 500 560`. [outer] and [inner] are how far each stroke is drawn, 0 to 1; [finial] how far the
/// diamond at its apex has popped in, or null for the motto's arch, which has none.
class ArchPainter extends CustomPainter {
  ArchPainter({required this.outer, required this.inner, required this.color, this.finial});

  final double outer;
  final double inner;
  final double? finial;
  final Color color;

  /// The arch's width over its height.
  static const aspect = 500 / 560;

  static final _outer = Path()
    ..moveTo(280, 620)
    ..lineTo(280, 330)
    ..cubicTo(280, 184.3, 394.4, 118.5, 500, 95)
    ..cubicTo(605.6, 118.5, 720, 184.3, 720, 330)
    ..lineTo(720, 620);

  static final _inner = Path()
    ..moveTo(296, 620)
    ..lineTo(296, 334)
    ..cubicTo(296, 198, 402, 136, 500, 114)
    ..cubicTo(598, 136, 704, 198, 704, 334)
    ..lineTo(704, 620);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 500, size.height / 560);
    canvas
      ..save()
      ..translate((size.width - 500 * scale) / 2, (size.height - 560 * scale) / 2)
      ..scale(scale)
      ..translate(-250, -70);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.25, 1 / scale)
      ..color = color;
    canvas
      ..drawPath(_drawn(_outer, outer), stroke)
      ..drawPath(_drawn(_inner, inner), stroke..color = color.withValues(alpha: color.a * 0.45));
    if (finial case final pop? when pop > 0) {
      canvas
        ..save()
        ..translate(500, 80)
        ..rotate(math.pi / 4)
        ..scale(pop)
        ..drawRect(Rect.fromCenter(center: Offset.zero, width: 12, height: 12), Paint()..color = color)
        ..restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArchPainter oldDelegate) =>
      oldDelegate.outer != outer ||
      oldDelegate.inner != inner ||
      oldDelegate.finial != finial ||
      oldDelegate.color != color;
}

/// The hand-drawn line under the motto, a little uneven on purpose, and the dot that ends it: the web's `.motto-line`
/// in its viewBox `0 0 560 40`. [stroke] is how far the line is drawn and [dot] how far the dot has popped in.
class HandLinePainter extends CustomPainter {
  HandLinePainter({required this.stroke, required this.dot, required this.color, required this.dotColor});

  final double stroke;
  final double dot;
  final Color color;
  final Color dotColor;

  static const aspect = 560 / 40;

  static final _line = Path()
    ..moveTo(8, 24)
    ..cubicTo(60, 18, 110, 27, 168, 21)
    ..cubicTo(230, 15, 268, 28, 330, 22)
    ..cubicTo(392, 16, 440, 26, 494, 19)
    ..cubicTo(516, 16, 534, 18, 552, 22);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 560;
    canvas
      ..save()
      ..scale(scale)
      ..drawPath(
        _drawn(_line, stroke),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    if (dot > 0) canvas.drawCircle(const Offset(552, 22), 3.2 * dot, Paint()..color = dotColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HandLinePainter oldDelegate) =>
      oldDelegate.stroke != stroke || oldDelegate.dot != dot || oldDelegate.color != color;
}
