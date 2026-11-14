import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an outfit is kept as its parts by name, and read back', () {
    const outfit = RobotOutfit(hat: RobotHat.topHat, head: RobotHead.tv, body: RobotBody.labCoat);
    expect(encodeRobotOutfit(outfit), '{"hat":"topHat","head":"tv","body":"labCoat"}');
    expect(decodeRobotOutfit(encodeRobotOutfit(outfit)), outfit);
  });

  test('a part it does not know is the first of its kind; text that is no outfit is none', () {
    expect(decodeRobotOutfit('{"hat":"sombrero","head":"dome"}'), const RobotOutfit(head: RobotHead.dome));
    expect(decodeRobotOutfit('not json'), isNull);
    expect(decodeRobotOutfit('[1]'), isNull);
  });

  test('it reads what was kept, and keeps each part put on', () async {
    final store = MemoryRobotOutfitStore(const RobotOutfit(hat: RobotHat.beanie));
    final cubit = RobotOutfitCubit(store: store);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.hat, RobotHat.beanie);

    await cubit.wear(RobotBody.kaftan);
    await cubit.wear(RobotHead.ears);
    expect(cubit.state, const RobotOutfit(hat: RobotHat.beanie, head: RobotHead.ears, body: RobotBody.kaftan));
    expect(store.kept, cubit.state);
  });

  test('with nothing kept it wears its first outfit', () async {
    final cubit = RobotOutfitCubit(store: MemoryRobotOutfitStore());
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state, RobotOutfit.initial);
  });
}
