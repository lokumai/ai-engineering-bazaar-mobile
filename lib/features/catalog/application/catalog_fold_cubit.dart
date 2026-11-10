import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which levels of each track's catalog the reader opened or closed, kept in memory while the app runs (owner,
/// 2026-11-10): leaving the catalog and coming back finds the levels as they were, and a new launch forgets them.
///
/// A track the reader has not touched has no entry: its catalog opens the level of the next module to read and follows
/// it as modules are completed. The first open or close fixes that track's levels from what was showing.
///
/// A `Cubit` because every call is atomic and the event stream adds nothing.
final class CatalogFoldCubit extends Cubit<Map<Track, Set<String>>> {
  CatalogFoldCubit() : super(const {});

  /// The levels of [track]'s catalog that are open, [upNext] being the level of the next module to read, if any.
  Set<String> openIn(Track track, String? upNext) => state[track] ?? {?upNext};

  /// Opens [slug] in [track]'s catalog when closed and closes it when open, from the levels [openIn] gives.
  void toggle(Track track, String slug, String? upNext) {
    final open = {...openIn(track, upNext)};
    if (!open.remove(slug)) open.add(slug);
    emit({...state, track: Set.unmodifiable(open)});
  }
}
