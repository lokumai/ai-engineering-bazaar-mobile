import 'package:ai_engineering_bazaar/features/welcome/application/welcome_bloc.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// A store in memory that counts its writes.
final class _MemoryWelcomeStore implements IWelcomeStore {
  _MemoryWelcomeStore({this.wasSeen = false});

  bool wasSeen;
  int writes = 0;

  @override
  Future<bool> seen() async => wasSeen;

  @override
  Future<void> markSeen() async {
    writes++;
    wasSeen = true;
  }
}

void main() {
  test('starts checking', () {
    expect(WelcomeBloc(store: _MemoryWelcomeStore()).state, const WelcomeChecking());
  });

  blocTest<WelcomeBloc, WelcomeState>(
    'the first launch shows Welcome',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore()),
    act: (bloc) => bloc.add(const WelcomeStarted()),
    expect: () => [const WelcomeShowing()],
  );

  blocTest<WelcomeBloc, WelcomeState>(
    'a later launch goes straight to the app',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore(wasSeen: true)),
    act: (bloc) => bloc.add(const WelcomeStarted()),
    expect: () => [const WelcomeDone()],
  );

  final store = _MemoryWelcomeStore();
  blocTest<WelcomeBloc, WelcomeState>(
    'entering opens the app and records it once',
    build: () => WelcomeBloc(store: store),
    act: (bloc) => bloc
      ..add(const WelcomeStarted())
      ..add(const WelcomeEntered())
      ..add(const WelcomeEntered()),
    expect: () => [const WelcomeShowing(), const WelcomeDone()],
    verify: (_) {
      expect(store.writes, 1);
      expect(store.wasSeen, isTrue);
    },
  );

  blocTest<WelcomeBloc, WelcomeState>(
    'entering before Welcome shows does nothing',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore()),
    act: (bloc) => bloc.add(const WelcomeEntered()),
    expect: () => <WelcomeState>[],
  );
}
