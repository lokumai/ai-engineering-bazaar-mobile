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
    // One choice is written at a time, in the order made: the store clears the other choices before it keeps this one,
    // so two quick choices written at once could leave both kept, and the next start take the wrong one.
    final previous = _saving;
    final saving = _saving = () async {
      // A write that failed was logged by the store; the next one still runs.
      await previous.catchError((Object _) {});
      await _store.choose(track);
    }();
    await saving;
  }

  /// The write of the last choice, which the next one waits for.
  Future<void> _saving = Future<void>.value();
}
