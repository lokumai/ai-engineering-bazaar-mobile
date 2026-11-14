import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';

/// What the robot of an app icon wears (plan 9.10): one of its hats on its own screen, or another of its heads in a
/// hat that suits it (the owner, 2026-11-14: not the fez again on every head). `tool/render_app_icons.dart` draws the icons in it.
RobotOutfit appIconOutfit(AppIconRobot robot) => switch (robot) {
  AppIconRobot.fez => const RobotOutfit(),
  AppIconRobot.antenna => const RobotOutfit(hat: RobotHat.antenna),
  AppIconRobot.beanie => const RobotOutfit(hat: RobotHat.beanie),
  AppIconRobot.dome => const RobotOutfit(head: RobotHead.dome, hat: RobotHat.beanie),
  AppIconRobot.mortarboard => const RobotOutfit(hat: RobotHat.mortarboard),
  AppIconRobot.tv => const RobotOutfit(head: RobotHead.tv, hat: RobotHat.antenna),
  AppIconRobot.turban => const RobotOutfit(hat: RobotHat.turban),
  AppIconRobot.ears => const RobotOutfit(head: RobotHead.ears, hat: RobotHat.mortarboard),
  AppIconRobot.wizard => const RobotOutfit(hat: RobotHat.wizard),
  AppIconRobot.topHat => const RobotOutfit(hat: RobotHat.topHat),
  AppIconRobot.visor => const RobotOutfit(head: RobotHead.visor, hat: RobotHat.antenna),
  AppIconRobot.crown => const RobotOutfit(hat: RobotHat.crown),
};
