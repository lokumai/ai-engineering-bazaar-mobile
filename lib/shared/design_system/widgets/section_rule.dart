import 'package:flutter/material.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';

/// A section heading followed by a dashed ornament rule that fills the rest of the line (the mockup's `h2` with its
/// dashed `#c8a078` line). The heading is a header for assistive technology; the rule is decoration.
class SectionRule extends StatelessWidget {
  const SectionRule({super.key, required this.title, this.style});

  final String title;

  /// The heading's style; the theme's `titleLarge` in the title colour when null.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ?? Theme.of(context).textTheme.titleLarge?.copyWith(color: context.bazaarColors.onSurfaceTitle);
    return Row(
      spacing: 12,
      children: [
        Flexible(
          child: Semantics(header: true, child: Text(title, style: textStyle)),
        ),
        const Expanded(child: DashedRule()),
      ],
    );
  }
}

/// A horizontal dashed line in the ornament colour, as wide as it is let be.
class DashedRule extends StatelessWidget {
  const DashedRule({super.key, this.thickness = 2, this.dash = 6, this.gap = 4});

  final double thickness;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: thickness,
        width: double.infinity,
        child: CustomPaint(
          painter: _DashPainter(thickness: thickness, dash: dash, gap: gap),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.thickness, required this.dash, required this.gap});

  final double thickness;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = BazaarFixedColors.ornament;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0, size.width).toDouble();
      canvas.drawRect(Rect.fromLTRB(x, 0, end, thickness), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      oldDelegate.thickness != thickness || oldDelegate.dash != dash || oldDelegate.gap != gap;
}
