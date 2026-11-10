import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_art.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The opening while the app starts (plan 1Y, 1Z, 1AA), on every launch, over the whole screen in front of [child]: an
/// animation only, with no words and no button. On the bar's navy a bazaar gate draws itself, its red and cream
/// voussoirs running down from the apex; the tiled wall around it comes up in a ripple from the gate; the lattice band
/// runs out along its threshold; two lamps drop on their cords and swing; the light comes up inside the arch and the
/// Lokum logo pops in it. Once that has played and the content and the record have settled, the reader walks in: the
/// arch grows past the edges of the screen and the app is there inside it.
///
/// The launch screens are the same navy, so the start reads as one piece. Under reduced motion it is drawn in place
/// and gives way as soon as the app is ready (spec 3.10). It is decoration, hidden from assistive technology.
class WelcomeSplash extends StatefulWidget {
  const WelcomeSplash({super.key, required this.child});

  final Widget child;

  /// How long the gate takes to come in when motion is allowed.
  static const entrance = Duration(milliseconds: 2200);

  /// The key of the opening while it stands over the app.
  static const sceneKey = Key('welcome-splash');

  /// How long the walk through the arch takes.
  static const exit = Duration(milliseconds: 750);

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash> with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _walk;
  bool _played = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: WelcomeSplash.entrance)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _played = true);
      });
    _walk = AnimationController(vsync: this, duration: WelcomeSplash.exit)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _gone = true);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 1;
      _played = true;
    } else if (_motion.status == AnimationStatus.dismissed) {
      unawaited(_motion.forward());
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The app is ready once the content and the record have settled, or the content cannot be opened at all.
    final ready = switch ((context.watch<ContentBloc>().state, context.watch<RecordBloc>().state)) {
      (ContentBroken(), _) => true,
      (ContentReady(), RecordReady()) => true,
      _ => false,
    };
    final leaving = _played && ready;
    final still = MediaQuery.disableAnimationsOf(context);
    if (leaving && !still && _walk.status == AnimationStatus.dismissed) {
      // Started after this frame, so the walk begins from the gate as drawn.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _walk.status == AnimationStatus.dismissed) unawaited(_walk.forward());
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // The app builds behind the opening, so it is in place when the arch opens onto it.
        widget.child,
        // Under reduced motion there is no walk to wait for: the opening is gone once the app is ready.
        if (!_gone && !(leaving && still))
          IgnorePointer(
            ignoring: leaving,
            child: _Opening(key: WelcomeSplash.sceneKey, motion: _motion, walk: _walk),
          ),
      ],
    );
  }
}

/// The gate's red voussoirs, as the web's gate draws them.
const _brick = Color(0xffa0503c);

/// The gate's cream voussoirs and the light in the arch.
const _cream = Color(0xfff6eee0);
const _light = Color(0xffffe6b0);

/// Where the gate stands on a screen of [size].
class _Geometry {
  _Geometry(Size size) {
    final width = math.min(math.min(size.width * 0.56, 260.0), size.height * 0.5 / _ratio);
    final height = width * _ratio;
    arch = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.47), width: width, height: height);
  }

  /// The gate's height over its width.
  static const double _ratio = 1.45;

  late final Rect arch;

  /// The middle of the arch, where the light stands and the walk heads for.
  Offset get heart => Offset(arch.center.dx, arch.top + arch.height * 0.45);

  /// The arch's line from the foot of its left side over the apex to the foot of its right side.
  Path outline() {
    final r = arch;
    final spring = r.top + r.width * 0.62;
    final rise = spring - r.top;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, spring)
      ..cubicTo(r.left, r.top + rise * 0.35, r.center.dx - r.width * 0.2, r.top + rise * 0.1, r.center.dx, r.top)
      ..cubicTo(r.center.dx + r.width * 0.2, r.top + rise * 0.1, r.right, r.top + rise * 0.35, r.right, spring)
      ..lineTo(r.right, r.bottom);
  }

  /// The opening inside the arch.
  Path opening() => outline()..close();
}

/// The opening over the whole screen, and the walk through the arch on [walk].
class _Opening extends StatelessWidget {
  const _Opening({super.key, required this.motion, required this.walk});

  final Animation<double> motion;
  final Animation<double> walk;

  @override
  Widget build(BuildContext context) {
    final into = CurvedAnimation(parent: walk, curve: Curves.easeInCubic);
    // The status bar lies over the navy, so its icons are light.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final geometry = _Geometry(size);
            final heart = Alignment(geometry.heart.dx / size.width * 2 - 1, geometry.heart.dy / size.height * 2 - 1);
            return AnimatedBuilder(
              animation: into,
              builder: (context, child) {
                final t = into.value;
                if (t == 0) return child!;
                // The arch grows past the screen's edges; the app shows through it, the light inside fading first.
                return Transform.scale(
                  scale: 1 + 9 * t,
                  alignment: heart,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipPath(
                        clipper: _Around(geometry),
                        child: _Wall(motion: motion, geometry: geometry),
                      ),
                      Opacity(
                        // Faded on the walk's own clock, so the light is gone before the arch has grown much.
                        opacity: (1 - walk.value * 2.5).clamp(0, 1),
                        child: ClipPath(
                          clipper: _Inside(geometry),
                          child: _Wall(motion: motion, geometry: geometry),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: _Wall(motion: motion, geometry: geometry),
            );
          },
        ),
      ),
    );
  }
}

/// Everything but the opening inside the arch.
class _Around extends CustomClipper<Path> {
  const _Around(this.geometry);

  final _Geometry geometry;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addPath(geometry.opening(), Offset.zero);

  @override
  bool shouldReclip(_Around oldClipper) => oldClipper.geometry.arch != geometry.arch;
}

/// The opening inside the arch.
class _Inside extends CustomClipper<Path> {
  const _Inside(this.geometry);

  final _Geometry geometry;

  @override
  Path getClip(Size size) => geometry.opening();

  @override
  bool shouldReclip(_Inside oldClipper) => oldClipper.geometry.arch != geometry.arch;
}

/// The navy wall with its tiles, the gate, the threshold band, the lamps and the logo, coming in on [motion].
class _Wall extends StatelessWidget {
  const _Wall({required this.motion, required this.geometry});

  final Animation<double> motion;
  final _Geometry geometry;

  /// The tallest person's height.
  static const double _people = 96;

  /// Each person's height as a share of the tallest, from the left.
  static const _heights = [0.86, 1.0, 0.95, 0.84, 0.9];

  Animation<double> _part(double begin, double end, {Curve curve = BazaarMotion.bazaar}) => CurvedAnimation(
    parent: motion,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final arch = geometry.arch;
    final band = _part(0, 0.32);
    final logo = _part(0.55, 0.85, curve: Curves.easeOutBack);
    final logoIn = _part(0.55, 0.7, curve: Curves.easeOut);
    final logoSide = arch.width * 0.46;
    final lampX = arch.left / 2;
    return ColoredBox(
      color: BazaarFixedColors.bar,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _GatePainter(
              geometry: geometry,
              tiles: _part(0.18, 0.75, curve: Curves.linear),
              draw: _part(0.04, 0.5, curve: Curves.easeInOut),
              glow: _part(0.42, 0.85, curve: Curves.easeOut),
            ),
          ),
          // The lattice band runs out along the threshold from the gate's foot to both edges.
          Positioned(
            top: arch.bottom,
            left: 0,
            right: 0,
            height: LatticeBand.height,
            child: AnimatedBuilder(
              animation: band,
              builder: (context, child) => ClipRect(clipper: _Middle(band.value), child: child),
              child: CustomPaint(painter: LatticeBandPainter(bandC: context.bazaarColors.bandC)),
            ),
          ),
          Positioned(
            top: 0,
            left: lampX - _Lamp.width / 2,
            child: _Lamp(
              art: WelcomeArt.lampLeft,
              height: 176,
              cord: arch.top * 0.55,
              drop: _part(0.32, 0.58, curve: Curves.easeOutCubic),
              swing: _part(0.55, 1, curve: Curves.linear),
            ),
          ),
          Positioned(
            top: 0,
            right: lampX - _Lamp.width / 2,
            child: _Lamp(
              art: WelcomeArt.lampRight,
              height: 132,
              cord: arch.top * 0.55 + 24,
              drop: _part(0.4, 0.66, curve: Curves.easeOutCubic),
              swing: _part(0.62, 1, curve: Curves.linear),
              phase: -1,
            ),
          ),
          // The light spilling out of the gate onto the floor.
          Positioned(
            top: arch.bottom + LatticeBand.height,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _part(0.5, 0.9),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.7,
                    colors: [Color(0x40ffe6b0), Color(0x00ffe6b0)],
                  ),
                ),
              ),
            ),
          ),
          // The people of the bazaar step onto the threshold one after the other.
          Positioned(
            top: arch.bottom - _Wall._people,
            left: 0,
            right: 0,
            height: _Wall._people,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                for (final (position, art) in WelcomeArt.cast.indexed)
                  _Rise(
                    animation: _part(0.6 + 0.06 * position, 0.76 + 0.06 * position, curve: Curves.easeOutBack),
                    child: Image(
                      image: AssetImage(art),
                      height: _Wall._people * _heights[position],
                      width: _Wall._people * _heights[position] * 330 / 600,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: geometry.heart.dx - logoSide / 2,
            top: geometry.heart.dy - logoSide / 2,
            width: logoSide,
            height: logoSide,
            child: FadeTransition(
              opacity: logoIn,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.4, end: 1).animate(logo),
                child: const Image(image: AssetImage(WelcomeArt.logo), filterQuality: FilterQuality.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tiled wall rippling in from the gate on [tiles], the arch drawing itself from the apex down on [draw], and the
/// light inside it on [glow].
class _GatePainter extends CustomPainter {
  _GatePainter({required this.geometry, required this.tiles, required this.draw, required this.glow})
    : super(repaint: Listenable.merge([tiles, draw, glow]));

  final _Geometry geometry;
  final Animation<double> tiles;
  final Animation<double> draw;
  final Animation<double> glow;

  /// The spacing of the wall's tiles.
  static const double _tile = 34;

  /// The length of one voussoir along the arch.
  static const double _stone = 15;

  static const double _ring = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final opening = geometry.opening();
    _paintTiles(canvas, size, opening);
    _paintLight(canvas, opening);
    _paintArch(canvas);
  }

  void _paintTiles(Canvas canvas, Size size, Path opening) {
    final heart = geometry.heart;
    final reach = math.sqrt(size.width * size.width + size.height * size.height) * 0.75;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dot = Paint();
    for (var row = 0; row * _tile < size.height + _tile; row++) {
      for (var column = 0; column * _tile < size.width + _tile; column++) {
        // Every other row is offset half a tile, as the gate's wall.
        final centre = Offset(column * _tile + (row.isOdd ? _tile / 2 : 0), row * _tile + _tile / 2);
        if (opening.contains(centre)) continue;
        final delay = ((centre - heart).distance / reach).clamp(0.0, 1.0) * 0.7;
        final shown = ((tiles.value - delay) / 0.3).clamp(0.0, 1.0);
        if (shown == 0) continue;
        final r = 7.0 * shown;
        outline.color = BazaarFixedColors.bandA.withValues(alpha: 0.55 * shown);
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx, centre.dy - r)
            ..lineTo(centre.dx + r, centre.dy)
            ..lineTo(centre.dx, centre.dy + r)
            ..lineTo(centre.dx - r, centre.dy)
            ..close(),
          outline,
        );
        dot.color = BazaarFixedColors.ornament.withValues(alpha: 0.6 * shown);
        canvas.drawCircle(centre, 1.6 * shown, dot);
      }
    }
  }

  void _paintLight(Canvas canvas, Path opening) {
    if (glow.value == 0) return;
    final arch = geometry.arch;
    canvas.save();
    canvas.clipPath(opening);
    canvas.drawRect(
      arch,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, (geometry.heart.dy - arch.center.dy) / (arch.height / 2)),
          radius: 1.1,
          colors: [
            _light.withValues(alpha: glow.value),
            _light.withValues(alpha: 0.5 * glow.value),
            _light.withValues(alpha: 0.14 * glow.value),
          ],
          stops: const [0, 0.4, 1],
        ).createShader(arch),
    );
    canvas.restore();
  }

  void _paintArch(Canvas canvas) {
    if (draw.value == 0) return;
    final metric = geometry.outline().computeMetrics().first;
    final middle = metric.length / 2;
    final from = middle * (1 - draw.value);
    final to = metric.length - from;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ring
      ..strokeCap = StrokeCap.butt
      ..color = _cream;
    canvas.drawPath(metric.extractPath(from, to), ring);
    // The red voussoirs, every other stone, counted from the apex so the two sides match.
    final brick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ring
      ..color = _brick;
    for (var start = _stone / 2; middle - start > 0; start += _stone * 2) {
      for (final (a, b) in [(middle + start, middle + start + _stone), (middle - start - _stone, middle - start)]) {
        final lo = math.max(a, from);
        final hi = math.min(b, to);
        if (hi > lo) canvas.drawPath(metric.extractPath(lo, hi), brick);
      }
    }
    // The ornament lines along both edges of the ring.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = BazaarFixedColors.ornament;
    for (final offset in [-_ring / 2, _ring / 2]) {
      final shifted = _offsetOutline(offset);
      final m = shifted.computeMetrics().first;
      final half = m.length / 2;
      canvas.drawPath(m.extractPath(half * (1 - draw.value), m.length - half * (1 - draw.value)), edge);
    }
  }

  /// The arch's line moved [offset] outwards (negative inwards), as a scaled copy about the arch's foot.
  Path _offsetOutline(double offset) {
    final arch = geometry.arch;
    final scaleX = (arch.width + offset * 2) / arch.width;
    final scaleY = (arch.height + offset) / arch.height;
    final matrix = Matrix4.identity()
      ..translateByDouble(arch.center.dx, arch.bottom, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1, 1)
      ..translateByDouble(-arch.center.dx, -arch.bottom, 0, 1);
    return geometry.outline().transform(matrix.storage);
  }

  @override
  bool shouldRepaint(_GatePainter oldDelegate) => oldDelegate.geometry.arch != geometry.arch;
}

/// A lamp that drops in on its [cord] from the top of the screen on [drop], then swings, less each time, to rest.
class _Lamp extends StatelessWidget {
  const _Lamp({
    required this.art,
    required this.height,
    required this.cord,
    required this.drop,
    required this.swing,
    this.phase = 1,
  });

  final String art;
  final double height;
  final double cord;
  final Animation<double> drop;
  final Animation<double> swing;

  /// 1 swings right first, -1 left first.
  final double phase;

  static const double width = 96;

  /// The widest swing, in radians (about 7 degrees).
  static const double _amplitude = 0.12;

  @override
  Widget build(BuildContext context) {
    final lamp = SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 1.5, height: math.max(cord, 0), color: BazaarFixedColors.ornament),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // The lamp's own light on the wall.
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x66ffd27a), Color(0x00ffd27a)]),
                ),
                child: SizedBox.square(dimension: width),
              ),
              Image(image: AssetImage(art), height: height, filterQuality: FilterQuality.medium),
            ],
          ),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([drop, swing]),
      builder: (context, child) {
        final t = swing.value;
        // Two and a half swings that die down to rest.
        final angle = phase * _amplitude * (1 - t) * math.sin(t * math.pi * 5);
        return Transform.translate(
          offset: Offset(0, -(cord + height * 1.2) * (1 - drop.value)),
          child: Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child),
        );
      },
      child: lamp,
    );
  }
}

/// The middle [fraction] of the box's width.
class _Middle extends CustomClipper<Rect> {
  const _Middle(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromCenter(center: size.center(Offset.zero), width: size.width * fraction, height: size.height);

  @override
  bool shouldReclip(_Middle oldClipper) => oldClipper.fraction != fraction;
}

/// [child] fading in as it rises into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        // A curve that overshoots moves past its place and back; the opacity stops at full.
        opacity: animation.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 40 * (1 - animation.value)), child: child),
      ),
      child: child,
    );
  }
}
