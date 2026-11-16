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

/// A launch ground that logs each look named to it.
final class _Ground implements ILaunchGround {
  final kept = <ThemeMode>[];

  @override
  Future<void> keep(ThemeMode mode) async => kept.add(mode);
}

/// A store that fails the test if it is read.
final class _UnreadStore implements IThemeStore {
  @override
  Future<ThemeMode?> chosen() => fail('read again');

  @override
  Future<void> choose(ThemeMode mode) async {}
}

void main() {
  test('starts light before anything is chosen', () => expect(ThemeChoiceCubit().state, ThemeMode.light));

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
    build: () => ThemeChoiceCubit(store: _Store(ThemeMode.dark)),
    act: (c) => c.load(),
    expect: () => [ThemeMode.dark],
  );
  blocTest<ThemeChoiceCubit, ThemeMode>(
    'load with no choice leaves it light',
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

  // The phone opens the next launch on the page colour of the look the reader reads in (the owner, 2026-11-15).
  group('the launch ground', () {
    test('load names the kept look', () async {
      final ground = _Ground();
      final cubit = ThemeChoiceCubit(store: _Store(ThemeMode.light), ground: ground);
      addTearDown(cubit.close);

      await cubit.load();

      expect(ground.kept, [ThemeMode.light]);
    });

    test('load names light when nothing was chosen', () async {
      final ground = _Ground();
      final cubit = ThemeChoiceCubit(store: _Store(), ground: ground);
      addTearDown(cubit.close);

      await cubit.load();

      expect(ground.kept, [ThemeMode.light]);
    });

    test('choose keeps the look, then names it', () async {
      final ground = _Ground();
      final store = _Store();
      final cubit = ThemeChoiceCubit(store: store, ground: ground);
      addTearDown(cubit.close);

      await cubit.choose(ThemeMode.light);
      await cubit.choose(ThemeMode.dark);

      expect(ground.kept, [ThemeMode.light, ThemeMode.dark]);
      expect(store.kept, ThemeMode.dark);
    });
  });

  // The boot reads the look before the first frame, so the app's first frame is on its ground (the owner, 2026-11-15).
  test('starts in the look the boot read, and load only names it', () async {
    final ground = _Ground();
    final cubit = ThemeChoiceCubit(store: _UnreadStore(), ground: ground, initial: ThemeMode.light);
    addTearDown(cubit.close);
    expect(cubit.state, ThemeMode.light);

    await cubit.load();

    expect(cubit.state, ThemeMode.light);
    expect(ground.kept, [ThemeMode.light]);
  });
}
