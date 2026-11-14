import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('it starts in its fez, its classic screen and its own body, all open at level 0', () {
    expect(RobotOutfit.initial, const RobotOutfit(hat: RobotHat.fez, head: RobotHead.classic, body: RobotBody.classic));
    expect([RobotHat.fez.level, RobotHead.classic.level, RobotBody.classic.level], [0, 0, 0]);
  });

  test('every level from 1 to 13 unlocks something to wear, and nothing waits past it', () {
    // Feeds reach the first levels, a module a level after them: thirteen are a few modules in.
    const last = 13;
    expect(last, greaterThan(PocketModel.feedLevels));
    for (var level = 1; level <= last; level++) {
      expect(RobotOutfit.unlockedAt(level), isNotEmpty, reason: 'level $level');
    }
    final all = [
      ...RobotHat.values.map((p) => p.level),
      ...RobotHead.values.map((p) => p.level),
      ...RobotBody.values.map((p) => p.level),
    ];
    expect(all.every((level) => level <= last), isTrue);
    expect(RobotOutfit.unlockedAt(0), isEmpty, reason: 'what is open from the start is not news');
  });

  test('worn below its level, a part is its first of its kind until the model reaches it again', () {
    const chosen = RobotOutfit(hat: RobotHat.crown, head: RobotHead.dome, body: RobotBody.vest);
    expect(chosen.within(0), RobotOutfit.initial);
    expect(chosen.within(3), const RobotOutfit(head: RobotHead.dome, body: RobotBody.vest));
    expect(chosen.within(12), chosen);
  });

  test('only the fez and the graduation cap hang their bead on a tassel', () {
    expect(
      [
        for (final hat in RobotHat.values)
          if (hat.tassel) hat,
      ],
      [RobotHat.fez, RobotHat.mortarboard],
    );
  });
}
