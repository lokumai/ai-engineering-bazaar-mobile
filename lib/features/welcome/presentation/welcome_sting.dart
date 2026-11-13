import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The opening while the app starts (plan 1Y, 1AA; the owner, 2026-11-13), on every launch, over the whole screen in
/// front of [child]: the app icon's mark, the striped secret agent (`assets/brand/app_icon/mark.svg`), on the app's
/// own page colour, light or dark. The mark stands still in the middle of the screen from the first frame. Once it has
/// held for [entrance] and the content and the record have settled, the camera flies into it, rolling a little: each
/// stripe splits into thinner ribbons that lie at different depths, and the ribbons rush past the viewer one after
/// another as the page gives way to the app.
///
/// The launch screens are the dark page colour, as the app opens dark until the reader chooses. Under reduced motion
/// the mark is drawn in place and gives way as soon as the app is ready (spec 3.10). It is decoration, hidden from
/// assistive technology.
class WelcomeSting extends StatefulWidget {
  const WelcomeSting({super.key, required this.child});

  final Widget child;

  /// How long the mark stands still before the flight can start: 0.5 s since 2026-11-14 (0.6 s before), so the whole
  /// opening takes 1.45 s (the owner).
  static const entrance = Duration(milliseconds: 500);

  /// How long the flight into the mark takes.
  static const exit = Duration(milliseconds: 950);

  /// The key of the opening while it stands over the app.
  static const sceneKey = Key('welcome-sting');

  @override
  State<WelcomeSting> createState() => _WelcomeStingState();
}

class _WelcomeStingState extends State<WelcomeSting> with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _flight;
  bool _played = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: WelcomeSting.entrance)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _played = true);
      });
    _flight = AnimationController(vsync: this, duration: WelcomeSting.exit)
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
    _flight.dispose();
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
    if (leaving && !still && _flight.status == AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _flight.status == AnimationStatus.dismissed) unawaited(_flight.forward());
      });
    }
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(enabled: leaving || _gone, child: widget.child),
        if (!_gone && !(leaving && still))
          IgnorePointer(
            key: WelcomeSting.sceneKey,
            ignoring: leaving,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              // The status bar lies over the page colour.
              value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: Colors.transparent,
              ),
              child: ExcludeSemantics(
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: StingPainter(motion: _motion, flight: _flight, page: theme.scaffoldBackgroundColor),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The mark's colours, as `mark.svg` paints them.
const _teal = Color(0xff2f8c86);
const _gold = Color(0xffc8a078);
const _brick = Color(0xffa0503c);

/// One thin ribbon of a stripe: its edges along the mark's bottom edge, the depth it lies at and its shade.
class _Ribbon {
  const _Ribbon(this.left, this.right, this.depth, this.colour, this.shade);

  final double left;
  final double right;

  /// 1 is the mark's own plane; a ribbon further back passes the viewer later.
  final double depth;
  final Color colour;

  /// From -1 (darker) to 1 (lighter), shown more as the flight goes on.
  final double shade;
}

/// The striped secret agent of `mark.svg` in its 200 x 200 units: a fedora tilted forward and to the side, a faceless
/// head, a coat with its collar up and lapels, and a brick tie.
@visibleForTesting
abstract final class AgentMark {
  static final Path _crown2 = Path()
    ..moveTo(70, 64)
    ..cubicTo(70, 40, 76, 24, 88, 22)
    ..cubicTo(94, 21, 97, 28, 100, 28)
    ..cubicTo(103, 28, 106, 21, 112, 22)
    ..cubicTo(124, 24, 130, 40, 130, 64)
    ..close();
  static final Path _brim2 = Path()
    ..moveTo(28, 70)
    ..cubicTo(36, 63, 70, 61, 100, 61)
    ..cubicTo(130, 61, 164, 63, 172, 70)
    ..cubicTo(164, 76, 130, 77, 100, 77)
    ..cubicTo(70, 77, 36, 76, 28, 70)
    ..close();
  static final Path _band2 = Path()
    ..moveTo(70, 55)
    ..cubicTo(84, 58, 116, 58, 130, 55)
    ..lineTo(130, 62)
    ..cubicTo(116, 65, 84, 65, 70, 62)
    ..close();
  static final Path _gap2 = Path()
    ..moveTo(58, 76)
    ..cubicTo(76, 80, 124, 80, 142, 76)
    ..lineTo(142, 82)
    ..lineTo(58, 82)
    ..close();
  static final Path _head2 = Path()
    ..moveTo(74, 80)
    ..lineTo(126, 80)
    ..lineTo(126, 100)
    ..cubicTo(126, 118, 113, 130, 100, 130)
    ..cubicTo(87, 130, 74, 118, 74, 100)
    ..close();
  static final Path _body = Path()
    ..moveTo(22, 196)
    ..cubicTo(24, 164, 38, 148, 68, 138)
    ..lineTo(86, 132)
    ..lineTo(100, 146)
    ..lineTo(114, 132)
    ..lineTo(132, 138)
    ..cubicTo(162, 148, 176, 164, 178, 196)
    ..close();
  static final Path _collarL = Path()
    ..moveTo(86, 132)
    ..lineTo(70, 112)
    ..lineTo(66, 136)
    ..close();
  static final Path _collarR = Path()
    ..moveTo(114, 132)
    ..lineTo(130, 112)
    ..lineTo(134, 136)
    ..close();
  static final Path _shirt = Path()
    ..moveTo(86, 134)
    ..lineTo(100, 150)
    ..lineTo(114, 134)
    ..lineTo(118, 137)
    ..lineTo(100, 196)
    ..lineTo(82, 137)
    ..close();
  static final Path _lapelL = Path()
    ..moveTo(68, 140)
    ..lineTo(74, 138)
    ..lineTo(95, 196)
    ..lineTo(87, 196)
    ..close();
  static final Path _lapelR = Path()
    ..moveTo(132, 140)
    ..lineTo(126, 138)
    ..lineTo(105, 196)
    ..lineTo(113, 196)
    ..close();
  static final Path _tie = Path()
    ..moveTo(96, 150)
    ..lineTo(104, 150)
    ..lineTo(106, 158)
    ..lineTo(102, 188)
    ..lineTo(98, 188)
    ..lineTo(94, 158)
    ..close();

  /// The hat's tilt: 9 degrees about the brim's middle, and 6 units down.
  static final Float64List _tilt =
      (Matrix4.identity()
            ..translateByDouble(100, 72, 0, 1)
            ..rotateZ(-9 * math.pi / 180)
            ..translateByDouble(-100, -72, 0, 1)
            ..translateByDouble(0, 6, 0, 1))
          .storage;

  /// Where the stripes show, as the mask of `mark.svg` cuts it.
  static final Path shape = () {
    Path union(Iterable<Path> paths) => paths.reduce((a, b) => Path.combine(PathOperation.union, a, b));
    final hat = Path.combine(PathOperation.difference, union([_crown2, _brim2]), _band2).transform(_tilt);
    final solid = union([_head2, _body, _collarL, _collarR, hat]);
    final holes = union([_gap2.transform(_tilt), _shirt, _lapelL, _lapelR]);
    return Path.combine(
      PathOperation.union,
      Path.combine(PathOperation.difference, solid, holes),
      _brim2.transform(_tilt),
    );
  }();

  /// The tie, painted brick over the stripes.
  static Path get tie => _tie;
}

/// Paints the sting on the [page] colour at the [flight]'s progress, in the mark's own 200 x 200 units, seen through a
/// camera that moves into the screen. [motion] is the hold before the flight; the mark does not move during it.
@visibleForTesting
class StingPainter extends CustomPainter {
  StingPainter({required this.motion, required this.flight, required this.page})
    : super(repaint: Listenable.merge([motion, flight]));

  final Animation<double> motion;
  final Animation<double> flight;
  final Color page;

  /// The point the camera flies at, in the agent's head; it is also the middle of the screen.
  static const Offset _focus = Offset(100, 108);

  /// The mark's width, shoulder to shoulder, which sets its size on the screen.
  static const double _width = 156;

  /// How far the camera travels, past the deepest ribbon.
  static const double _travel = 2.05;

  /// The mark's 30 stripes, each 13 units of colour every 19 along its bottom edge (y 220), and the thinner ribbons
  /// each splits into, edge to edge (a hair over, so no seam shows while they lie together).
  static final List<_Ribbon> _ribbons = () {
    const colours = [_teal, _gold, _brick];
    const cuts = [0.0, 3.5, 6.0, 10.0, 13.0];
    final random = math.Random(7);
    return [
      for (var i = 0; i < 30; i++)
        for (var j = 0; j < cuts.length - 1; j++)
          _Ribbon(
            -260 + 19.0 * i + cuts[j] - 0.15,
            -260 + 19.0 * i + cuts[j + 1] + 0.15,
            1.05 + 0.9 * random.nextDouble(),
            colours[i % 3],
            random.nextDouble() * 2 - 1,
          ),
    ];
  }();

  static double _span(double t, double begin, double end) => ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final f = flight.value;
    // The page fades onto the app once the ribbons have the screen.
    final pageLeft = 1 - Curves.easeIn.transform(_span(f, 0.45, 0.85));
    if (pageLeft > 0) canvas.drawRect(Offset.zero & size, Paint()..color = page.withValues(alpha: page.a * pageLeft));

    // The agent stands about three fifths of a phone's width.
    final base = math.min(size.width * 0.6, size.height * 0.34) / _width;
    // The camera starts slowly and gathers speed, as a push in.
    final camera = _travel * (Curves.easeInCubic.transform(f) * 0.7 + f * 0.3);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    // The camera rolls a little as it gathers speed.
    canvas.rotate(-0.12 * Curves.easeIn.transform(f));
    final paint = Paint();
    // The agent's outline frames everything until the camera is through it; the tie goes first.
    Path? tie;
    if (camera < 0.97) {
      final at = _at(base / (1 - camera));
      canvas.clipPath(AgentMark.shape.transform(at));
      tie = AgentMark.tie.transform(at);
    }
    for (final ribbon in _ribbons) {
      final ahead = ribbon.depth - camera;
      // A ribbon fades out as it reaches the viewer, and is gone once passed.
      final near = _span(ahead, 0, 0.22);
      if (near == 0) continue;
      final colour = _shade(ribbon.colour, ribbon.shade * _span(f, 0, 0.4) * 0.15);
      final path = _ribbon(ribbon.left, ribbon.right);
      // A faint trail behind each ribbon while it moves, from where it was a moment ago.
      if (f > 0) {
        final before = ribbon.depth - math.max(camera - 0.05, 0);
        paint.color = colour.withValues(alpha: near * 0.18);
        canvas.drawPath(path.transform(_at(base * ribbon.depth / before)), paint);
      }
      paint.color = colour.withValues(alpha: near);
      canvas.drawPath(path.transform(_at(base * ribbon.depth / ahead)), paint);
    }
    final tieLeft = 1 - _span(f, 0, 0.22);
    if (tie != null && tieLeft > 0) canvas.drawPath(tie, paint..color = _brick.withValues(alpha: tieLeft));
    canvas.restore();
  }

  /// The band from [left] to [right] along the mark's bottom edge (y 220), running up to the right, far past the mark
  /// both ways, so its ends never show as the camera comes close.
  static Path _ribbon(double left, double right) => Path()
    ..moveTo(left - 680, 900)
    ..lineTo(right - 680, 900)
    ..lineTo(right + 920, -700)
    ..lineTo(left + 920, -700)
    ..close();

  /// The mark's units to the screen's, at [scale] about the focus, the screen's middle at the origin.
  static Float64List _at(double scale) =>
      (Matrix4.identity()
            ..scaleByDouble(scale, scale, 1, 1)
            ..translateByDouble(-_focus.dx, -_focus.dy, 0, 1))
          .storage;

  static Color _shade(Color colour, double amount) =>
      amount >= 0 ? Color.lerp(colour, Colors.white, amount)! : Color.lerp(colour, Colors.black, -amount)!;

  @override
  bool shouldRepaint(StingPainter oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.flight != flight || oldDelegate.page != page;
}
