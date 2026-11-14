import 'dart:async';

import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The opening while the app starts (plan 1Y, 9.10), on every launch, over the whole screen in front of [child]: the
/// pocket model's robot, in what the reader dressed it in, greets them with a short turn picked at random, a wave, a
/// few hearts, stars for eyes (the owner, 2026-11-14: in place of the striped agent). It stands on the ground of the
/// app icon the reader chose ([AppIconCubit]), the colour the launch screen showed; until the choice is read only that
/// ground shows. Once the robot has greeted ([robot] calls its `onDone`) and the content and the record have settled,
/// the opening fades into the app in [fade].
///
/// The welcome feature may not read the pocket model: the app passes the [robot] (`lib/app/app.dart`). Under reduced
/// motion the robot stands still and the opening gives way as soon as the app is ready (spec 3.10). It is decoration,
/// hidden from assistive technology.
class WelcomeSting extends StatefulWidget {
  const WelcomeSting({super.key, required this.child, required this.robot});

  final Widget child;

  /// The robot that greets, given what to call when it is done.
  final Widget Function(VoidCallback onDone) robot;

  /// How long the opening takes to fade into the app.
  static const fade = Duration(milliseconds: 300);

  /// The longest the opening waits for the robot's greeting, should it never say it is done.
  static const longest = Duration(milliseconds: 2500);

  /// The key of the opening while it stands over the app.
  static const sceneKey = Key('welcome-sting');

  /// The key of the opening's ground.
  static const groundKey = Key('welcome-sting-ground');

  @override
  State<WelcomeSting> createState() => _WelcomeStingState();
}

class _WelcomeStingState extends State<WelcomeSting> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: WelcomeSting.fade)
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
    _fade.dispose();
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
    // The chosen icon; null until the choice is read, when only the launch screen's ground shows.
    final icon = switch (context.watch<AppIconCubit>().state) {
      AppIconKnown(:final icon) => icon,
      AppIconUnread() => null,
    };
    final still = MediaQuery.disableAnimationsOf(context);
    if (icon != null) _waited ??= Timer(WelcomeSting.longest, _done);
    final leaving = ready && icon != null && (_greeted || still);
    if (leaving && !still && _fade.status == AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _fade.status == AnimationStatus.dismissed) unawaited(_fade.forward());
      });
    }
    final ground = (icon ?? BazaarIcon.defaultIcon).ground;
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
              // The status bar lies over the icon's ground.
              value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: Colors.transparent,
              ),
              child: ExcludeSemantics(
                child: FadeTransition(
                  opacity: ReverseAnimation(_fade),
                  child: ColoredBox(
                    key: WelcomeSting.groundKey,
                    color: ground,
                    child: icon == null
                        ? const SizedBox.expand()
                        : Center(child: SizedBox(width: 300, height: 280, child: widget.robot(_done))),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
