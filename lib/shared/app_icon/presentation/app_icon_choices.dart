import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_name.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:ai_engineering_bazaar/shared/robot_level/robot_level_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The key of [robot]'s choice among [AppIconChoices].
Key appIconChoiceKey(AppIconRobot robot) => ValueKey('app-icon-${robot.name}');

/// The key of [ground]'s segment above [AppIconChoices].
Key appIconGroundKey(AppIconGround ground) => ValueKey('app-icon-ground-${ground.name}');

/// The app icon choice (plan 9.10): above, the ground, dark or cream; under it the robots as pictures on that ground,
/// three to a row, the one in use ringed. Choosing a ground puts the icon in use on it; a tap on a robot makes it the
/// app's icon on the ground chosen. A robot the pocket model has not unlocked in its wardrobe yet is locked, with its
/// level ([RobotLevelCubit]). Settings' app icon page and Welcome's first step both show it, Welcome only the unlocked
/// robots ([unlockedOnly]). The pictures carry no names under them (the owner, 2026-11-14); a screen reader still hears
/// each name.
class AppIconChoices extends StatelessWidget {
  const AppIconChoices({super.key, this.unlockedOnly = false});

  /// Whether the locked robots are left out.
  final bool unlockedOnly;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final current = context.watch<AppIconCubit>().state.icon;
    final level = context.watch<RobotLevelCubit>().state;
    final ground = current.backdrop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        BazaarSegmentedControl<AppIconGround>(
          semanticLabel: s.app_icon_ground,
          selected: ground,
          onSelected: (chosen) => context.read<AppIconCubit>().choose(BazaarIcon.of(current.robot, chosen)),
          segments: [
            BazaarSegment(
              value: AppIconGround.cream,
              label: s.app_icon_cream,
              key: appIconGroundKey(AppIconGround.cream),
            ),
            BazaarSegment(value: AppIconGround.dark, label: s.app_icon_dark, key: appIconGroundKey(AppIconGround.dark)),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final robot in AppIconRobot.values)
                  if (!unlockedOnly || robot.level <= level)
                    SizedBox(
                      width: width,
                      child: _Choice(
                        key: appIconChoiceKey(robot),
                        icon: BazaarIcon.of(robot, ground),
                        selected: robot == current.robot,
                        // The icon in use stays chosen after the model starts over, though its robot is locked again.
                        locked: robot.level > level,
                        onTap: () => context.read<AppIconCubit>().choose(BazaarIcon.of(robot, ground)),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One icon: its picture, ringed when it is the one in use; locked, faint under a lock and its level.
class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.icon, required this.selected, required this.locked, required this.onTap});

  final BazaarIcon icon;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final name = appIconName(s, icon);
    final onTap = locked ? null : this.onTap;
    return Semantics(
      container: true,
      button: !locked,
      selected: selected,
      label: locked
          ? s.wardrobe_item_locked(name, icon.level)
          : (icon == BazaarIcon.defaultIcon ? '$name, ${s.app_icon_default}' : name),
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            border: Border.all(color: selected ? colors.primary : Colors.transparent, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: locked ? 0.3 : 1,
                      child: Image.asset(icon.asset, fit: BoxFit.cover),
                    ),
                    if (locked)
                      // At a large text size the lock and its level shrink to the picture.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: colors.onSurfaceTitle, size: 24),
                              Text(
                                s.pocket_level(icon.level),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: colors.onSurfaceTitle, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
