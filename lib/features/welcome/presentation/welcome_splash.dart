import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_art.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The bazaar's gate while the app opens (plan 1Y), on every launch, in front of [child]: the gate cropped to its
/// centre with a light in its arch, reaching the top of the screen, the two lamps, the people of the web's home page,
/// the line that says what the course is, and the maker's mark. There is no button: once the entrance has played and
/// the content and the record have settled, the scene fades into [child].
///
/// Under reduced motion it is drawn in place and gives way as soon as the app is ready (spec 3.10). The pictures are
/// decoration, hidden from assistive technology; the line is read.
class WelcomeSplash extends StatefulWidget {
  const WelcomeSplash({super.key, required this.child});

  final Widget child;

  /// How long the entrance takes when motion is allowed.
  static const entrance = Duration(milliseconds: 1800);

  /// The key of the scene while it stands over the app.
  static const sceneKey = Key('welcome-splash');

  /// How long the scene takes to fade into the app.
  static const fade = Duration(milliseconds: 300);

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  bool _played = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: WelcomeSplash.entrance)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _played = true);
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
    super.dispose();
  }

  /// The part of the entrance between [begin] and [end], eased.
  Animation<double> _part(double begin, double end, {Curve curve = BazaarMotion.bazaar}) => CurvedAnimation(
    parent: _motion,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    // The app is ready once the content and the record have settled, or the content cannot be opened at all.
    final ready = switch ((context.watch<ContentBloc>().state, context.watch<RecordBloc>().state)) {
      (ContentBroken(), _) => true,
      (ContentReady(), RecordReady()) => true,
      _ => false,
    };
    final leaving = _played && ready;
    final fade = MediaQuery.disableAnimationsOf(context) ? Duration.zero : WelcomeSplash.fade;
    return Stack(
      fit: StackFit.expand,
      children: [
        // The app builds behind the scene, so it is in place when the scene fades.
        widget.child,
        // Under reduced motion there is no fade to wait for: the scene is gone once the app is ready.
        if (!_gone && !(leaving && fade == Duration.zero))
          IgnorePointer(
            ignoring: leaving,
            // It leaves as if walking in: the gate grows towards the reader as it fades.
            child: AnimatedScale(
              scale: leaving ? 1.12 : 1,
              alignment: const Alignment(0, -0.3),
              curve: Curves.easeIn,
              duration: fade,
              child: AnimatedOpacity(
                opacity: leaving ? 0 : 1,
                curve: Curves.easeIn,
                duration: fade,
                onEnd: () {
                  if (leaving) setState(() => _gone = true);
                },
                child: _SplashPage(key: WelcomeSplash.sceneKey, part: _part),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage({super.key, required this.part});

  final Animation<double> Function(double begin, double end, {Curve curve}) part;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    // The scene runs under the status bar, light at the top, so the status bar draws dark icons on it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Material(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: _Scene(part: part, top: MediaQuery.paddingOf(context).top),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _Rise(
                animation: part(0.6, 0.95),
                child: Semantics(
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
              ),
            ),
            const Spacer(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _Rise(
                  animation: part(0.7, 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      const ExcludeSemantics(
                        child: Image(image: AssetImage('assets/brand/lokum_logo.webp'), width: 22, height: 22),
                      ),
                      Text(s.welcome_maker, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The picture over the words: the gate in a 400 high frame grown by [top], the status bar's height, so it reaches the
/// top of the screen; the light in its arch; the two lamps; and the people standing in a row across its foot and just
/// below it, as the mockup places them on a 390 wide phone.
class _Scene extends StatelessWidget {
  const _Scene({required this.part, required this.top});

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
          // The light in the arch.
          Positioned(
            top: glowTop,
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
            child: _Lamp(art: WelcomeArt.lampLeft, height: 128, drop: part(0.18, 0.55), swing: part(0.5, 1)),
          ),
          Positioned(
            top: top - 4,
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
        // A curve that overshoots moves past its place and back; the opacity stops at full.
        opacity: animation.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, distance * (1 - animation.value)), child: child),
      ),
      child: child,
    );
  }
}
