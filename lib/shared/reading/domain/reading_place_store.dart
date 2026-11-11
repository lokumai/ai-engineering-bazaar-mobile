import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';

/// Where the reading places are kept on this device (plan 1BA); `lib/app/di/` fills it with a file under Application
/// Support.
abstract interface class IReadingPlaceStore {
  /// Every place kept, by [readingPlaceKey]; none when nothing is kept or it cannot be read.
  Future<Map<String, ReadingPlace>> load();

  /// Keeps [places] in place of what was kept; an empty map removes them.
  Future<void> save(Map<String, ReadingPlace> places);
}

/// A store that keeps the places in memory only, for tests and for a device without storage.
final class MemoryReadingPlaceStore implements IReadingPlaceStore {
  MemoryReadingPlaceStore([Map<String, ReadingPlace> places = const {}]) : _places = places;

  Map<String, ReadingPlace> _places;

  @override
  Future<Map<String, ReadingPlace>> load() async => _places;

  @override
  Future<void> save(Map<String, ReadingPlace> places) async => _places = places;
}
