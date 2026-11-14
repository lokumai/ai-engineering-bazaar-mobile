import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The opening while the app starts (plan 1Y, 9.10), on every launch, over the whole screen in front of [child]: the
/// pocket model's robot, in what the reader dressed it in, pops up and greets them with a short turn picked at random,
/// a wave, a few hearts, a spin, a hum (the owner, 2026-11-14: in place of the striped agent). It stands on the ground
/// of the look the reader reads in, light or dark, all of it (the owner, 2026-11-14): the launch screen's colour turns
/// to it as the opening starts. Until the reader's choices on this device are read ([AppIconCubit]), only the launch
/// screen's colour shows. Once the robot has greeted ([robot] calls its `onDone`) and the content and the record have
/// settled, the opening gives way to the app in [leave]: the robot shrinks away with a little bounce and the app
/// opens out of where it stood, in a growing circle. The whole is about a second.
///
/// The welcome feature may not read the pocket model: the app passes the [robot] (`lib/app/app.dart`). Under reduced
/// motion the robot stands still and the opening gives way as soon as the app is ready (spec 3.10). It is decoration,
/// hidden from assistive technology.
class WelcomeSting extends StatefulWidget {
  const WelcomeSting({super.key, required this.child, required this.robot});

  final Widget child;

  /// The robot that greets, given what to call when it is done.
  final Widget Function(VoidCallback onDone) robot;

  /// How long the opening takes to give way to the app.
  static const leave = Duration(milliseconds: 420);

  /// How long the launch screen's colour takes to turn to the reader's ground.
  static const tint = Duration(milliseconds: 180);

  /// The longest the opening waits for the robot's greeting, should it never say it is done.
  static const longest = Duration(milliseconds: 1600);

  /// The key of the opening while it stands over the app.
  static const sceneKey = Key('welcome-sting');

  /// The key of the opening's ground.
  static const groundKey = Key('welcome-sting-ground');

  @override
  State<WelcomeSting> createState() => _WelcomeStingState();
}

class _WelcomeStingState extends State<WelcomeSting> with SingleTickerProviderStateMixin {
  late final AnimationController _leave = AnimationController(vsync: this, duration: WelcomeSting.leave)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() => _gone = true);
    });
  Timer? _waited;
  bool _greeted = false;
  bool _gone = false;

  void _done() {
    _waited?.cancel();
    if (mounted && !_greeted) setState(() => _greeted = true);
  }

  @override
  void dispose() {
    _waited?.cancel();
    _leave.dispose();
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
    // Whether the reader's choices on this device are read; until then only the launch screen's colour shows.
    final read = switch (context.watch<AppIconCubit>().state) {
      AppIconKnown() => true,
      AppIconUnread() => false,
    };
    final launch = switch (context.watch<AppIconCubit>().state) {
      AppIconKnown(:final icon) => icon.ground,
      AppIconUnread() => BazaarIcon.defaultIcon.ground,
    };
    final still = MediaQuery.disableAnimationsOf(context);
    if (read) _waited ??= Timer(WelcomeSting.longest, _done);
    final leaving = ready && read && (_greeted || still);
    if (leaving && !still && _leave.status == AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _leave.status == AnimationStatus.dismissed) unawaited(_leave.forward());
      });
    }
    // The ground the reader reads on.
    final ground = read ? Theme.of(context).scaffoldBackgroundColor : launch;
    final dark = ThemeData.estimateBrightnessForColor(ground) == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(enabled: leaving || _gone, child: widget.child),
        if (!_gone && !(leaving && still))
          IgnorePointer(
            key: WelcomeSting.sceneKey,
            // Until it leaves, a tap stays on the opening (the robot may be petted), and does not reach the app.
            ignoring: leaving,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              // The status bar lies over the ground.
              value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: Colors.transparent,
              ),
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _leave,
                  builder: (context, child) {
                    final t = _leave.value;
                    // The app opens out of the middle, slowly first, after the robot has begun to go.
                    final open = Curves.easeInCubic.transform(((t - 0.2) / 0.8).clamp(0.0, 1.0));
                    return ClipPath(
                      clipper: t == 0 ? null : _Iris(open),
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(begin: launch, end: ground),
                        duration: still ? Duration.zero : WelcomeSting.tint,
                        builder: (context, colour, robot) =>
                            ColoredBox(key: WelcomeSting.groundKey, color: colour ?? ground, child: robot),
                        child: read ? child : const SizedBox.expand(),
                      ),
                    );
                  },
                  child: Center(
                    child: _Robot(leave: _leave, still: still, child: widget.robot(_done)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The robot as it comes and goes: it pops up as it appears and, as the opening leaves, swells a touch and shrinks
/// away.
class _Robot extends StatelessWidget {
  const _Robot({required this.leave, required this.still, required this.child});

  final Animation<double> leave;
  final bool still;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: still ? 1 : 0.7, end: 1),
    duration: still ? Duration.zero : const Duration(milliseconds: 260),
    curve: Curves.easeOutBack,
    builder: (context, come, robot) => AnimatedBuilder(
      animation: leave,
      builder: (context, robot) {
        final go = Curves.easeInBack.transform((leave.value / 0.45).clamp(0.0, 1.0));
        return Transform.scale(scale: math.max(0, come * (1 - go)), child: robot);
      },
      child: robot,
    ),
    child: SizedBox(width: 300, height: 280, child: child),
  );
}

/// Everything but a circle in the middle, [open] of the way to the corners: the app shows through the circle.
class _Iris extends CustomClipper<Path> {
  const _Iris(this.open);

  final double open;

  @override
  Path getClip(Size size) {
    final whole = Offset.zero & size;
    final radius = open * (size.longestSide / 2 + size.shortestSide / 2);
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(whole),
      Path()..addOval(Rect.fromCircle(center: whole.center, radius: radius)),
    );
  }

  @override
  bool shouldReclip(_Iris old) => old.open != open;
}
