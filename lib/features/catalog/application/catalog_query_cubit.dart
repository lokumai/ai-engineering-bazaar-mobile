import 'package:flutter_bloc/flutter_bloc.dart';

/// The words in the catalog's search field, kept in memory while the app runs, as [CatalogFoldCubit] keeps the levels:
/// a tab left and come back to rebuilds the catalog, and finds the search as it was; a new launch starts empty.
///
/// A `Cubit` because every call is atomic and the event stream adds nothing.
final class CatalogQueryCubit extends Cubit<String> {
  CatalogQueryCubit() : super('');

  /// Keeps [query] as the field holds it.
  void keep(String query) => emit(query);
}
