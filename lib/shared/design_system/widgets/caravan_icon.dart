import 'package:flutter/widgets.dart';

/// The Caravan's mark in the bottom navigation: a horse's head with its mane apart, facing the way the reader reads,
/// filled, on the 24 grid of the bar's other icons (the owner, 2026-11-16: a horse in place of the camel, in the tab
/// only; the Caravan's scene keeps its camels). It takes the colour and size of the surrounding [IconTheme].
class CaravanIcon extends StatelessWidget {
  const CaravanIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: HorsePainter(
            theme.color ?? const Color(0xff000000),
            mirrored: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

/// Paints the Caravan tab's horse; [horse] is its outline.
class HorsePainter extends CustomPainter {
  const HorsePainter(this.color, {required this.mirrored});

  final Color color;
  final bool mirrored;

  /// The horse's head facing right on a 24 by 24 grid: the head and neck with the eye left open, and the mane apart.
  static final Path horse = Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(5.2, 21.0)
    ..cubicTo(5.0, 16.0, 5.6, 11.0, 7.4, 7.6)
    ..cubicTo(8.2, 6.0, 9.0, 5.0, 9.8, 4.4)
    ..lineTo(10.9, 1.2)
    ..lineTo(12.3, 4.1)
    ..cubicTo(14.6, 4.6, 17.0, 6.6, 18.8, 9.6)
    ..cubicTo(19.6, 10.8, 20.6, 11.8, 20.8, 13.0)
    ..cubicTo(21.0, 14.4, 20.2, 15.2, 19.0, 15.0)
    ..cubicTo(17.6, 14.8, 16.6, 13.8, 15.2, 13.8)
    ..cubicTo(13.8, 13.8, 13.2, 15.2, 13.4, 17.0)
    ..lineTo(14.0, 21.0)
    ..close()
    ..addOval(Rect.fromCircle(center: const Offset(13.6, 7.8), radius: 0.7))
    ..moveTo(9.0, 4.6)
    ..cubicTo(6.6, 5.6, 4.8, 8.4, 4.2, 11.6)
    ..cubicTo(3.6, 14.4, 3.2, 16.8, 2.4, 18.6)
    ..cubicTo(3.6, 17.6, 4.2, 16.4, 4.4, 15.4)
    ..cubicTo(4.6, 12.0, 5.4, 9.2, 7.0, 6.8)
    ..cubicTo(7.6, 5.8, 8.2, 5.1, 9.0, 4.6)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // In a right-to-left language the horse faces left.
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(horse, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HorsePainter oldDelegate) => oldDelegate.color != color || oldDelegate.mirrored != mirrored;
}
