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
}

/// The Welcome screen (the mockup's first screen, plan Phase 1I): the lattice band, the gate with the people of the
/// web's home page in front of it, the app's name and its lead line, Enter the bazaar, and the maker's mark.
///
/// The gate opens, the people step in and the words rise, once; under reduced motion everything is drawn in place at
/// once (spec 3.10). The pictures are decoration, hidden from assistive technology.
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key, required this.onEnter});

  final VoidCallback onEnter;

  /// How long the entrance takes when motion is allowed.
  static const entrance = Duration(milliseconds: 1800);

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
  Animation<double> _part(double begin, double end) => CurvedAnimation(
    parent: _motion,
    curve: Interval(begin, end, curve: BazaarMotion.bazaar),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final words = _part(0.55, 0.85);
    final button = _part(0.7, 1);
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
                      child: _Scene(gate: _part(0, 0.6), cast: _motion),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _Rise(
                        animation: words,
                        child: Column(
                          spacing: 12,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                s.app_title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(color: colors.onSurfaceTitle),
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
                        animation: button,
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

/// The gate, cropped to its centre as the mockup crops it, with the people in a row in front of it.
class _Scene extends StatelessWidget {
  const _Scene({required this.gate, required this.cast});

  final Animation<double> gate;

  /// The whole entrance: each person steps in on a part of it.
  final Animation<double> cast;

  static const double _height = 360;
  static const double _gateWidth = 680;
  static const double _person = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: gate,
                builder: (context, child) => Opacity(
                  opacity: gate.value,
                  child: Transform.scale(scale: 1.14 - 0.14 * gate.value, child: child),
                ),
                // The gate keeps its width on any screen: a phone shows its centre, a wider screen the whole of it.
                child: const OverflowBox(
                  minWidth: _gateWidth,
                  maxWidth: _gateWidth,
                  alignment: Alignment.topCenter,
                  child: Image(image: AssetImage(WelcomeArt.gate), width: _gateWidth, fit: BoxFit.fitWidth),
                ),
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
                      animation: CurvedAnimation(
                        parent: cast,
                        curve: Interval(0.3 + 0.06 * position, 0.6 + 0.06 * position, curve: BazaarMotion.bazaar),
                      ),
                      distance: 60,
                      child: Image(image: AssetImage(art), width: _person, height: _person * 400 / 220),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
