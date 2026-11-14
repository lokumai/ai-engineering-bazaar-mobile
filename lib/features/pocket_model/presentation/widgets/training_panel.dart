import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// How the pocket model's training stands: its level in a ring that fills toward the next, the tokens it was fed, the
/// road of levels, and its training loss as a chart that grows with every feed.
class TrainingPanel extends StatelessWidget {
  const TrainingPanel({super.key, required this.model});

  final PocketModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final next = model.toNext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _LevelRing(level: model.level, progress: model.progress, reduced: reduced),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.pocket_level(model.level),
                    style: displayFace(theme.textTheme.titleMedium)?.copyWith(color: colors.onSurfaceTitle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      s.pocket_tokens(model.tokens),
                      if (next != null) s.pocket_to_next(next, model.level + 1) else s.pocket_top,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LevelRoad(level: model.level, reduced: reduced),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LossChart(tokens: model.tokens),
      ],
    );
  }
}

/// The level's number in a ring that fills as the model nears the next level, with a little bounce at a new level.
class _LevelRing extends StatelessWidget {
  const _LevelRing({required this.level, required this.progress, required this.reduced});

  final int level;
  final double progress;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return SizedBox.square(
      dimension: 66,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(progress: value, colour: colors.primary, track: colors.line),
          child: child,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: reduced ? Duration.zero : const Duration(milliseconds: 420),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              child: child,
            ),
            child: Column(
              key: ValueKey(level),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$level',
                  style: displayFace(theme.textTheme.titleLarge)?.copyWith(color: colors.primary, height: 1),
                ),
                Text(
                  S.of(context).pocket_level_word,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted, height: 1.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.colour, required this.track});

  final double progress;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 5.0;
    final rect = (Offset.zero & size).deflate(width / 2 + 1);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    // A bead at the arc's head.
    final head = -math.pi / 2 + sweep;
    final centre = rect.center + Offset(math.cos(head), math.sin(head)) * (rect.width / 2);
    canvas
      ..drawCircle(centre, width * 0.95, Paint()..color = colour)
      ..drawCircle(centre, width * 0.4, Paint()..color = track);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.colour != colour || old.track != track;
}

/// The road of levels, one pip for each after the first: the ones reached filled, the next one waiting.
class _LevelRoad extends StatelessWidget {
  const _LevelRoad({required this.level, required this.reduced});

  final int level;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return ExcludeSemantics(
      child: Row(
        spacing: 4,
        children: [
          for (var i = 1; i < PocketModel.levels.length; i++)
            Expanded(
              child: AnimatedContainer(
                duration: reduced ? Duration.zero : Duration(milliseconds: 260 + 40 * i),
                curve: Curves.easeOutCubic,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= level ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: i <= level ? colors.primary : (i == level + 1 ? colors.lineStrong : colors.line),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The training loss as a chart, as a training run draws it: the curve from the first token to now, falling, with a
/// mark where each level was reached and the loss now in a pill. It grows with each feed.
class LossChart extends StatelessWidget {
  const LossChart({super.key, required this.tokens});

  final int tokens;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final language = Localizations.localeOf(context).languageCode;
    final loss = NumberFormat('0.00', language).format(PocketModel.lossAt(tokens));
    return Semantics(
      container: true,
      label: tokens > 0 ? '${s.pocket_loss_title}, ${s.pocket_loss(loss)}' : s.pocket_loss_title,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, size: 16, color: colors.onSurfaceMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.pocket_loss_title,
                      style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurface),
                    ),
                  ),
                  if (tokens > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Directionality.of(context) == TextDirection.rtl ? Icons.south_west : Icons.south_east,
                              size: 13,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(loss, style: theme.textTheme.labelMedium?.copyWith(color: colors.primary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 76,
                child: tokens == 0
                    ? Center(
                        child: Text(
                          s.pocket_loss_empty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
                        ),
                      )
                    : TweenAnimationBuilder<double>(
                        tween: Tween(end: tokens.toDouble()),
                        duration: reduced ? Duration.zero : const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => CustomPaint(
                          size: Size.infinite,
                          painter: LossChartPainter(
                            tokens: value,
                            colour: colors.primary,
                            grid: colors.line,
                            mark: colors.onSurfaceFaint,
                            mirrored: Directionality.of(context) == TextDirection.rtl,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the loss from the first token to [tokens]; the levels reached on the way are marked on the curve.
class LossChartPainter extends CustomPainter {
  LossChartPainter({
    required this.tokens,
    required this.colour,
    required this.grid,
    required this.mark,
    this.mirrored = false,
  });

  final double tokens;
  final Color colour;
  final Color grid;
  final Color mark;

  /// A right-to-left language reads time from the right, so the curve runs from the right.
  final bool mirrored;

  static const _points = 40;

  /// The levels reached by [tokens], whose places the chart marks.
  static List<int> marks(double tokens) => [
    for (final at in PocketModel.levels.skip(1))
      if (at <= tokens) at,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (tokens <= 0 || size.isEmpty) return;
    if (mirrored) {
      canvas
        ..save()
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    const top = 6.0;
    final bottom = size.height - 4;
    final highest = PocketModel.lossAt(0);
    final lowest = math.min(PocketModel.lossAt(tokens.round()), highest - 0.01);
    double yOf(double loss) => top + (1 - (loss - lowest) / (highest - lowest)) * (bottom - top);
    // Room at the ends for the beads.
    const inset = 9.0;
    double xOf(double at) => inset + at / tokens * (size.width - 2 * inset);
    Offset point(double at) => Offset(xOf(at), yOf(PocketModel.lossAt(at.round())));

    // The grid: three dashed rules.
    final rule = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var n = 0; n < 3; n++) {
      final y = top + (bottom - top) * n / 2;
      for (var x = 0.0; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width), y), rule);
      }
    }

    final line = Path();
    for (var i = 0; i < _points; i++) {
      final p = point(tokens * i / (_points - 1));
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(xOf(tokens), bottom)
      ..lineTo(xOf(0), bottom)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bottom), [
            colour.withValues(alpha: 0.28),
            colour.withValues(alpha: 0),
          ]),
      )
      ..drawPath(
        line,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

    // A tick and a bead where each level was reached.
    final tick = Paint()
      ..color = mark.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (final at in marks(tokens)) {
      final p = point(at.toDouble());
      for (var y = p.dy + 5; y < bottom; y += 5) {
        canvas.drawLine(Offset(p.dx, y), Offset(p.dx, math.min(y + 2, bottom)), tick);
      }
      canvas
        ..drawCircle(p, 3.6, Paint()..color = colour)
        ..drawCircle(p, 1.6, Paint()..color = grid);
    }

    // Now: a bead in a soft halo.
    final now = point(tokens);
    canvas
      ..drawCircle(now, 9, Paint()..color = colour.withValues(alpha: 0.16))
      ..drawCircle(now, 4.2, Paint()..color = colour);
    if (mirrored) canvas.restore();
  }

  @override
  bool shouldRepaint(LossChartPainter old) =>
      old.tokens != tokens || old.colour != colour || old.grid != grid || old.mark != mark || old.mirrored != mirrored;
}
