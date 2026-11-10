import 'package:flutter_bloc/flutter_bloc.dart';

/// Which levels of the Quiz tab the reader opened or closed, kept in memory while the app runs (owner, 2026-11-10):
/// leaving the tab and coming back finds the levels as they were, and a new launch forgets them.
///
/// Until the reader opens or closes one, the state is null and the tab opens the level of the next module to read,
/// following it as modules are completed. The first open or close fixes the levels from what was showing.
///
/// A `Cubit` because every call is atomic and the event stream adds nothing.
final class QuizFoldCubit extends Cubit<Set<String>?> {
  QuizFoldCubit() : super(null);

  /// The levels that are open, [upNext] being the level of the next module to read, if any.
  Set<String> openWith(String? upNext) => state ?? {?upNext};

  /// Opens [slug] when closed and closes it when open, from the levels [openWith] gives.
  void toggle(String slug, String? upNext) {
    final open = {...openWith(upNext)};
    if (!open.remove(slug)) open.add(slug);
    emit(Set.unmodifiable(open));
  }
}
