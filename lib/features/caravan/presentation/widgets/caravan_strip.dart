import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_journey.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The whole road in one strip (the web's histogram strip, `scene/strip.ts`): each month a bar as tall as the trends
/// on the road then, each year's name at its start (no dot for each stop, the owner, 2026-11-14), and the stretch the
/// stage shows as a window.
///
/// A drag moves the caravan along the road under the finger and, on release, to the nearest stop; a tap goes to the
/// stop nearest the spot. To a screen reader it is a slider over the stops, read as the chosen trend.
class CaravanStrip extends StatelessWidget {
  const CaravanStrip({
    super.key,
    required this.road,
    required this.journey,
    required this.selected,
    required this.span,
    required this.focusOffset,
    required this.onSelect,
    required this.label,
    required this.value,
    this.increased,
    this.decreased,
  });

  final CaravanRoad road;
  final CaravanJourney journey;
  final int selected;

  /// How many months the stage shows, for the window's width.
  final double span;

  /// How far the chosen stop stands past the stage's middle, in months.
  final double focusOffset;
  final ValueChanged<int> onSelect;

  /// The slider's name and its value (the chosen trend), and the values of the next and the previous stop.
  final String label;
  final String value;
  final String? increased;
  final String? decreased;

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final mirrored = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      slider: true,
      label: label,
      value: value,
      increasedValue: increased,
      decreasedValue: decreased,
      onIncrease: selected < road.stops.length - 1 ? () => onSelect(selected + 1) : null,
      onDecrease: selected > 0 ? () => onSelect(selected - 1) : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double monthAt(double x) => (mirrored ? width - x : x) / width * road.length;
            int stopAt(double x) => road.nearestStop(monthAt(x));
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final stop = stopAt(details.localPosition.dx);
                if (stop >= 0) onSelect(stop);
              },
              onHorizontalDragUpdate: (details) =>
                  journey.dragTo(monthAt(details.localPosition.dx) - focusOffset, dt: 1 / 60),
              onHorizontalDragEnd: (details) {
                final stop = road.nearestStop(journey.t + focusOffset);
                if (stop >= 0) {
                  journey.rest();
                  onSelect(stop);
                }
              },
              child: SizedBox(
                height: height,
                width: width,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _StripPainter(
                      road: road,
                      journey: journey,
                      span: span,
                      mirrored: mirrored,
                      textStyle: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.road,
    required this.journey,
    required this.span,
    required this.mirrored,
    required this.textStyle,
  }) : super(repaint: journey);

  final CaravanRoad road;
  final CaravanJourney journey;
  final double span;
  final bool mirrored;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas
      ..drawRRect(rr, Paint()..color = BazaarFixedColors.bar)
      ..save()
      ..clipRRect(rr);
    if (mirrored) {
      canvas
        ..translate(w, 0)
        ..scale(-1, 1);
    }
    final n = road.length;
    final bw = w / n;
    final base = h - 16;
    final top = 6.0;
    // The bars and the line over them.
    final bar = Paint()..color = BazaarFixedColors.ornament.withValues(alpha: 0.38);
    final line = Path();
    for (var i = 0; i < n; i++) {
      final bh = math.max(1.5, road.norm[i] * (base - top));
      canvas.drawRRect(RRect.fromLTRBR(i * bw + 1, base - bh, (i + 1) * bw - 1, base, const Radius.circular(1.5)), bar);
      final p = Offset((i + 0.5) * bw, base - road.norm[i] * (base - top));
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = BazaarFixedColors.ornament
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
    // Each year's name at its start, with a hairline.
    final tick = Paint()
      ..color = BazaarFixedColors.onBarDim.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final year in road.yearStarts) {
      final x = year.at / n * w;
      if (year.at > 0) canvas.drawLine(Offset(x, top), Offset(x, h), tick);
      final painter = TextPainter(
        text: TextSpan(
          text: '${year.year}',
          style: (textStyle ?? const TextStyle()).copyWith(
            color: BazaarFixedColors.onBarDim,
            fontSize: 10,
            height: 1,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final next = road.yearStarts.where((other) => other.at > year.at).map((other) => other.at / n * w).firstOrNull;
      if ((next ?? w) - x > painter.width + 8) {
        canvas.save();
        final at = Offset(x + 4, h - painter.height - 3);
        if (mirrored) {
          canvas
            ..translate(at.dx + painter.width, at.dy)
            ..scale(-1, 1);
          painter.paint(canvas, Offset.zero);
        } else {
          painter.paint(canvas, at);
        }
        canvas.restore();
      }
      painter.dispose();
    }
    // The window: the stretch of road the stage shows.
    final ww = math.max(18.0, span / n * w);
    final left = ((journey.t - span / 2) / n * w).clamp(0.0, w - ww);
    final window = RRect.fromLTRBR(left, 2, left + ww, h - 2, const Radius.circular(9));
    canvas
      ..drawRRect(window, Paint()..color = BazaarFixedColors.onBar.withValues(alpha: 0.10))
      ..drawRRect(
        window,
        Paint()
          ..color = BazaarFixedColors.onBar.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.road != road ||
      old.span != span ||
      old.mirrored != mirrored ||
      old.journey != journey ||
      old.textStyle != textStyle;
}
