import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/outfit_names.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/robot_stage.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The parts of the wardrobe, each a tab.
enum _Kind { hat, head, body }

/// The robot's wardrobe (plan 9.9), from Settings' Customize: the robot on its rug at the top, in the middle, in what
/// it wears, and a tap pets it as on the pocket model's sheet ([RobotStage]); under it its hats, heads and bodies, a
/// tab each, as pictures with no names under them (the owner, 2026-11-14: the picture says it). A part the pocket
/// model has not reached the level of is shown locked, with its level; a tap on any other puts it on.
class RobotWardrobePage extends StatefulWidget {
  const RobotWardrobePage({super.key});

  @override
  State<RobotWardrobePage> createState() => _RobotWardrobePageState();
}

class _RobotWardrobePageState extends State<RobotWardrobePage> {
  _Kind _kind = _Kind.hat;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final model = context.watch<PocketModelBloc>().state;
    final (level, temperature) = switch (model) {
      PocketModelReady(:final model, :final temperature) => (model.level, temperature),
      PocketModelLoading() => (0, 0.8),
    };
    final chosen = context.watch<RobotOutfitCubit>().state;
    final worn = chosen.within(level);
    final parts = switch (_kind) {
      _Kind.hat => RobotHat.values,
      _Kind.head => RobotHead.values,
      _Kind.body => RobotBody.values,
    };
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionRule(title: s.settings_robot),
            const SizedBox(height: AppSpacing.lg),
            BazaarCard(
              padding: EdgeInsets.zero,
              child: Semantics(
                image: true,
                label: s.wardrobe_preview(outfitName(s, worn.hat), outfitName(s, worn.head), outfitName(s, worn.body)),
                child: SizedBox(
                  key: const ValueKey('wardrobe-robot'),
                  height: 250,
                  child: RobotStage(outfit: worn),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BazaarSegmentedControl<_Kind>(
              semanticLabel: s.settings_robot,
              selected: _kind,
              onSelected: (kind) => setState(() => _kind = kind),
              segments: [
                BazaarSegment(value: _Kind.hat, label: s.wardrobe_hat, key: const ValueKey('wardrobe-hats')),
                BazaarSegment(value: _Kind.head, label: s.wardrobe_head, key: const ValueKey('wardrobe-heads')),
                BazaarSegment(value: _Kind.body, label: s.wardrobe_body, key: const ValueKey('wardrobe-bodies')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final part in parts)
                      SizedBox(
                        width: width,
                        child: _Choice(
                          key: ValueKey('wardrobe-${part.name}-${_kind.name}'),
                          part: part,
                          worn: worn,
                          level: level,
                          temperature: temperature,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(s.wardrobe_note, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

/// One hat, head or body: a picture of the robot in it, a ring when it is worn, a lock and its level when the model
/// has not reached it. Its name is for a screen reader only.
class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.part, required this.worn, required this.level, required this.temperature});

  final Enum part;
  final RobotOutfit worn;
  final int level;
  final double temperature;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final part = this.part;
    final needs = unlockLevel(part);
    final locked = needs > level;
    final trying = switch (part) {
      final RobotHat hat => worn.copyWith(hat: hat),
      final RobotHead head => worn.copyWith(head: head),
      final RobotBody body => worn.copyWith(body: body),
      _ => worn,
    };
    final selected = trying == worn;
    final name = outfitName(s, part);
    final picture = part is RobotBody
        ? PocketRobotPainter(
            rug: false,
            centred: true,
            repaint: const AlwaysStoppedAnimation(0),
            frame: () => RobotFrame(
              time: 0,
              face: RobotFace.calm,
              look: Offset.zero,
              blink: 0,
              hop: 0,
              temperature: temperature,
              level: level,
              particles: const [],
              alive: false,
              mirrored: false,
              outfit: RobotOutfit(body: part),
            ),
          )
        : RobotHeadPainter(face: RobotFace.calm, temperature: temperature, outfit: trying) as CustomPainter;
    void wear() => context.read<RobotOutfitCubit>().wear(part);
    return Semantics(
      container: true,
      button: !locked,
      selected: selected,
      label: locked ? s.wardrobe_item_locked(name, needs) : (selected ? s.wardrobe_item_worn(name) : name),
      onTap: locked ? null : wear,
      excludeSemantics: true,
      child: InkWell(
        onTap: locked ? null : wear,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(color: selected ? colors.primary : colors.line, width: selected ? 3 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: locked ? 0.3 : 1,
                        child: part is RobotBody
                            // The whole robot stands in its box, its feet near the box's foot.
                            ? FittedBox(
                                child: SizedBox(width: 150, height: 190, child: CustomPaint(painter: picture)),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: CustomPaint(painter: picture),
                              ),
                      ),
                      if (locked)
                        // At a large text size the lock and its level shrink to the picture.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: colors.onSurfaceMuted, size: 26),
                              Text(
                                s.pocket_level(needs),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceTitle,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
