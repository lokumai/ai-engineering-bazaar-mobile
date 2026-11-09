import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The current track, For Engineers at start.
///
/// The web keeps the track per browser tab in session storage and never in the record (Decision A11, web
/// `src/lib/tracks.ts`), so reading writes nothing to the record; the app keeps it in memory for the same reason.
final class TrackCubit extends Cubit<Track> {
  TrackCubit() : super(Track.engineers);

  /// Makes [track] the current track; choosing the current one emits nothing.
  void select(Track track) {
    if (track == state) return;
    emit(track);
  }
}
