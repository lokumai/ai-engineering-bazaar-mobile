import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:flutter/material.dart';

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

/// The Welcome screen, laid out as the team's mockup draws it (plan 1K): the lattice band, the gate cropped to its
/// centre with a light in its arch, two lamps hanging at the corners, the people of the web's home page in front of
/// it, the line that says what the course is, its lead line, Enter the bazaar, and the maker's mark.
///
/// The gate opens, the lamps drop and swing to rest, the people step in and the words rise, once; the motion ends,
/// so nothing moves while the reader decides. Under reduced motion everything is drawn in place at once (spec 3.10).
/// The pictures are decoration, hidden from assistive technology.
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key, required this.onEnter});

  final VoidCallback onEnter;

  /// How long the entrance takes when motion is allowed.
  static const entrance = Duration(milliseconds: 2600);

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this, duration: WelcomeView.entrance);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 1;
    } else if (_motion.status == AnimationStatus.dismissed) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LatticeBand(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: _Scene(motion: _motion, part: _part),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 8),
                      child: _Rise(
                        animation: _part(0.82, 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 8,
                          children: [
                            const ExcludeSemantics(
                              child: Image(image: AssetImage('assets/brand/lokum_logo.webp'), width: 22, height: 22),
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
          ],
        ),
      ),
    );
  }
}

/// The picture over the words: the gate in a 400 high frame, the light in its arch, the two lamps, and the people
/// standing in a row across its foot and just below it, as the mockup places them on a 390 wide phone.
class _Scene extends StatelessWidget {
  const _Scene({required this.motion, required this.part});

  final Animation<double> motion;
  final Animation<double> Function(double begin, double end, {Curve curve}) part;

  static const double _frame = 400;
  static const double _height = 466;
  static const double _gateWidth = 680;

  /// Each person's height, from the left, and the order they step in, from the centre out.
  static const _heights = [108.0, 124.0, 118.0, 104.0, 112.0];
  static const _order = [2, 1, 0, 3, 4];

  @override
  Widget build(BuildContext context) {
    final gate = part(0, 0.62);
    final glow = part(0.35, 0.8);
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _frame,
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
                child: const OverflowBox(
                  minWidth: _gateWidth,
                  maxWidth: _gateWidth,
                  alignment: Alignment.topCenter,
                  child: Image(image: AssetImage(WelcomeArt.gate), width: _gateWidth, fit: BoxFit.fitWidth),
                ),
              ),
            ),
          ),
          // The light in the arch.
          Positioned(
            top: 214,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: glow,
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
          Positioned(
            top: -4,
            left: 18,
            child: _Lamp(art: WelcomeArt.lampLeft, height: 128, drop: part(0.18, 0.55), swing: part(0.5, 1)),
          ),
          Positioned(
            top: -4,
            right: 18,
            child: _Lamp(art: WelcomeArt.lampRight, height: 96, drop: part(0.25, 0.6), swing: part(0.55, 1), phase: -1),
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
                    animation: part(0.34 + 0.05 * _order[position], 0.6 + 0.05 * _order[position]),
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

/// A lamp that drops in from above on [drop], then swings from its cord on [swing], less each time, to rest.
class _Lamp extends StatelessWidget {
  const _Lamp({required this.art, required this.height, required this.drop, required this.swing, this.phase = 1});

  final String art;
  final double height;
  final Animation<double> drop;
  final Animation<double> swing;

  /// 1 swings right first, -1 left first.
  final double phase;

  /// The widest swing, in radians (about 6 degrees, as the mockup's).
  static const double _amplitude = 0.105;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([drop, swing]),
      builder: (context, child) {
        final t = swing.value;
        // Two and a half swings that die down to rest.
        final angle = phase * _amplitude * (1 - t) * math.sin(t * math.pi * 5);
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
        opacity: animation.value,
        child: Transform.translate(offset: Offset(0, distance * (1 - animation.value)), child: child),
      ),
      child: child,
    );
  }
}
