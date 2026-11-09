import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The current track, For Engineers until the chosen one is read.
///
/// The reader chooses a track once, on Welcome, and can change it in Settings (plan 1L); the choice is kept by the
/// [ITrackStore], on this device and never in the record (the web keeps its track out of the record too, Decision
/// A11). Opening a page of the other track, by a link, makes it the current track for this run without changing the
/// choice, as the web remembers the last track page opened.
final class TrackCubit extends Cubit<Track> {
  TrackCubit({this._store = const MemoryTrackStore()}) : super(Track.engineers);

  final ITrackStore _store;

  /// Reads the chosen track, if one was chosen, and makes it the current track.
  Future<void> load() async {
    final chosen = await _store.chosen();
    if (chosen != null && !isClosed) select(chosen);
  }

  /// Makes [track] the current track for this run; choosing the current one emits nothing.
  void select(Track track) {
    if (track == state) return;
    emit(track);
  }

  /// Makes [track] the current track and keeps it as the reader's choice.
  Future<void> choose(Track track) async {
    select(track);
    await _store.choose(track);
  }
}
