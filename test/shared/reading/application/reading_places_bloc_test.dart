import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

final _at = DateTime.utc(2026, 11, 11, 9);
final _first = ReadingPlace(heading: 'one', offset: 40, share: 0.3, at: _at);
final _kept = {'engineers:alpha/first': _first};

void main() {
  late MemoryReadingPlaceStore store;

  setUp(() => store = MemoryReadingPlaceStore(_kept));

  blocTest<ReadingPlacesBloc, ReadingPlacesState>(
    'reads the kept places at start',
    build: () => ReadingPlacesBloc(store: store),
    act: (bloc) => bloc.add(const ReadingPlacesStarted()),
    expect: () => [ReadingPlacesReady(_kept)],
  );

  final later = ReadingPlace(offset: 500, share: 0.6, at: _at.add(const Duration(minutes: 5)));

  blocTest<ReadingPlacesBloc, ReadingPlacesState>(
    'a place is kept by track and module, and a module back at its top has none',
    build: () => ReadingPlacesBloc(store: store),
    act: (bloc) => bloc
      ..add(const ReadingPlacesStarted())
      ..add(ReadingPlaceKept(track: Track.everyone, module: 'alpha/first', place: later))
      ..add(ReadingPlaceKept(track: Track.everyone, module: 'alpha/first', place: later))
      ..add(const ReadingPlaceCleared(track: Track.engineers, module: 'alpha/first'))
      ..add(const ReadingPlaceCleared(track: Track.engineers, module: 'alpha/first')),
    expect: () => [
      ReadingPlacesReady(_kept),
      ReadingPlacesReady({..._kept, 'everyone:alpha/first': later}),
      ReadingPlacesReady({'everyone:alpha/first': later}),
    ],
    verify: (_) async => expect(await store.load(), {'everyone:alpha/first': later}),
  );

  blocTest<ReadingPlacesBloc, ReadingPlacesState>(
    'keeps only the most recent places',
    build: () => ReadingPlacesBloc(store: MemoryReadingPlaceStore()),
    act: (bloc) {
      bloc.add(const ReadingPlacesStarted());
      for (var i = 0; i <= ReadingPlacesBloc.kept; i++) {
        bloc.add(
          ReadingPlaceKept(
            track: Track.engineers,
            module: 'level/m$i',
            place: ReadingPlace(offset: 200, share: 0.5, at: _at.add(Duration(minutes: i))),
          ),
        );
      }
    },
    skip: ReadingPlacesBloc.kept + 1,
    verify: (bloc) {
      final places = (bloc.state as ReadingPlacesReady).places;
      expect(places, hasLength(ReadingPlacesBloc.kept));
      expect(places.containsKey('engineers:level/m0'), isFalse, reason: 'the oldest place goes');
    },
  );

  blocTest<ReadingPlacesBloc, ReadingPlacesState>(
    'an erase empties the places and its undo brings them back',
    build: () => ReadingPlacesBloc(store: store),
    act: (bloc) => bloc
      ..add(const ReadingPlacesStarted())
      ..add(const ReadingPlacesErased())
      ..add(const ReadingPlacesEraseUndone()),
    expect: () => [ReadingPlacesReady(_kept), const ReadingPlacesReady({}), ReadingPlacesReady(_kept)],
    verify: (_) async => expect(await store.load(), _kept),
  );

  blocTest<ReadingPlacesBloc, ReadingPlacesState>(
    'an undo with no erase changes nothing, and one after a new place brings the old places back with the new one',
    build: () => ReadingPlacesBloc(store: store),
    act: (bloc) => bloc
      ..add(const ReadingPlacesStarted())
      ..add(const ReadingPlacesEraseUndone())
      ..add(const ReadingPlacesErased())
      ..add(ReadingPlaceKept(track: Track.engineers, module: 'beta/fourth', place: later))
      ..add(const ReadingPlacesEraseUndone()),
    expect: () => [
      ReadingPlacesReady(_kept),
      const ReadingPlacesReady({}),
      ReadingPlacesReady({'engineers:beta/fourth': later}),
      ReadingPlacesReady({..._kept, 'engineers:beta/fourth': later}),
    ],
  );

  test('a place of the loading state is none', () {
    expect(const ReadingPlacesLoading().of(Track.engineers, 'alpha/first'), isNull);
    expect(ReadingPlacesReady(_kept).of(Track.engineers, 'alpha/first'), _first);
    expect(ReadingPlacesReady(_kept).of(Track.everyone, 'alpha/first'), isNull);
  });
}
