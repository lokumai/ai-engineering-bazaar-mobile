import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// The track the reader chose, kept on this device apart from the record (plan 1L): the track cubit's port, which
/// `lib/app/di/` fills with the app's file flags.
abstract interface class ITrackStore {
  /// The track chosen on this device, or null when none was chosen yet.
  Future<Track?> chosen();

  /// Keeps [track] as the chosen track.
  Future<void> choose(Track track);
}

/// A store that keeps nothing: the track lives in memory only, For Engineers at every start.
final class MemoryTrackStore implements ITrackStore {
  const MemoryTrackStore();

  @override
  Future<Track?> chosen() async => null;

  @override
  Future<void> choose(Track track) async {}
}
