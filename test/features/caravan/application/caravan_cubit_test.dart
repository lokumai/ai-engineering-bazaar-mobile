import 'package:ai_engineering_bazaar/features/caravan/application/caravan_cubit.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dwell = Duration(seconds: 4);

  test('starts resting at the first stop', () {
    expect(CaravanCubit().state, const CaravanResting(0));
  });

  test('select, next and previous stay on the road', () {
    final cubit = CaravanCubit()..select(3, count: 5);
    expect(cubit.state, const CaravanResting(3));
    cubit.next(count: 5);
    expect(cubit.state.selected, 4);
    cubit.next(count: 5);
    expect(cubit.state.selected, 4, reason: 'no stop after the last');
    cubit.select(-2, count: 5);
    expect(cubit.state.selected, 0);
    cubit.previous(count: 5);
    expect(cubit.state.selected, 0, reason: 'no stop before the first');
  });

  test('a road with no stop changes nothing', () {
    final cubit = CaravanCubit()
      ..select(2, count: 0)
      ..tour(count: 0);
    expect(cubit.state, const CaravanResting(0));
  });

  test('a tour walks to the next stop at once, then one stop a dwell, and rests after the last', () {
    fakeAsync((async) {
      final cubit = CaravanCubit(dwell: dwell)..select(1, count: 4);
      cubit.tour(count: 4);
      expect(cubit.state, const CaravanTouring(2));
      async.elapse(dwell);
      expect(cubit.state, const CaravanTouring(3));
      async.elapse(dwell);
      expect(cubit.state, const CaravanResting(3));
      async.elapse(dwell * 3);
      expect(cubit.state, const CaravanResting(3), reason: 'the tour is over');
      cubit.close();
    });
  });

  test('a tour from the last stop starts again at the first', () {
    final cubit = CaravanCubit()
      ..select(3, count: 4)
      ..tour(count: 4);
    expect(cubit.state, const CaravanTouring(0));
    cubit.close();
  });

  test('a move by the reader ends the tour where it chooses', () {
    fakeAsync((async) {
      final cubit = CaravanCubit(dwell: dwell)..tour(count: 6);
      cubit.previous(count: 6);
      expect(cubit.state, const CaravanResting(0));
      async.elapse(dwell * 2);
      expect(cubit.state, const CaravanResting(0), reason: 'no tour left running');
      cubit.close();
    });
  });

  test('rest ends a tour where the caravan is, and does nothing when resting', () {
    fakeAsync((async) {
      final cubit = CaravanCubit(dwell: dwell)..tour(count: 6);
      async.elapse(dwell);
      cubit.rest();
      expect(cubit.state, const CaravanResting(2));
      async.elapse(dwell * 2);
      expect(cubit.state, const CaravanResting(2));
      final before = cubit.state;
      cubit.rest();
      expect(cubit.state, same(before));
      cubit.close();
    });
  });

  test('closing ends a tour', () {
    fakeAsync((async) {
      final cubit = CaravanCubit(dwell: dwell)..tour(count: 6);
      cubit.close();
      async.elapse(dwell * 3);
      expect(async.pendingTimers, isEmpty);
    });
  });
}
