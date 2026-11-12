import 'package:ai_engineering_bazaar/features/welcome/application/welcome_bloc.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
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
    'the first launch asks for the language and the track first, and says whether the story follows (plan 3.5)',
    build: () => WelcomeBloc(store: _MemoryWelcomeStore()),
    act: (bloc) => bloc.add(const WelcomeStarted(story: true)),
    expect: () => [const WelcomeChoosingTrack(story: true)],
  );

  final store = _MemoryWelcomeStore();
  blocTest<WelcomeBloc, WelcomeState>(
    'choosing the track tells the story; reading it opens the app and records it once (plan 1L, 3.5)',
    build: () => WelcomeBloc(store: store),
    act: (bloc) => bloc
      ..add(const WelcomeStarted(story: true))
      ..add(const WelcomeStoryRead())
      ..add(const WelcomeTrackChosen(Track.everyone))
      ..add(const WelcomeTrackChosen(Track.engineers))
      ..add(const WelcomeStoryRead())
      ..add(const WelcomeStoryRead()),
    expect: () => [
      const WelcomeChoosingTrack(story: true),
      const WelcomeTellingStory(track: Track.everyone),
      const WelcomeDone(chosen: Track.everyone),
    ],
    verify: (_) {
      expect(store.writes, 1);
      expect(store.wasSeen, isTrue);
    },
  );

  final noStory = _MemoryWelcomeStore();
  blocTest<WelcomeBloc, WelcomeState>(
    'without a story, choosing the track opens the app and records it (web D125)',
    build: () => WelcomeBloc(store: noStory),
    act: (bloc) => bloc
      ..add(const WelcomeStarted())
      ..add(const WelcomeTrackChosen(Track.engineers)),
    expect: () => [const WelcomeChoosingTrack(), const WelcomeDone(chosen: Track.engineers)],
    verify: (_) => expect(noStory.writes, 1),
  );

  final notYet = _MemoryWelcomeStore();
  blocTest<WelcomeBloc, WelcomeState>(
    'Welcome is not recorded before the story is read, so a launch left during it asks again',
    build: () => WelcomeBloc(store: notYet),
    act: (bloc) => bloc
      ..add(const WelcomeStoryRead())
      ..add(const WelcomeTrackChosen(Track.engineers))
      ..add(const WelcomeStarted(story: true))
      ..add(const WelcomeTrackChosen(Track.engineers)),
    expect: () => [const WelcomeChoosingTrack(story: true), const WelcomeTellingStory(track: Track.engineers)],
    verify: (_) => expect(notYet.writes, 0),
  );
}
