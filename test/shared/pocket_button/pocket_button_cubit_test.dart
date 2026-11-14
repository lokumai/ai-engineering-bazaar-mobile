import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_cubit.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shown until hidden, and a hidden button stays hidden at the next start', () async {
    final store = MemoryPocketButtonStore();
    final cubit = PocketButtonCubit(store: store);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state, isTrue);

    await cubit.show(shown: false);
    expect((cubit.state, store.kept), (false, true));

    final next = PocketButtonCubit(store: store);
    addTearDown(next.close);
    await next.load();
    expect(next.state, isFalse);

    await next.show(shown: true);
    expect((next.state, store.kept), (true, false));
  });
}
