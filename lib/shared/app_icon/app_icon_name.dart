import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';

/// [icon]'s name in the interface's language: its robot's wardrobe part and its ground, as Fez, dark.
String appIconName(S s, BazaarIcon icon) => s.app_icon_name(_robot(s, icon.robot), switch (icon.backdrop) {
  AppIconGround.dark => s.app_icon_dark,
  AppIconGround.cream => s.app_icon_cream,
});

/// The name of [robot]'s wardrobe part, as the wardrobe names it.
String _robot(S s, AppIconRobot robot) => switch (robot) {
  AppIconRobot.fez => s.outfit_hat_fez,
  AppIconRobot.antenna => s.outfit_hat_antenna,
  AppIconRobot.beanie => s.outfit_hat_beanie,
  AppIconRobot.dome => s.outfit_head_dome,
  AppIconRobot.mortarboard => s.outfit_hat_mortarboard,
  AppIconRobot.tv => s.outfit_head_tv,
  AppIconRobot.turban => s.outfit_hat_turban,
  AppIconRobot.ears => s.outfit_head_ears,
  AppIconRobot.wizard => s.outfit_hat_wizard,
  AppIconRobot.topHat => s.outfit_hat_top_hat,
  AppIconRobot.visor => s.outfit_head_visor,
  AppIconRobot.crown => s.outfit_hat_crown,
};
