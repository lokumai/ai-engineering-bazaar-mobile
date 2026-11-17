import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_assistant.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// The face on the Apprentice's button in the corner, which its card in the sheet must agree with.
void main() {
  final noon = DateTime.utc(2026, 11, 16, 12);
  final longAgo = noon.subtract(const Duration(days: 1));

  RobotFace faceOf(PocketModelReady state) => withClock(Clock.fixed(noon), () => robotFaceOf(state));

  test('asleep, it shows asleep', () {
    expect(faceOf(PocketModelReady(model: PocketModel(tokens: 40, lastFed: longAgo), awake: false)), RobotFace.asleep);
  });

  // The owner, 2026-11-16: woken and not fed since, its button still slept while its card was awake.
  test('woken and not fed since, it is awake and calm, as its card shows it', () {
    expect(faceOf(PocketModelReady(model: PocketModel(tokens: 40, lastFed: longAgo), awake: true)), RobotFace.calm);
  });

  test('not fed for a few hours, it is hungry', () {
    final fed = noon.subtract(PocketModel.hungerAfter);
    expect(faceOf(PocketModelReady(model: PocketModel(tokens: 40, lastFed: fed), awake: true)), RobotFace.hungry);
  });
}
