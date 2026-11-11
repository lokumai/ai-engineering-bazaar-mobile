part of 'reading_places_bloc.dart';

sealed class ReadingPlacesState extends Equatable {
  const ReadingPlacesState();
}

/// The places are being read.
final class ReadingPlacesLoading extends ReadingPlacesState {
  const ReadingPlacesLoading();

  @override
  List<Object?> get props => const [];
}

/// The places of this device by [readingPlaceKey]; a module never scrolled, or scrolled back to its top, has none.
final class ReadingPlacesReady extends ReadingPlacesState {
  const ReadingPlacesReady(this.places);

  final Map<String, ReadingPlace> places;

  @override
  List<Object?> get props => [places];
}

/// The place of the module [module] in [track], or null when it has none or the places are being read.
extension ReadingPlaceOf on ReadingPlacesState {
  ReadingPlace? of(Track track, String module) => switch (this) {
    ReadingPlacesReady(:final places) => places[readingPlaceKey(track, module)],
    ReadingPlacesLoading() => null,
  };
}
