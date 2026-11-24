import 'dart:async';

import 'package:ai_engineering_bazaar/shared/utils/serial_writes.dart';
import 'package:flutter_test/flutter_test.dart';

// Review 11, architecture 8: six cubits had their own copy of this queue, with two error semantics.
void main() {
  test('writes run one at a time, in the order asked', () async {
    final writes = SerialWrites();
    final first = Completer<void>();
    final done = <String>[];
    final a = writes.run(() async {
      await first.future;
      done.add('a');
    });
    final b = writes.run(() async => done.add('b'));
    await pumpEventQueue();
    expect(done, isEmpty, reason: 'b waits for a');
    first.complete();
    await Future.wait([a, b]);
    expect(done, ['a', 'b']);
  });

  test('a write that fails fails its own caller only, and the next still runs', () async {
    final writes = SerialWrites();
    final failed = writes.run(() async => throw StateError('disk'));
    final next = writes.run(() async {});
    await expectLater(failed, throwsStateError);
    await expectLater(next, completes);
  });
}
