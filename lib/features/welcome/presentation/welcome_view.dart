import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The pictures of the Welcome screen (`assets/welcome/SOURCE.md`).
abstract final class WelcomeArt {
  static const gate = 'assets/welcome/gate.webp';
  static const cast = [
    'assets/welcome/cast_mihri.webp',
    'assets/welcome/cast_dariush.webp',
    'assets/welcome/cast_bit.webp',
    'assets/welcome/cast_mei.webp',
    'assets/welcome/cast_piri.webp',
  ];
  static const lampLeft = 'assets/welcome/lamp_left.webp';
  static const lampRight = 'assets/welcome/lamp_right.webp';
}

/// The Welcome screen, laid out as the team's mockup draws it (plan 1K): the gate cropped to its centre with a light in
/// its arch, reaching the top of the screen under the status bar (plan 1S), two lamps hanging at the corners, the
/// people of the web's home page in front of it, the line that says what the course is, its lead line, Enter the
/// bazaar, and the maker's mark.
///
/// The gate opens, the lamps drop and swing, the people step in one after the other and the words rise. Then, for
/// [ambience], the light in the arch breathes, the lamps sway a little and motes of light rise through the gate, fading
/// to rest (plan 1S). Under reduced motion everything is drawn in place at once and nothing moves (spec 3.10). The
/// pictures are decoration, hidden from assistive technology.
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key, required this.onEnter});

  final VoidCallback onEnter;

  /// How long the entrance takes when motion is allowed.
  static const entrance = Duration(milliseconds: 2600);

  /// How long the scene stays alive after the entrance, before it comes to rest.
  static const ambience = Duration(seconds: 12);

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with TickerProviderStateMixin {
  late final AnimationController _ambience;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    // Both are made here, not on first use, so each ticker is set up before a frame runs.
    _ambience = AnimationController(vsync: this, duration: WelcomeView.ambience);
    _motion = AnimationController(vsync: this, duration: WelcomeView.entrance)
      // The scene comes alive once the entrance ends, unless motion is reduced.
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && !MediaQuery.disableAnimationsOf(context)) {
          unawaited(_ambience.forward());
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 1;
      _ambience.stop();
      _ambience.value = 0;
    } else if (_motion.status == AnimationStatus.dismissed) {
      unawaited(_motion.forward());
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _ambience.dispose();
    super.dispose();
  }

  /// The part of the entrance between [begin] and [end], eased.
  Animation<double> _part(double begin, double end, {Curve curve = BazaarMotion.bazaar}) => CurvedAnimation(
    parent: _motion,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    // The scene runs under the status bar, light at the top, so the status bar draws dark icons on it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  // At least as tall as the screen, so the maker's mark sits at its foot on a tall phone.
                  builder: (context, viewport) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: viewport.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ExcludeSemantics(
                              child: _Scene(
                                motion: _motion,
                                ambience: _ambience,
                                part: _part,
                                top: MediaQuery.paddingOf(context).top,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: _Rise(
                                animation: _part(0.66, 0.92),
                                child: Column(
                                  spacing: 12,
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        s.welcome_headline,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          color: colors.onSurfaceTitle,
                                          fontWeight: FontWeight.w700,
                                          height: 1.15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      s.welcome_lede,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                              child: _Rise(
                                animation: _part(0.76, 1),
                                child: FilledButton.icon(
                                  key: const Key('welcome-enter'),
                                  onPressed: widget.onEnter,
                                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                                  icon: const Icon(Icons.arrow_forward),
                                  iconAlignment: IconAlignment.end,
                                  label: Text(s.welcome_enter),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20, top: 8),
                              child: _Rise(
                                animation: _part(0.82, 1),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 8,
                                  children: [
                                    const ExcludeSemantics(
                                      child: Image(
                                        image: AssetImage('assets/brand/lokum_logo.webp'),
                                        width: 22,
                                        height: 22,
                                      ),
                                    ),
                                    Text(
                                      s.welcome_maker,
                                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// The picture over the words: the gate in a 400 high frame grown by [top], the status bar's height, so it reaches the
/// top of the screen; the light in its arch; the two lamps; and the people standing in a row across its foot and just
/// below it, as the mockup places them on a 390 wide phone.
class _Scene extends StatelessWidget {
  const _Scene({required this.motion, required this.ambience, required this.part, required this.top});

  final Animation<double> motion;

  /// The scene's life after the entrance, from 0 to 1; still at both ends.
  final Animation<double> ambience;
  final Animation<double> Function(double begin, double end, {Curve curve}) part;
  final double top;

  static const double _frame = 400;
  static const double _below = 66;
  static const double _gateWidth = 680;

  /// Each person's height, from the left, and the order they step in, one after the other from the left.
  static const _heights = [108.0, 124.0, 118.0, 104.0, 112.0];

  @override
  Widget build(BuildContext context) {
    final gate = part(0, 0.62);
    final glow = part(0.35, 0.8);
    final frame = _frame + top;
    // The gate grows with the frame, so it fills it on a phone with a tall status bar as on one with none.
    final scale = frame / _frame;
    final gateWidth = _gateWidth * scale;
    final glowTop = 214 * scale;
    return SizedBox(
      height: frame + _below,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: frame,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: gate,
                builder: (context, child) => Opacity(
                  opacity: gate.value,
                  child: Transform.scale(
                    scale: 1.14 - 0.14 * gate.value,
                    alignment: const Alignment(0, 0.4),
                    child: child,
                  ),
                ),
                // The gate keeps its width on any screen: a phone shows its centre, a wider screen more of it.
                child: OverflowBox(
                  minWidth: gateWidth,
                  maxWidth: gateWidth,
                  alignment: Alignment.topCenter,
                  child: Image(image: const AssetImage(WelcomeArt.gate), width: gateWidth, fit: BoxFit.fitWidth),
                ),
              ),
            ),
          ),
          // The light in the arch, breathing while the scene is alive.
          Positioned(
            top: glowTop,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([glow, ambience]),
                builder: (context, child) {
                  final breath = _wave(ambience.value, 0);
                  return Opacity(
                    opacity: (glow.value * (1 - 0.25 * breath.abs())).clamp(0, 1),
                    child: Transform.scale(scale: 1 + 0.12 * breath, child: child),
                  );
                },
                child: const SizedBox.square(
                  dimension: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xF2FFF6DC), Color(0x73FFECBE), Color(0x00FFECBE)],
                        stops: [0, 0.4, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Motes of light rising through the gate.
          Positioned(
            top: glowTop - 120,
            left: 0,
            right: 0,
            height: 300,
            child: IgnorePointer(child: CustomPaint(painter: _MotesPainter(ambience))),
          ),
          // A light veil under the status bar, so its icons read on the pattern.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 12,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xD9FDFBF7), Color(0x00FDFBF7)],
                ),
              ),
            ),
          ),
          Positioned(
            top: top - 4,
            left: 18,
            child: _Lamp(
              art: WelcomeArt.lampLeft,
              height: 128,
              drop: part(0.18, 0.55),
              swing: part(0.5, 1),
              ambience: ambience,
            ),
          ),
          Positioned(
            top: top - 4,
            right: 18,
            child: _Lamp(
              art: WelcomeArt.lampRight,
              height: 96,
              drop: part(0.25, 0.6),
              swing: part(0.55, 1),
              ambience: ambience,
              phase: -1,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                for (final (position, art) in WelcomeArt.cast.indexed)
                  _Rise(
                    animation: part(0.3 + 0.08 * position, 0.52 + 0.08 * position, curve: Curves.easeOutBack),
                    distance: 60,
                    child: Image(
                      image: AssetImage(art),
                      height: _heights[position],
                      width: _heights[position] * 330 / 600,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The scene's slow wave at [t] of its life, offset by [shift] of a beat: three beats that swell in and fade out, so
/// it is still at 0 and at 1.
double _wave(double t, double shift) => math.sin(math.pi * t) * math.sin(2 * math.pi * (3 * t + shift));

/// A few motes of warm light that rise through the arch and fade, while [life] runs; none at its ends.
class _MotesPainter extends CustomPainter {
  _MotesPainter(this.life) : super(repaint: life);

  final Animation<double> life;

  /// Each mote's place across the arch, from -1 to 1, its start in its cycle, and its size.
  static const _motes = [
    (-0.30, 0.00, 2.6),
    (0.18, 0.21, 2.0),
    (-0.08, 0.43, 3.0),
    (0.34, 0.60, 2.2),
    (-0.42, 0.74, 1.8),
    (0.05, 0.88, 2.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = life.value;
    final envelope = math.sin(math.pi * t);
    if (envelope <= 0) return;
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final (x, start, radius) in _motes) {
      final cycle = (t * 4 + start) % 1;
      final fade = math.sin(math.pi * cycle);
      final dx = size.width / 2 + x * 110 + 6 * math.sin(2 * math.pi * (cycle + start));
      final dy = size.height * (1 - cycle);
      paint.color = Color.fromRGBO(255, 236, 190, 0.85 * fade * envelope);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_MotesPainter oldDelegate) => oldDelegate.life != life;
}

/// A lamp that drops in from above on [drop], swings from its cord on [swing], less each time, then sways a little
/// while [ambience] runs.
class _Lamp extends StatelessWidget {
  const _Lamp({
    required this.art,
    required this.height,
    required this.drop,
    required this.swing,
    required this.ambience,
    this.phase = 1,
  });

  final String art;
  final double height;
  final Animation<double> drop;
  final Animation<double> swing;
  final Animation<double> ambience;

  /// 1 swings right first, -1 left first.
  final double phase;

  /// The widest swing, in radians (about 6 degrees, as the mockup's).
  static const double _amplitude = 0.105;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([drop, swing, ambience]),
      builder: (context, child) {
        final t = swing.value;
        // Two and a half swings that die down, then a slow sway, a third as wide, while the scene is alive.
        final angle =
            phase * _amplitude * (1 - t) * math.sin(t * math.pi * 5) +
            phase * _amplitude / 3 * _wave(ambience.value, 0.25);
        return Transform.translate(
          offset: Offset(0, -150 * (1 - drop.value)),
          child: Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child),
        );
      },
      child: Image(image: AssetImage(art), height: height, filterQuality: FilterQuality.medium),
    );
  }
}

/// [child] fading in as it rises [distance] pixels into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child, this.distance = 16});

  final Animation<double> animation;
  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        // A curve that overshoots moves past its place and back; the opacity stops at full.
        opacity: animation.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, distance * (1 - animation.value)), child: child),
      ),
      child: child,
    );
  }
}
