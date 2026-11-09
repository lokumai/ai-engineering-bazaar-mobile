import 'dart:async';

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
/// animation only, with no words and no button. On the bar's navy, the Lokum logo pops in and the lattice band runs out
/// from under it to both edges. Once that has played and the content and the record have settled, the screen opens
/// down the middle like a pair of doors and the app is there behind it.
///
/// The Android launch screen is the same navy, so the start reads as one piece. Under reduced motion it is drawn in
/// place and gives way as soon as the app is ready (spec 3.10). It is decoration, hidden from assistive technology.
class WelcomeSplash extends StatefulWidget {
  const WelcomeSplash({super.key, required this.child});

  final Widget child;

  /// How long the logo and the band take to come in when motion is allowed.
  static const entrance = Duration(milliseconds: 1000);

  /// The key of the opening while it stands over the app.
  static const sceneKey = Key('welcome-splash');

  /// How long the doors take to open.
  static const exit = Duration(milliseconds: 550);

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash> with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _doors;
  bool _played = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: WelcomeSplash.entrance)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _played = true);
      });
    _doors = AnimationController(vsync: this, duration: WelcomeSplash.exit)
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
    _doors.dispose();
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
    if (leaving && !still && _doors.status == AnimationStatus.dismissed) {
      // Started after this frame, so the doors open from the opening as drawn.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _doors.status == AnimationStatus.dismissed) unawaited(_doors.forward());
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // The app builds behind the opening, so it is in place when the doors open.
        widget.child,
        // Under reduced motion there are no doors to wait for: the opening is gone once the app is ready.
        if (!_gone && !(leaving && still))
          IgnorePointer(
            ignoring: leaving,
            child: _Doors(key: WelcomeSplash.sceneKey, motion: _motion, doors: _doors),
          ),
      ],
    );
  }
}

/// The opening drawn twice, each copy clipped to one half of the screen, the halves sliding apart on [doors].
class _Doors extends StatelessWidget {
  const _Doors({super.key, required this.motion, required this.doors});

  final Animation<double> motion;
  final Animation<double> doors;

  @override
  Widget build(BuildContext context) {
    final open = CurvedAnimation(parent: doors, curve: Curves.easeInCubic);
    final face = _Face(motion: motion);
    // The status bar lies over the navy, so its icons are light.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: open,
          builder: (context, face) => Stack(
            fit: StackFit.expand,
            children: [
              for (final side in [-1.0, 1.0])
                FractionalTranslation(
                  // Half the screen's width takes a half fully off its edge.
                  translation: Offset(side * 0.5 * open.value, 0),
                  child: ClipRect(clipper: _Half(side), child: face),
                ),
            ],
          ),
          child: face,
        ),
      ),
    );
  }
}

/// The left half of the box for -1, the right half for 1.
class _Half extends CustomClipper<Rect> {
  const _Half(this.side);

  final double side;

  @override
  Rect getClip(Size size) => side < 0
      ? Rect.fromLTWH(0, 0, size.width / 2, size.height)
      : Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_Half oldClipper) => oldClipper.side != side;
}

/// The navy ground, the logo in the middle and the band under it, coming in on [motion].
class _Face extends StatelessWidget {
  const _Face({required this.motion});

  final Animation<double> motion;

  static const double _logo = 120;

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: motion,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final show = CurvedAnimation(
      parent: motion,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );
    final band = CurvedAnimation(
      parent: motion,
      curve: const Interval(0.35, 0.95, curve: BazaarMotion.bazaar),
    );
    final bandC = context.bazaarColors.bandC;
    return ColoredBox(
      color: BazaarFixedColors.bar,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: show,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.55, end: 1).animate(pop),
              child: const Image(
                image: AssetImage(WelcomeArt.logo),
                width: _logo,
                height: _logo,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // The band runs out from the middle to both edges of the screen.
          SizedBox(
            height: LatticeBand.height,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: band,
              builder: (context, child) => ClipRect(clipper: _Middle(band.value), child: child),
              child: CustomPaint(
                painter: LatticeBandPainter(bandC: bandC),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
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
