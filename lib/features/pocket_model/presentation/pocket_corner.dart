import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_assistant.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Apprentice's corner at Home's head (plan 11.2, the owner, 2026-11-16): the whole robot in what it wears, which
/// opens its sheet,
/// its name and level with how far its feeds have taken it to the next, a Chat button, and under them what it says,
/// with a tail up to it: the day's card, which the app passes as [message]. The floating button stays on Home too, under
/// the thumb, which the corner at the page's head is far from (the owner, 2026-11-16).
class PocketCorner extends StatelessWidget {
  const PocketCorner({super.key, this.message});

  /// What the Apprentice presents; nothing under it while null.
  final Widget? message;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final (level, progress) = switch (context.watch<PocketModelBloc>().state) {
      PocketModelReady(:final model) => (model.level, model.progress),
      PocketModelLoading() => (0, 0.0),
    };
    final message = this.message;
    return Column(
      key: const ValueKey('pocket-corner'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 12,
          children: [
            const _CornerRobot(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    s.pocket_title,
                    style: displayFace(textTheme.titleMedium)?.copyWith(color: colors.onSurfaceTitle),
                  ),
                  Text(s.pocket_level(level), style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted)),
                  const SizedBox(height: 4),
                  ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: colors.primary,
                        backgroundColor: colors.line,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              key: const ValueKey('pocket-corner-chat'),
              onPressed: () {
                context.read<PocketModelBloc>().add(const PocketModelAsked());
                showPocketModelSheet(context);
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(s.pocket_ask, maxLines: 1),
            ),
          ],
        ),
        if (message != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(padding: const EdgeInsets.only(top: 12), child: message),
              // The tail, from the card up to the robot's button.
              PositionedDirectional(
                top: 7,
                start: _CornerRobot.width / 2 - 6,
                child: ExcludeSemantics(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        border: Border(
                          top: BorderSide(color: colors.line),
                          left: BorderSide(color: colors.line),
                        ),
                      ),
                      child: const SizedBox.square(dimension: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The whole robot, standing in what it wears with the model's face, drawn once: a tap opens its sheet (the owner,
/// 2026-11-16).
class _CornerRobot extends StatelessWidget {
  const _CornerRobot();

  static const double width = 64;
  static const double height = 84;

  /// The stage it is drawn on, then fitted into [width] by [height].
  static const Size _stage = Size(150, 197);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<PocketModelBloc>().state;
    final (level, temperature) = switch (state) {
      PocketModelReady(:final model, :final temperature) => (model.level, temperature),
      PocketModelLoading() => (0, 0.8),
    };
    final face = robotFaceOf(state);
    final outfit = context.watch<RobotOutfitCubit>().state.within(level);
    void open() {
      context.read<PocketModelBloc>().add(const PocketModelAsked());
      showPocketModelSheet(context);
    }

    return Semantics(
      button: true,
      label: '${s.pocket_title}, ${s.pocket_level(level)}',
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        key: const ValueKey('pocket-corner-robot'),
        onTap: open,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: SizedBox(
          width: width,
          height: height,
          child: FittedBox(
            child: CustomPaint(
              size: _stage,
              painter: PocketRobotPainter(
                rug: false,
                centred: true,
                repaint: const AlwaysStoppedAnimation(0),
                frame: () => RobotFrame(
                  time: 0,
                  face: face,
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
    );
  }
}
