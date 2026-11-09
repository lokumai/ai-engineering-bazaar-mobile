import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_art.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The bazaar's gate while the app opens (plan 1Y, 1Z), on every launch, in front of [child]: an animation only, with no
/// words and no button. The gate opens in the middle of the screen, the two lamps drop and swing, the people step in
/// one after the other and the light in the arch comes up. Once that has played and the content and the record have
/// settled, the reader walks in: the gate grows towards the light in its arch and fades into [child].
///
/// Under reduced motion it is drawn in place and gives way as soon as the app is ready (spec 3.10). It is decoration,
/// hidden from assistive technology.
class WelcomeSplash extends StatefulWidget {
  const WelcomeSplash({super.key, required this.child});

  final Widget child;

  /// How long the entrance takes when motion is allowed.
  static const entrance = Duration(milliseconds: 1800);

  /// The key of the scene while it stands over the app.
  static const sceneKey = Key('welcome-splash');

  /// How long the walk through the gate takes.
  static const fade = Duration(milliseconds: 700);

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
    _walk = AnimationController(vsync: this, duration: WelcomeSplash.fade)
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
    final still = MediaQuery.disableAnimationsOf(context);
    if (leaving && !still && _walk.status == AnimationStatus.dismissed) {
      // Started after this frame, so the walk begins from the scene as drawn.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _walk.status == AnimationStatus.dismissed) unawaited(_walk.forward());
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // The app builds behind the scene, so it is in place when the scene fades.
        widget.child,
        // Under reduced motion there is no walk to wait for: the scene is gone once the app is ready.
        if (!_gone && !(leaving && still))
          IgnorePointer(
            ignoring: leaving,
            child: _SplashPage(key: WelcomeSplash.sceneKey, part: _part, walk: _walk),
          ),
      ],
    );
  }
}

/// The scene in the middle of the screen, on the page ground, and the walk through the gate on [walk].
class _SplashPage extends StatelessWidget {
  const _SplashPage({super.key, required this.part, required this.walk});

  final Animation<double> Function(double begin, double end, {Curve curve}) part;
  final Animation<double> walk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final into = CurvedAnimation(parent: walk, curve: Curves.easeInCubic);
    final away = CurvedAnimation(
      parent: walk,
      curve: const Interval(0.45, 1, curve: Curves.easeIn),
    );
    // The status bar lies over the light page ground, so its icons are dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: ReverseAnimation(away),
          child: Material(
            color: theme.colorScheme.surface,
            child: Center(
              child: AnimatedBuilder(
                animation: into,
                // The walk heads for the light in the arch.
                builder: (context, child) =>
                    Transform.scale(scale: 1 + 2.4 * into.value, alignment: _Scene.archLight, child: child),
                child: _Scene(part: part),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The scene: the gate in a 400 high frame, the light in its arch, the two lamps, and the people standing in a row
/// across its foot and just below it, as the mockup places them on a 390 wide phone.
class _Scene extends StatelessWidget {
  const _Scene({required this.part});

  final Animation<double> Function(double begin, double end, {Curve curve}) part;

  static const double _frame = 400;
  static const double _below = 66;

  /// Where the light in the arch stands in the scene, the point the walk heads for.
  static const archLight = Alignment(0, (214 + 60) / (_frame + _below) * 2 - 1);
  static const double _gateWidth = 680;

  /// Each person's height, from the left, and the order they step in, one after the other from the left.
  static const _heights = [108.0, 124.0, 118.0, 104.0, 112.0];

  @override
  Widget build(BuildContext context) {
    final gate = part(0, 0.62);
    final glow = part(0.35, 0.8);
    const frame = _frame;
    const gateWidth = _gateWidth;
    const glowTop = 214.0;
    return SizedBox(
      height: frame + _below,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: frame,
            // The gate's top and foot melt into the page ground, so it stands in the screen, not as a picture on it.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                stops: [0, 0.16, 0.86, 1],
              ).createShader(bounds),
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
