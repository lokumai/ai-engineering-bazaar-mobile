import 'dart:async';

import 'package:ai_engineering_bazaar/shared/robot_level/robot_level_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('it is 0 until it reads the kept level', () async {
    final cubit = RobotLevelCubit(read: () async => 6);
    addTearDown(cubit.close);
    expect(cubit.state, 0);
    await cubit.load();
    expect(cubit.state, 6);
  });

  test('a level the model told is kept over a read that comes later', () async {
    final read = Completer<int>();
    final cubit = RobotLevelCubit(read: () => read.future);
    addTearDown(cubit.close);
    final loading = cubit.load();
    cubit.reached(3);
    read.complete(9);
    await loading;
    expect(cubit.state, 3);
  });

  test('it goes back down when the model starts over', () {
    final cubit = RobotLevelCubit()..reached(8);
    addTearDown(cubit.close);
    cubit.reached(0);
    expect(cubit.state, 0);
  });
}
