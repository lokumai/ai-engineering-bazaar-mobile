import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The robot's head and hat as an app icon draws it (plan 9.10): a happy face on a square [ground], the head filling
/// [fill] of the square's side. The app icons are rendered from it (`tool/render_app_icons.dart`).
class RobotIconPainter extends CustomPainter {
  RobotIconPainter({required this.outfit, this.ground, this.fill = 0.72});

  final RobotOutfit outfit;

  /// The colour behind the head; null leaves it clear (Android's adaptive icon draws its own).
  final Color? ground;

  /// The share of the side the head's box takes.
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (ground case final ground?) canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final side = size.shortestSide * fill;
    final box = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    canvas
      ..save()
      ..translate(box.left, box.top);
    RobotHeadPainter(face: RobotFace.happy, outfit: outfit, tight: true).paint(canvas, box.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RobotIconPainter old) => old.outfit != outfit || old.ground != ground || old.fill != fill;
}

/// The whole robot, standing in what it wears now with a happy face, small in a rounded square on [ground]: Settings'
/// Wardrobe row (the owner, 2026-11-17: the whole Apprentice, not its head).
class RobotPortrait extends StatelessWidget {
  const RobotPortrait({super.key, required this.size, required this.ground});

  final double size;
  final Color ground;

  /// The stage the robot is drawn on, as the Apprentice's corner draws it, then fitted into the square.
  static const Size _stage = Size(150, 197);

  @override
  Widget build(BuildContext context) {
    final (level, temperature) = switch (context.watch<PocketModelBloc>().state) {
      PocketModelReady(:final model, :final temperature) => (model.level, temperature),
      PocketModelLoading() => (0, 0.8),
    };
    final outfit = context.watch<RobotOutfitCubit>().state.within(level);
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(size * 0.23)),
      child: ColoredBox(
        color: ground,
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: EdgeInsets.all(size * 0.06),
            child: FittedBox(
              child: CustomPaint(
                size: _stage,
                painter: PocketRobotPainter(
                  rug: false,
                  centred: true,
                  repaint: const AlwaysStoppedAnimation(0),
                  frame: () => RobotFrame(
                    time: 0,
                    face: RobotFace.happy,
                    look: Offset.zero,
                    blink: 0,
                    hop: 0,
                    temperature: temperature,
                    level: level,
                    particles: const [],
                    alive: false,
                    mirrored: false,
                    outfit: outfit,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
