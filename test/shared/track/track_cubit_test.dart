import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
