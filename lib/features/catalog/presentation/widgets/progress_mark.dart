import 'dart:math' as math;

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The three marks of a catalog module row, which the legend teaches (the progress page's marks, plan 1AB).
enum ProgressMarkKind { complete, notYet, planned }

/// A module row's mark (web `completion.css:699-719,757-764`): a filled success disc with a check, an empty ring, or a
/// dashed ring. A graphic only; the row's semantics carry the state.
class ProgressMark extends StatelessWidget {
  const ProgressMark(this.kind, {super.key});

  final ProgressMarkKind kind;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return SizedBox.square(
      dimension: _size,
      child: CustomPaint(
        painter: _MarkPainter(
          kind: kind,
          fill: BazaarFixedColors.success,
          check: colors.onPrimary,
          ring: colors.onSurfaceMuted,
          dashed: colors.onSurfaceFaint,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.kind,
    required this.fill,
    required this.check,
    required this.ring,
    required this.dashed,
  });

  final ProgressMarkKind kind;
  final Color fill;
  final Color check;
  final Color ring;
  final Color dashed;

  static const double _stroke = 2;
  static const int _dashes = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    switch (kind) {
      case ProgressMarkKind.complete:
        canvas.drawOval(Offset.zero & size, Paint()..color = fill);
        final tick = Path()
          ..moveTo(size.width * 0.28, size.height * 0.52)
          ..lineTo(size.width * 0.44, size.height * 0.68)
          ..lineTo(size.width * 0.74, size.height * 0.36);
        canvas.drawPath(
          tick,
          stroke
            ..color = check
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case ProgressMarkKind.notYet:
        canvas.drawOval(rect, stroke..color = ring);
      case ProgressMarkKind.planned:
        // Half of each arc step is drawn, half left open.
        const step = 2 * math.pi / _dashes;
        for (var dash = 0; dash < _dashes; dash++) {
          canvas.drawArc(rect, dash * step, step / 2, false, stroke..color = dashed);
        }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.fill != fill ||
      oldDelegate.check != check ||
      oldDelegate.ring != ring ||
      oldDelegate.dashed != dashed;
}
