import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bazaar_theme.dart';

/// A ring that fills with [color] by [done] of [total], with [center] inside it (the mockup's conic dial).
///
/// The ring is an image named by [semanticLabel]; the text inside is part of that image, so assistive technology
/// reads the label once. The ring grows with the text scale, so the text inside always fits (spec 3.10).
class CompletionDial extends StatelessWidget {
  const CompletionDial({
    super.key,
    required this.done,
    required this.total,
    required this.color,
    required this.center,
    required this.semanticLabel,
    this.size = 46,
    this.ring = 5,
  });

  final int done;
  final int total;

  /// The filled part of the ring.
  final Color color;

  /// The text inside the ring, such as `3/8`.
  final String center;
  final String semanticLabel;

  /// The diameter at text scale 1.
  final double size;

  /// The width of the ring.
  final double ring;

  /// The share of the ring that is filled, from 0 to 1; 0 when [total] is 0.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final diameter = MediaQuery.textScalerOf(context).scale(size);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurface);
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: diameter,
        child: CustomPaint(
          painter: CompletionDialPainter(fraction: fraction, color: color, track: colors.surfaceSunken, ring: ring),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(ring + 1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(center, style: style, maxLines: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the ring: the [track] all round, then [fraction] of it in [color] clockwise from the top.
class CompletionDialPainter extends CustomPainter {
  const CompletionDialPainter({required this.fraction, required this.color, required this.track, required this.ring});

  final double fraction;
  final Color color;
  final Color track;
  final double ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(ring / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (fraction > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, paint..color = color);
  }

  @override
  bool shouldRepaint(CompletionDialPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.ring != ring;
}
