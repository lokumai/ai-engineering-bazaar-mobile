import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';

/// The name of a hat, a head or a body in the wardrobe.
String outfitName(S s, Enum part) => switch (part) {
  RobotHat.fez => s.outfit_hat_fez,
  RobotHat.antenna => s.outfit_hat_antenna,
  RobotHat.beanie => s.outfit_hat_beanie,
  RobotHat.mortarboard => s.outfit_hat_mortarboard,
  RobotHat.turban => s.outfit_hat_turban,
  RobotHat.wizard => s.outfit_hat_wizard,
  RobotHat.topHat => s.outfit_hat_top_hat,
  RobotHat.crown => s.outfit_hat_crown,
  RobotHead.classic => s.outfit_head_classic,
  RobotHead.dome => s.outfit_head_dome,
  RobotHead.tv => s.outfit_head_tv,
  RobotHead.ears => s.outfit_head_ears,
  RobotHead.visor => s.outfit_head_visor,
  RobotBody.classic => s.outfit_body_classic,
  RobotBody.vest => s.outfit_body_vest,
  RobotBody.hoodie => s.outfit_body_hoodie,
  RobotBody.labCoat => s.outfit_body_lab_coat,
  RobotBody.kaftan => s.outfit_body_kaftan,
  RobotBody.suit => s.outfit_body_suit,
  RobotBody.astronaut => s.outfit_body_astronaut,
  _ => '',
};

/// The level [part] unlocks at.
int unlockLevel(Enum part) => switch (part) {
  RobotHat(:final level) || RobotHead(:final level) || RobotBody(:final level) => level,
  _ => 0,
};
