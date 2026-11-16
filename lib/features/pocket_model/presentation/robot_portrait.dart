import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The robot's head and hat as an app icon draws it (plan 9.10): a happy face on a square [ground], the head filling
/// [fill] of the square's side. The app icons are rendered from it (`tool/render_app_icons.dart`), and Settings'
/// Wardrobe row shows it.
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

/// The robot in what it wears now, as a small rounded picture in the app icon's style, on [ground]: Settings' Wardrobe
/// row.
class RobotPortrait extends StatelessWidget {
  const RobotPortrait({super.key, required this.size, required this.ground});

  final double size;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    final level = switch (context.watch<PocketModelBloc>().state) {
      PocketModelReady(:final model) => model.level,
      PocketModelLoading() => 0,
    };
    final outfit = context.watch<RobotOutfitCubit>().state.within(level);
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(size * 0.23)),
      child: CustomPaint(
        size: Size.square(size),
        painter: RobotIconPainter(outfit: outfit, ground: ground),
      ),
    );
  }
}
