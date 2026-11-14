import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/app_icon_outfit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app icons' robots (lib/shared/app_icon/) in step with the wardrobe (plan 9.10).
void main() {
  test('each icon shows a wardrobe part no other shows, unlocks once all it wears is, and only one wears the fez', () {
    final shown = <Enum>{};
    for (final robot in AppIconRobot.values) {
      final outfit = appIconOutfit(robot);
      expect(outfit.body, RobotBody.classic, reason: robot.name);
      expect(robot.level, [outfit.hat.level, outfit.head.level].reduce(math.max), reason: robot.name);
      if (!robot.head) expect(outfit.head, RobotHead.classic, reason: robot.name);
      final part = robot.head ? outfit.head : outfit.hat;
      expect(shown.add(part), isTrue, reason: '${robot.name} shows a part no other icon shows');
    }
    // Every hat, and every head but the classic one the hats stand on.
    expect(shown, {...RobotHat.values, ...RobotHead.values.where((head) => head != RobotHead.classic)});
    // The owner, 2026-11-14: too many fezzes before, each head wore it.
    expect(AppIconRobot.values.where((robot) => appIconOutfit(robot).hat == RobotHat.fez), [AppIconRobot.fez]);
  });

  test('the icons stand in the order they unlock', () {
    final levels = [for (final robot in AppIconRobot.values) robot.level];
    expect(levels, [...levels]..sort());
  });
}
