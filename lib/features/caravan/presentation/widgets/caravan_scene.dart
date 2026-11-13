import 'dart:math' as math;

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/caravan_icon.dart';
import 'package:flutter/widgets.dart';

/// The Caravan page's picture: three camels walk in over the dunes at dusk and stop, under a low sun and the first stars.
/// They walk once, the way the reader reads, and stand still at once when the platform asks for reduced motion.
/// Decoration only, so it is hidden from assistive technology. The colours are the bazaar's fixed ones, the same in
/// both themes, as the bar's are.
class CaravanScene extends StatefulWidget {
  const CaravanScene({super.key});

  /// How long the caravan takes to walk in.
  static const Duration walk = Duration(milliseconds: 2600);

  @override
  State<CaravanScene> createState() => _CaravanSceneState();
}

class _CaravanSceneState extends State<CaravanScene> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final duration = motionDuration(context, CaravanScene.walk);
    if (duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = duration
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mirrored = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.infinite,
        painter: CaravanScenePainter(progress: _progress, mirrored: mirrored),
      ),
    );
  }
}

/// Paints the dusk, the dunes and the caravan; [progress] runs from the caravan out of sight (0) to the caravan in
/// place (1).
class CaravanScenePainter extends CustomPainter {
  CaravanScenePainter({required this.progress, required this.mirrored}) : super(repaint: progress);

  final Animation<double> progress;

  /// Whether the scene is drawn for a right-to-left language, the caravan walking left.
  final bool mirrored;

  static const Color _sky = BazaarFixedColors.bar;
  static const Color _gold = BazaarFixedColors.ornament;
  static final Color _dusk = Color.lerp(_sky, _gold, 0.42)!;
  static final Color _farDune = Color.lerp(_sky, _gold, 0.30)!;
  static final Color _nearDune = Color.lerp(_gold, BazaarFixedColors.caution, 0.35)!;
  static final Color _camel = Color.lerp(_sky, const Color(0xff000000), 0.25)!;

  /// The stars, as fractions of the width and of the sky's height, with a radius each.
  static const List<(double, double, double)> _stars = [
    (0.06, 0.18, 1.2),
    (0.14, 0.42, 0.8),
    (0.21, 0.12, 1.0),
    (0.29, 0.30, 1.4),
    (0.37, 0.08, 0.8),
    (0.44, 0.38, 1.0),
    (0.52, 0.16, 1.2),
    (0.58, 0.46, 0.8),
    (0.63, 0.06, 1.0),
    (0.83, 0.10, 1.4),
    (0.90, 0.34, 0.8),
    (0.95, 0.20, 1.0),
    (0.10, 0.60, 0.8),
    (0.34, 0.56, 0.8),
    (0.77, 0.28, 0.8),
  ];

  /// The ridge of the near dune, where the camels walk, at [x] across a scene of [size].
  static double ridge(double x, Size size) =>
      size.height * 0.80 - size.height * 0.07 * math.sin(2 * math.pi * x / size.width * 0.9 + 0.5);

  static double _farRidge(double x, Size size) =>
      size.height * 0.66 - size.height * 0.08 * math.sin(2 * math.pi * x / size.width * 1.3 + 2.2);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_sky, _sky, _dusk],
          stops: const [0, 0.35, 0.8],
        ).createShader(rect),
    );

    final star = Paint()..color = const Color(0xffffffff).withValues(alpha: 0.7);
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(Offset(x * size.width, y * size.height * 0.7), r, star);
    }

    // The low sun, with its glow, half behind the far dune.
    final sun = Offset(size.width * 0.74, size.height * 0.60);
    final sunRadius = size.height * 0.17;
    canvas.drawCircle(
      sun,
      sunRadius * 2.4,
      Paint()
        ..shader = RadialGradient(colors: [_gold.withValues(alpha: 0.45), _gold.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: sun, radius: sunRadius * 2.4)),
    );
    canvas.drawCircle(sun, sunRadius, Paint()..color = Color.lerp(_gold, const Color(0xffffffff), 0.25)!);

    canvas.drawPath(_dune(size, _farRidge), Paint()..color = _farDune);
    canvas.drawPath(_dune(size, ridge), Paint()..color = _nearDune);

    _caravan(canvas, size, progress.value);
    canvas.restore();
  }

  Path _dune(Size size, double Function(double, Size) top) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      path.lineTo(x, top(x, size));
    }
    return path
      ..lineTo(size.width, top(size.width, size))
      ..lineTo(size.width, size.height)
      ..close();
  }

  /// The three camels, the leader biggest, walking in from the left edge to stand left of the sun, with their trail.
  void _caravan(Canvas canvas, Size size, double t) {
    final camel = size.height * 0.28;
    final gap = camel * 1.08;
    final lead = size.width * 0.54;
    final start = -gap * 3;
    final x = start + (lead - start) * t;
    // A step's rise and fall while they walk, gone when they stop.
    final step = math.sin(t * math.pi * 14).abs() * (1 - t) * camel * 0.05;

    final trail = Paint()..color = _camel.withValues(alpha: 0.35);
    final back = x - gap * 2 - camel * 0.3;
    for (var i = 0; i < 9; i++) {
      final fx = back - i * camel * 0.32;
      if (fx < 0) break;
      canvas.drawCircle(Offset(fx, ridge(fx, size) + 3), camel * 0.035 * (1 - i / 10), trail);
    }

    final paint = Paint()..color = _camel;
    for (var i = 0; i < 3; i++) {
      final scale = (i == 0 ? camel : camel * 0.88) / 24;
      final cx = x - gap * i;
      final feet = ridge(cx, size) + 2 - (i.isEven ? step : 0);
      canvas
        ..save()
        ..translate(cx - 12 * scale, feet - 21 * scale)
        ..scale(scale)
        ..drawPath(CamelPainter.camel, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(CaravanScenePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mirrored != mirrored;
}
