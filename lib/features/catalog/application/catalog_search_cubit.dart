import 'dart:async';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search_indexes.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the catalog's search shows.
final class CatalogSearchState extends Equatable {
  const CatalogSearchState({this.query = '', this.results, this.reading = false, this.levels = const {}, this.other});

  /// The words typed, as typed.
  final String query;

  /// The levels the hits are kept to, by slug; none keeps every level.
  final Set<String> levels;

  /// What [query] found; null while there is no query or the documents are still being read.
  final SearchResults? results;

  /// Whether the module documents are being read for the first search.
  final bool reading;

  /// What [query] found in the other track's modules when it found nothing at all in this track (plan 12.7); null
  /// otherwise. Its hits open the other track's module and leave the reader's track as it is.
  final SearchResults? other;

  /// Whether the catalog shows the search instead of the levels.
  bool get active => query.trim().isNotEmpty;

  @override
  List<Object?> get props => [query, results, reading, levels, other];
}

/// The catalog's search in one track and one language (plan 7.1). The first query reads the track's module documents
/// in the language, or in English where a module has none, as the reader opens them, and builds the index once; each
/// query after that is searched as typed. A document that cannot be read is left out. The index is kept in [indexes],
/// above the page, so a tab left and come back to does not build it again (review 11, architecture 3).
final class CatalogSearchCubit extends Cubit<CatalogSearchState> {
  CatalogSearchCubit({
    required this._repository,
    required this._bundle,
    required this._track,
    required this._language,
    CatalogSearchIndexes? indexes,
  }) : _indexes = indexes ?? CatalogSearchIndexes(),
       super(const CatalogSearchState());

  static final _log = AppLogger.getLogger('CatalogSearchCubit');

  final IContentRepository _repository;
  final BundleIndex _bundle;
  final Track _track;
  final String _language;
  final CatalogSearchIndexes _indexes;
  Future<CatalogSearchIndex>? _building;
  CatalogSearchIndex? _index;

  /// The other track's modules, built the first time a query finds nothing in this track.
  Future<CatalogSearchIndex>? _otherBuilding;

  /// Counts the queries, so one answered after a later one is dropped.
  int _ticket = 0;

  /// Searches [query] in the levels chosen, or goes back to the catalog when it is empty, every level chosen again.
  Future<void> search(String query) async {
    // The search field outlives a cubit a content refresh replaced, and its timer may still call this one (review 10,
    // finding 9).
    if (isClosed) return;
    final ticket = ++_ticket;
    if (query.trim().isEmpty) {
      emit(const CatalogSearchState());
      return;
    }
    var index = _index;
    if (index == null) {
      emit(CatalogSearchState(query: query, reading: true, levels: state.levels));
      try {
        index = _index = await (_building ??= _indexed(_track, levels: true));
      } on Object catch (error, stack) {
        // A build that failed is not kept: the next query reads the documents again, rather than wait on it for ever.
        _building = null;
        _log.error('search index not built: {}\n{}', [error, stack]);
        if (!isClosed && ticket == _ticket) {
          emit(CatalogSearchState(query: query, results: SearchResults.none, levels: state.levels));
        }
        return;
      }
    }
    if (isClosed || ticket != _ticket) return;
    // The levels as chosen now: a choice made while the documents were read counts.
    final levels = state.levels;
    final results = index.search(query, levels: levels);
    // Nothing at all in this track, whatever levels are chosen: the other track's modules are looked in (plan 12.7).
    final none = results.total == 0 && (levels.isEmpty || index.search(query).total == 0);
    emit(CatalogSearchState(query: query, results: results, levels: levels));
    if (!none) return;
    final SearchResults other;
    try {
      other = (await (_otherBuilding ??= _indexed(_track.other, levels: false))).search(query);
    } on Object catch (error, stack) {
      _otherBuilding = null;
      _log.error('other track search index not built: {}\n{}', [error, stack]);
      return;
    }
    if (isClosed || ticket != _ticket || other.total == 0) return;
    emit(CatalogSearchState(query: query, results: results, levels: levels, other: other));
  }

  /// Keeps the hits to [levels] (by slug; none for every level) and searches the query again.
  Future<void> filter(Set<String> levels) async {
    if (isClosed) return;
    emit(
      CatalogSearchState(
        query: state.query,
        results: state.results,
        reading: state.reading,
        levels: levels,
        other: state.other,
      ),
    );
    if (state.active) await search(state.query);
  }

  /// Clears the query.
  void clear() {
    _ticket++;
    emit(const CatalogSearchState());
  }

  /// The index of [track]'s modules, and of the levels when [levels] is set: the levels are the same in both tracks,
  /// so the other track's index leaves them out. One kept is used again.
  Future<CatalogSearchIndex> _indexed(Track track, {required bool levels}) => _indexes.of((
    contentVersion: _bundle.contentVersion,
    track: track,
    language: _language,
    levels: levels,
  ), () => _build(track, levels: levels));

  Future<CatalogSearchIndex> _build(Track track, {required bool levels}) async {
    final entries = <SearchEntry>[];
    for (final module in _bundle.modules) {
      final docs = module.tracks[track]?.docs;
      // A module with no document in the track (For Everyone not written) is absent, as on the web.
      final path = docs?[_language] ?? docs?['en'];
      if (path == null) continue;
      try {
        entries.addAll(entriesOf(await _repository.readModuleDoc(path), number: module.number));
      } on Object catch (error) {
        // Any document that cannot be read, a storage error included, is left out rather than stopping the search.
        _log.warn('module document {} left out of search: {}', [path, error]);
      }
    }
    // The levels after the modules: the web's search finds a level by its name and its blurb.
    if (levels) entries.addAll(_bundle.levels.map(levelEntryOf));
    return _indexes.make(entries, _language);
  }
}
