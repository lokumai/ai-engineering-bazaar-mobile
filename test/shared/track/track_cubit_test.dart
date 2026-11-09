import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Store implements ITrackStore {
  _Store([this.kept]);

  Track? kept;

  @override
  Future<Track?> chosen() async => kept;

  @override
  Future<void> choose(Track track) async => kept = track;
}

void main() {
  test('starts at For Engineers', () => expect(TrackCubit().state, Track.engineers));
  blocTest<TrackCubit, Track>(
    'select emits the chosen track',
    build: TrackCubit.new,
    act: (c) => c.select(Track.everyone),
    expect: () => [Track.everyone],
  );
  blocTest<TrackCubit, Track>(
    'selecting the current track emits nothing',
    build: TrackCubit.new,
    act: (c) => c.select(Track.engineers),
    expect: () => <Track>[],
  );

  group('the chosen track (plan 1L)', () {
    blocTest<TrackCubit, Track>(
      'load makes the kept choice current',
      build: () => TrackCubit(store: _Store(Track.everyone)),
      act: (c) => c.load(),
      expect: () => [Track.everyone],
    );
    blocTest<TrackCubit, Track>(
      'load with no choice kept stays at For Engineers',
      build: () => TrackCubit(store: _Store()),
      act: (c) => c.load(),
      expect: () => <Track>[],
    );

    test('choose makes the track current and keeps it; select keeps nothing', () async {
      final store = _Store();
      final cubit = TrackCubit(store: store);
      addTearDown(cubit.close);

      cubit.select(Track.everyone);
      expect(store.kept, isNull, reason: 'a link into the other track changes no choice');

      await cubit.choose(Track.engineers);
      expect(cubit.state, Track.engineers);
      expect(store.kept, Track.engineers);
    });
  });
}
