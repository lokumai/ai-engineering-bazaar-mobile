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
    'the first launch asks for the language and the track at once (plan 1Y)',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore()),
    act: (bloc) => bloc.add(const WelcomeStarted()),
    expect: () => [const WelcomeChoosingTrack()],
  );

  blocTest<WelcomeBloc, WelcomeState>(
    'a later launch goes straight to the app',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore(wasSeen: true)),
    act: (bloc) => bloc.add(const WelcomeStarted()),
    expect: () => [const WelcomeDone()],
  );

  blocTest<WelcomeBloc, WelcomeState>(
    'the first launch opens on the story when the content has one (plan 3.5)',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore()),
    act: (bloc) => bloc.add(const WelcomeStarted(story: true)),
    expect: () => [const WelcomeTellingStory()],
  );

  final store = _MemoryWelcomeStore();
  blocTest<WelcomeBloc, WelcomeState>(
    'reading the story asks for the track; choosing it opens the app and records it once (plan 1L, 3.5)',
    build: () => WelcomeBloc(store: store),
    act: (bloc) => bloc
      ..add(const WelcomeStarted(story: true))
      ..add(const WelcomeTrackChosen())
      ..add(const WelcomeStoryRead())
      ..add(const WelcomeStoryRead())
      ..add(const WelcomeTrackChosen())
      ..add(const WelcomeTrackChosen()),
    expect: () => [const WelcomeTellingStory(), const WelcomeChoosingTrack(), const WelcomeDone()],
    verify: (_) {
      expect(store.writes, 1);
      expect(store.wasSeen, isTrue);
    },
  );

  final notYet = _MemoryWelcomeStore();
  blocTest<WelcomeBloc, WelcomeState>(
    'Welcome is not recorded before a track is chosen',
    build: () => WelcomeBloc(store: notYet),
    act: (bloc) => bloc
      ..add(const WelcomeStoryRead())
      ..add(const WelcomeTrackChosen())
      ..add(const WelcomeStarted(story: true))
      ..add(const WelcomeStoryRead()),
    expect: () => [const WelcomeTellingStory(), const WelcomeChoosingTrack()],
    verify: (_) => expect(notYet.writes, 0),
  );
}
