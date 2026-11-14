import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_model_card.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The pocket model's button (plan 9.4): a round button with the robot's head in it, in the corner of the tabs the
/// shell shows it on, as the round assistants of other apps sit; a tap opens the pocket model in a sheet. Its face is
/// the model's mood: asleep, hungry, overfit or calm. It draws once and moves only when the model changes.
///
/// It tells the model the app's language, so the model reads and speaks it before the sheet is ever opened.
class PocketAssistantButton extends StatefulWidget {
  const PocketAssistantButton({super.key});

  /// The button's width and height.
  static const double size = 58;

  @override
  State<PocketAssistantButton> createState() => _PocketAssistantButtonState();
}

class _PocketAssistantButtonState extends State<PocketAssistantButton> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<PocketModelBloc>().add(PocketModelLanguageSet(Localizations.localeOf(context).languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocBuilder<PocketModelBloc, PocketModelState>(
      builder: (context, state) {
        final level = _levelOf(state);
        // The modules the reader finished that it has not read: a badge, and words for a screen reader.
        final waiting = switch (state) {
          PocketModelReady(:final model) => finishedFor(context, model).length,
          PocketModelLoading() => 0,
        };
        final label = [
          s.pocket_title,
          s.pocket_level(level),
          if (waiting > 0) s.pocket_read_waiting(waiting),
        ].join(', ');
        return Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          onTap: () => showPocketModelSheet(context),
          child: Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  key: const ValueKey('pocket-assistant'),
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: const Color(0x66000000),
                  color: RobotColors.body,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showPocketModelSheet(context),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [RobotColors.bodyLight, RobotColors.body],
                        ),
                      ),
                      child: SizedBox.square(
                        dimension: PocketAssistantButton.size,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
                          child: CustomPaint(
                            painter: RobotHeadPainter(
                              face: _faceOf(state),
                              outfit: context.watch<RobotOutfitCubit>().state.within(level),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (waiting > 0)
                  PositionedDirectional(
                    top: -2,
                    end: -2,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const ValueKey('pocket-assistant-badge'),
                        decoration: BoxDecoration(
                          color: const Color(0xffddb46a),
                          shape: BoxShape.circle,
                          border: Border.all(color: context.bazaarColors.surface, width: 2),
                        ),
                        child: SizedBox.square(
                          dimension: 22,
                          child: Center(
                            child: Text(
                              '$waiting',
                              style: const TextStyle(
                                color: RobotColors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static int _levelOf(PocketModelState state) => switch (state) {
    PocketModelReady(:final model) => model.level,
    PocketModelLoading() => 0,
  };

  static RobotFace _faceOf(PocketModelState state) {
    final now = clock.now();
    return switch (state) {
      PocketModelLoading() => RobotFace.calm,
      PocketModelReady(awake: false) => RobotFace.asleep,
      PocketModelReady(:final model) when model.overfitAt(now) => RobotFace.overfit,
      PocketModelReady(:final model) => switch (model.moodAt(now)) {
        PocketMood.hungry => RobotFace.hungry,
        PocketMood.asleep => RobotFace.asleep,
        PocketMood.newborn || PocketMood.content => RobotFace.calm,
      },
    };
  }
}

/// Opens the pocket model in a sheet over the whole app, its stage, its training and its buttons. Closed, it forgets
/// what it last said, so the sheet opens again without the old bubble.
Future<void> showPocketModelSheet(BuildContext context) async {
  final bloc = context.read<PocketModelBloc>();
  final outfit = context.read<RobotOutfitCubit>();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.bazaarColors.surface,
    builder: (context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: outfit),
      ],
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, controller) => SingleChildScrollView(
          key: const ValueKey('pocket-sheet'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: const PocketModelCard(),
        ),
      ),
    ),
  );
  if (!bloc.isClosed) bloc.add(const PocketModelHushed());
}
