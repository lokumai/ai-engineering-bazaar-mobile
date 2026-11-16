import 'package:ai_engineering_bazaar/features/tour/domain/tour_page.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Apprentice's tour (plan 11.3, the owner, 2026-11-16): for a first run only, it asks on Home whether to show the
/// reader around; said yes, each tab's first page is shown the first time it is opened. Settings' guide takes it again.
final class TourCubit extends Cubit<TourRecord?> {
  TourCubit({required this._store}) : super(null);

  final ITourStore _store;

  /// Reads where the reader is with it; null until then, and nothing shows.
  Future<void> load() async {
    final record = await _store.load();
    if (!isClosed && state == null) emit(record);
  }

  /// The first run's Welcome is over: the Apprentice is to ask.
  Future<void> offer() => _keep(const TourRecord(asking: true));

  /// The reader wants to be shown around.
  Future<void> accept() => _keep((state ?? const TourRecord()).copyWith(asking: false, guiding: true));

  /// The reader does not: no page is shown.
  Future<void> decline() => _keep((state ?? const TourRecord()).copyWith(asking: false, guiding: false));

  /// [page] was shown, to its end or skipped.
  Future<void> shown(TourPage page) {
    final record = state ?? const TourRecord();
    return _keep(record.copyWith(seen: {...record.seen, page.name}));
  }

  /// The tour from the start, every page shown again.
  Future<void> replay() => _keep(const TourRecord(guiding: true));

  /// Whether [page] is to be shown now.
  bool due(TourPage page) => switch (state) {
    TourRecord(:final guiding, :final seen) => guiding && !seen.contains(page.name),
    null => false,
  };

  Future<void> _keep(TourRecord record) async {
    if (isClosed) return;
    emit(record);
    await _store.save(record);
  }
}
