import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/features/about/presentation/about_palette.dart';
import 'package:flutter/widgets.dart';

/// The story's ground, as the web's `.ground` (`src/app/about.css`): one colour over the whole screen that turns from
/// section to section, a fine grain over it and the edge of the lamp's reach in its corners, which fades at [dawn].
/// The colour turns at once under reduced motion.
class AboutGround extends StatelessWidget {
  const AboutGround({super.key, required this.color, this.dawn = false, required this.child});

  final Color color;
  final bool dawn;
  final Widget child;

  static const grain = 'assets/about/grain.png';

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final turn = still ? Duration.zero : const Duration(milliseconds: 1400);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: turn,
      curve: Curves.easeInOutSine,
      builder: (context, colour, child) => ColoredBox(color: colour ?? color, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decoration: the grain and the vignette carry nothing to read.
          const ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage(grain), repeat: ImageRepeat.repeat),
              ),
            ),
          ),
          ExcludeSemantics(
            child: AnimatedOpacity(
              opacity: dawn ? 0.25 : 1,
              duration: turn,
              child: const CustomPaint(painter: _Vignette()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A radial gradient over an ellipse of radii [rx] and [ry] about [center], with [colors] at [stops] of its radius.
ui.Gradient ellipseGradient(Offset center, double rx, double ry, List<Color> colors, List<double> stops) {
  final matrix = Matrix4.identity()
    ..translateByDouble(center.dx, center.dy, 0, 1)
    ..scaleByDouble(rx, ry, 1, 1);
  return ui.Gradient.radial(Offset.zero, 1, colors, stops, TileMode.clamp, matrix.storage);
}

/// The web's `radial-gradient(ellipse 80% 75% at 50% 50%, transparent 55%, vignette 100%)`.
class _Vignette extends CustomPainter {
  const _Vignette();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ellipseGradient(
          rect.center,
          size.width * 0.8,
          size.height * 0.75,
          const [Color(0x0004040c), AboutPalette.vignette],
          const [0.55, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_Vignette oldDelegate) => false;
}
