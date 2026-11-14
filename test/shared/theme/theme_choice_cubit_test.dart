import 'dart:async';

import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

final class _Store implements IThemeStore {
  _Store([this.kept]);

  ThemeMode? kept;

  @override
  Future<ThemeMode?> chosen() async => kept;

  @override
  Future<void> choose(ThemeMode mode) async => kept = mode;
}

/// A store whose writes wait until the test lets them finish, and that logs when each one starts.
final class _SlowStore implements IThemeStore {
  final started = <ThemeMode>[];
  final gates = <Completer<void>>[];

  @override
  Future<ThemeMode?> chosen() async => null;

  @override
  Future<void> choose(ThemeMode mode) async {
    started.add(mode);
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
  }
}

void main() {
  test('starts dark before anything is chosen', () => expect(ThemeChoiceCubit().state, ThemeMode.dark));

  test('a control offers light and dark only', () {
    expect(ThemeChoiceCubit.modes, [ThemeMode.light, ThemeMode.dark]);
  });

  test('the memory store keeps nothing', () async {
    const store = MemoryThemeStore();
    await store.choose(ThemeMode.dark);
    expect(await store.chosen(), isNull);
  });

  blocTest<ThemeChoiceCubit, ThemeMode>(
    'load makes the kept choice current',
    build: () => ThemeChoiceCubit(store: _Store(ThemeMode.light)),
    act: (c) => c.load(),
    expect: () => [ThemeMode.light],
  );
  blocTest<ThemeChoiceCubit, ThemeMode>(
    'load with no choice leaves it dark',
    build: () => ThemeChoiceCubit(store: _Store()),
    act: (c) => c.load(),
    expect: () => <ThemeMode>[],
  );

  test('choose makes the mode current and keeps it', () async {
    final store = _Store();
    final cubit = ThemeChoiceCubit(store: store);
    addTearDown(cubit.close);

    await cubit.choose(ThemeMode.light);

    expect(cubit.state, ThemeMode.light);
    expect(store.kept, ThemeMode.light);
  });

  test('two quick choices are written one after the other, in the order made', () async {
    final store = _SlowStore();
    final cubit = ThemeChoiceCubit(store: store);
    unawaited(cubit.choose(ThemeMode.light));
    final last = cubit.choose(ThemeMode.dark);
    await pumpEventQueue();
    expect(store.started, [ThemeMode.light], reason: 'the second waits for the first');

    store.gates.first.complete();
    await pumpEventQueue();
    expect(store.started, [ThemeMode.light, ThemeMode.dark]);
    store.gates.last.complete();
    await last;
    expect(cubit.state, ThemeMode.dark);
    await cubit.close();
  });
}
