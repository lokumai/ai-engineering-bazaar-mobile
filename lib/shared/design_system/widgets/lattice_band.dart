import 'package:flutter/material.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';

/// The lattice band under the bar: diagonal stripes of the three band colours on the band ground, over an ornament rule
/// (the web's `--band-*` tokens, the mockup's 16 px band with its 2 px edge). Decoration only, so it is hidden from
/// assistive technology.
class LatticeBand extends StatelessWidget {
  const LatticeBand({super.key});

  /// The height of the stripes and the edge together.
  static const double height = BazaarLayout.band;

  /// The ornament rule under the stripes.
  static const double edge = 2;

  @override
  Widget build(BuildContext context) {
    final bandC = context.bazaarColors.bandC;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: LatticeBandPainter(bandC: bandC)),
      ),
    );
  }
}

/// Paints the band: a repeat of 27 units along the diagonal, as the mockup's
/// `repeating-linear-gradient(45deg, A 0 5, ground 5 9, B 9 14, ground 14 18, C 18 23, ground 23 27)`.
class LatticeBandPainter extends CustomPainter {
  const LatticeBandPainter({required this.bandC});

  /// The third stripe, the one band colour that differs between light and dark.
  final Color bandC;

  /// Each stripe as its start and end along the repeat, with its colour; the gaps are the ground.
  List<(double, double, Color)> get _stripes => [
    (0, 5, BazaarFixedColors.bandA),
    (9, 14, BazaarFixedColors.bandB),
    (18, 23, bandC),
  ];

  static const double _repeat = 27;

  @override
  void paint(Canvas canvas, Size size) {
    final stripes = Rect.fromLTWH(0, 0, size.width, size.height - LatticeBand.edge);
    canvas.drawRect(stripes, Paint()..color = BazaarFixedColors.bandGround);
    canvas.save();
    canvas.clipRect(stripes);
    // A 45 degree stripe crosses the band's height h over a run of h, so stripes start a height to the left.
    final h = stripes.height;
    final paint = Paint();
    for (var origin = -h; origin < size.width + _repeat; origin += _repeat) {
      for (final (start, end, color) in _stripes) {
        paint.color = color;
        canvas.drawPath(
          Path()
            ..moveTo(origin + start, h)
            ..lineTo(origin + end, h)
            ..lineTo(origin + end + h, 0)
            ..lineTo(origin + start + h, 0)
            ..close(),
          paint,
        );
      }
    }
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - LatticeBand.edge, size.width, LatticeBand.edge),
      Paint()..color = BazaarFixedColors.ornament,
    );
  }

  @override
  bool shouldRepaint(LatticeBandPainter oldDelegate) => oldDelegate.bandC != bandC;
}
