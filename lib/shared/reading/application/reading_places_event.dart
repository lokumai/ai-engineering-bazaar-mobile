part of 'reading_places_bloc.dart';

sealed class ReadingPlacesEvent {
  const ReadingPlacesEvent();
}

/// Reads the places kept on this device, once at start.
final class ReadingPlacesStarted extends ReadingPlacesEvent {
  const ReadingPlacesStarted();
}

/// The reader left the module [module] of [track] at [place].
final class ReadingPlaceKept extends ReadingPlacesEvent {
  const ReadingPlaceKept({required this.track, required this.module, required this.place});

  final Track track;
  final String module;
  final ReadingPlace place;
}

/// The reader went back to the top of the module [module] of [track]: it has no place any more.
final class ReadingPlaceCleared extends ReadingPlacesEvent {
  const ReadingPlaceCleared({required this.track, required this.module});

  final Track track;
  final String module;
}

/// Settings' reset erased the record: the places go with it, kept aside for its undo.
final class ReadingPlacesErased extends ReadingPlacesEvent {
  const ReadingPlacesErased();
}

/// The reset was undone: the places it erased come back.
final class ReadingPlacesEraseUndone extends ReadingPlacesEvent {
  const ReadingPlacesEraseUndone();
}
