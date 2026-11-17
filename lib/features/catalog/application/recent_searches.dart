import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the catalog's recent searches are kept on this device, apart from the record (plan 12.8); `lib/app/di/` fills
/// it with a file of the app's own.
abstract interface class IRecentSearchStore {
  /// The searches kept, the latest first.
  Future<List<String>> read();

  /// Keeps [searches], the latest first; none deletes the file.
  Future<void> write(List<String> searches);
}

/// A store that keeps the searches in memory only, for tests and for a device without storage.
final class MemoryRecentSearchStore implements IRecentSearchStore {
  MemoryRecentSearchStore([List<String> searches = const []]) : _searches = List.of(searches);

  List<String> _searches;

  @override
  Future<List<String>> read() async => List.of(_searches);

  @override
  Future<void> write(List<String> searches) async => _searches = List.of(searches);
}

/// The searches as the file keeps them: `{"schema":1,"searches":["tokenizer","rag"]}`.
String encodeRecentSearches(List<String> searches) => jsonEncode({'schema': 1, 'searches': searches});

/// The searches in [text]; anything that does not read as the file's shape reads as none. Losing them costs nothing.
List<String> decodeRecentSearches(String text) {
  try {
    if (jsonDecode(text) case {'schema': 1, 'searches': final List<Object?> searches}) {
      return [
        for (final search in searches)
          if (search is String && search.trim().isNotEmpty) search,
      ].take(RecentSearchesCubit.kept).toList();
    }
  } on FormatException {
    // A file that is not JSON reads as no search.
  }
  return const [];
}

/// The last searches the reader made in the catalog (plan 12.8), shown under the empty search field: at most [kept],
/// the latest first, one of each whatever its case. A search is kept when the reader opens one of its hits or sends it
/// from the keyboard, so a word half typed is not. Kept on this device only; Clear forgets them all.
///
/// A `Cubit`: every call is atomic and the event stream adds nothing.
final class RecentSearchesCubit extends Cubit<List<String>> {
  RecentSearchesCubit({IRecentSearchStore? store}) : _store = store ?? MemoryRecentSearchStore(), super(const []);

  /// How many searches are kept.
  static const kept = 5;

  final IRecentSearchStore _store;
  Future<void> _saving = Future.value();

  /// Reads the kept searches.
  Future<void> load() async {
    final searches = await _store.read();
    if (!isClosed) emit(List.unmodifiable(searches));
  }

  /// Puts [query] first, trimmed; the same words in another case give way to it.
  Future<void> add(String query) {
    final words = query.trim();
    if (words.isEmpty) return _saving;
    final lower = words.toLowerCase();
    return _keep([words, ...state.where((search) => search.toLowerCase() != lower)].take(kept).toList());
  }

  /// Forgets [search].
  Future<void> remove(String search) => _keep(state.where((kept) => kept != search).toList());

  /// Forgets every search.
  Future<void> clear() => _keep(const []);

  Future<void> _keep(List<String> searches) async {
    emit(List.unmodifiable(searches));
    final previous = _saving;
    final saving = _saving = () async {
      // A write that failed was logged by the store; the next one still runs.
      await previous.catchError((Object _) {});
      await _store.write(searches);
    }();
    await saving;
  }
}
