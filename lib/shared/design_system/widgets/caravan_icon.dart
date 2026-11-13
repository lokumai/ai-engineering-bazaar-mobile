import 'package:flutter/widgets.dart';

/// The Caravan's mark in the bottom navigation: a camel walking the way the reader reads, one hump, filled, on the 24 grid
/// of the bar's other icons. It takes the colour and size of the surrounding [IconTheme].
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
          painter: CamelPainter(
            theme.color ?? const Color(0xff000000),
            mirrored: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

/// Paints the Caravan's camel; [camel] is its outline, which the Caravan page's scene draws too.
class CamelPainter extends CustomPainter {
  const CamelPainter(this.color, {required this.mirrored});

  final Color color;
  final bool mirrored;

  /// The camel facing right on a 24 by 24 grid, with its tail apart.
  static final Path camel = Path()
    ..moveTo(4.6, 10.2)
    ..cubicTo(6.0, 9.6, 7.4, 4.6, 10.0, 4.6)
    ..cubicTo(12.6, 4.6, 13.2, 8.4, 14.6, 9.0)
    ..cubicTo(15.8, 9.6, 16.6, 11.4, 17.6, 11.0)
    ..cubicTo(18.6, 10.6, 18.8, 7.4, 19.6, 6.0)
    ..cubicTo(20.0, 5.2, 21.0, 5.0, 22.0, 5.6)
    ..lineTo(22.8, 6.4)
    ..lineTo(22.6, 7.3)
    ..lineTo(20.8, 7.6)
    ..cubicTo(20.2, 9.6, 19.8, 12.4, 17.8, 13.4)
    ..lineTo(17.8, 21.0)
    ..lineTo(16.5, 21.0)
    ..lineTo(16.3, 14.2)
    ..lineTo(15.4, 14.2)
    ..lineTo(15.2, 21.0)
    ..lineTo(13.9, 21.0)
    ..lineTo(13.8, 13.6)
    ..lineTo(9.4, 13.6)
    ..lineTo(9.2, 21.0)
    ..lineTo(7.9, 21.0)
    ..lineTo(7.8, 13.8)
    ..lineTo(7.0, 13.6)
    ..lineTo(6.6, 21.0)
    ..lineTo(5.3, 21.0)
    ..lineTo(5.4, 12.8)
    ..cubicTo(4.8, 12.2, 4.5, 11.2, 4.6, 10.2)
    ..close()
    ..moveTo(4.9, 10.8)
    ..lineTo(3.2, 14.6)
    ..lineTo(3.8, 14.9)
    ..lineTo(5.4, 11.6)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // In a right-to-left language the camel walks left.
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(camel, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CamelPainter oldDelegate) => oldDelegate.color != color || oldDelegate.mirrored != mirrored;
}
