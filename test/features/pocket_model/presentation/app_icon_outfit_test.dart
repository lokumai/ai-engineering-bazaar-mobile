import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/app_icon_outfit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app icons' robots (lib/shared/app_icon/) in step with the wardrobe (plan 9.10).
void main() {
  test('each icon shows one wardrobe part on the fez robot, and unlocks at that part\'s level', () {
    final shown = <Enum>{};
    for (final robot in AppIconRobot.values) {
      final outfit = appIconOutfit(robot);
      expect(outfit.body, RobotBody.classic, reason: robot.name);
      final part = robot.head ? outfit.head : outfit.hat;
      if (robot.head) {
        expect(outfit.hat, RobotHat.fez, reason: robot.name);
        expect((part as RobotHead).level, robot.level, reason: robot.name);
      } else {
        expect(outfit.head, RobotHead.classic, reason: robot.name);
        expect((part as RobotHat).level, robot.level, reason: robot.name);
      }
      expect(shown.add(part), isTrue, reason: '${robot.name} shows a part no other icon shows');
    }
    // Every hat, and every head but the classic one the hats stand on.
    expect(shown, {...RobotHat.values, ...RobotHead.values.where((head) => head != RobotHead.classic)});
  });

  test('the icons stand in the order they unlock', () {
    final levels = [for (final robot in AppIconRobot.values) robot.level];
    expect(levels, [...levels]..sort());
  });
}
