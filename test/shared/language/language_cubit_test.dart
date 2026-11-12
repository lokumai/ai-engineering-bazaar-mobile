import 'dart:async';

import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Store implements ILanguageStore {
  _Store([this.kept]);

  String? kept;

  @override
  Future<String?> chosen() async => kept;

  @override
  Future<void> choose(String language) async => kept = language;
}

/// A store whose writes wait until the test lets them finish, and that logs when each one starts.
final class _SlowStore implements ILanguageStore {
  final started = <String>[];
  final gates = <Completer<void>>[];

  @override
  Future<String?> chosen() async => null;

  @override
  Future<void> choose(String language) async {
    started.add(language);
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
  }
}

void main() {
  test('two quick choices are written one after the other, in the order made', () async {
    final store = _SlowStore();
    final cubit = LanguageCubit(store: store);
    unawaited(cubit.choose('tr'));
    final last = cubit.choose('fa');
    await pumpEventQueue();
    expect(store.started, ['tr'], reason: 'the second waits for the first');

    store.gates.first.complete();
    await pumpEventQueue();
    expect(store.started, ['tr', 'fa']);
    store.gates.last.complete();
    await last;
    expect(cubit.state, 'fa');
    await cubit.close();
  });

  test('starts in English', () => expect(LanguageCubit().state, 'en'));
  test('starts in the device language when the app has it', () => expect(LanguageCubit(initial: 'tr').state, 'tr'));
  test('starts in English when the device language is not one the app has', () {
    expect(LanguageCubit(initial: 'de').state, 'en');
  });

  blocTest<LanguageCubit, String>(
    'load makes the kept choice current',
    build: () => LanguageCubit(store: _Store('fa')),
    act: (c) => c.load(),
    expect: () => ['fa'],
  );
  blocTest<LanguageCubit, String>(
    'load with no choice keeps the starting language',
    build: () => LanguageCubit(store: _Store(), initial: 'tr'),
    act: (c) => c.load(),
    expect: () => <String>[],
  );

  test('choose makes the language current and keeps it', () async {
    final store = _Store();
    final cubit = LanguageCubit(store: store);
    addTearDown(cubit.close);

    await cubit.choose('tr');

    expect(cubit.state, 'tr');
    expect(store.kept, 'tr');
  });

  test('choose refuses a language the app does not have', () {
    expect(() => LanguageCubit().choose('de'), throwsArgumentError);
  });
}
