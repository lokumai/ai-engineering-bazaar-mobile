import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'reading_places_event.dart';
part 'reading_places_state.dart';

/// Where each module was left on this device (plan 1BA): the reader keeps the place as the reader scrolls and opens a
/// module there, Home offers the module left last as Continue reading, and Settings' reset erases the places with the
/// record and brings them back on undo.
///
/// A `Bloc` because it touches storage: every event runs in one queue, so a save never overtakes another.
final class ReadingPlacesBloc extends Bloc<ReadingPlacesEvent, ReadingPlacesState> {
  ReadingPlacesBloc({required this._store}) : super(const ReadingPlacesLoading()) {
    on<ReadingPlacesEvent>(_onEvent, transformer: EventTransformers.queue());
  }

  final IReadingPlaceStore _store;

  /// How many places are kept at most: the most recent ones, so the file stays small.
  static const kept = 50;

  /// The places the last reset erased, while its undo may bring them back.
  Map<String, ReadingPlace>? _erased;

  Map<String, ReadingPlace> get _places => switch (state) {
    ReadingPlacesReady(:final places) => places,
    ReadingPlacesLoading() => const {},
  };

  Future<void> _onEvent(ReadingPlacesEvent event, Emitter<ReadingPlacesState> emit) async {
    switch (event) {
      case ReadingPlacesStarted():
        emit(ReadingPlacesReady(await _store.load()));
      case ReadingPlaceKept(:final track, :final module, :final place):
        final key = readingPlaceKey(track, module);
        if (_places[key] == place) return;
        final places = _newest({..._places, key: place});
        _erased = null;
        emit(ReadingPlacesReady(places));
        await _store.save(places);
      case ReadingPlaceCleared(:final track, :final module):
        final key = readingPlaceKey(track, module);
        if (!_places.containsKey(key)) return;
        final places = {..._places}..remove(key);
        emit(ReadingPlacesReady(places));
        await _store.save(places);
      case ReadingPlacesErased():
        _erased = _places;
        emit(const ReadingPlacesReady({}));
        await _store.save(const {});
      case ReadingPlacesEraseUndone():
        final erased = _erased;
        if (erased == null) return;
        _erased = null;
        emit(ReadingPlacesReady(erased));
        await _store.save(erased);
    }
  }

  /// The [kept] most recent of [places].
  static Map<String, ReadingPlace> _newest(Map<String, ReadingPlace> places) {
    if (places.length <= kept) return places;
    final entries = places.entries.toList()..sort((a, b) => b.value.at.compareTo(a.value.at));
    return Map.fromEntries(entries.take(kept));
  }
}
