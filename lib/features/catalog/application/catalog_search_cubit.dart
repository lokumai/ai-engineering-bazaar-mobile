import 'dart:async';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the catalog's search shows.
final class CatalogSearchState extends Equatable {
  const CatalogSearchState({this.query = '', this.results, this.reading = false});

  /// The words typed, as typed.
  final String query;

  /// What [query] found; null while there is no query or the documents are still being read.
  final SearchResults? results;

  /// Whether the module documents are being read for the first search.
  final bool reading;

  /// Whether the catalog shows the search instead of the levels.
  bool get active => query.trim().isNotEmpty;

  @override
  List<Object?> get props => [query, results, reading];
}

/// The catalog's search in one track and one language (plan 7.1). The first query reads the track's module documents
/// in the language, or in English where a module has none, as the reader opens them, and builds the index once; each
/// query after that is searched as typed. A document that cannot be read is left out.
final class CatalogSearchCubit extends Cubit<CatalogSearchState> {
  CatalogSearchCubit({required this._repository, required this._bundle, required this._track, required this._language})
    : super(const CatalogSearchState());

  static final _log = AppLogger.getLogger('CatalogSearchCubit');

  final IContentRepository _repository;
  final BundleIndex _bundle;
  final Track _track;
  final String _language;
  Future<CatalogSearchIndex>? _building;
  CatalogSearchIndex? _index;

  /// Counts the queries, so one answered after a later one is dropped.
  int _ticket = 0;

  /// Searches [query], or goes back to the catalog when it is empty.
  Future<void> search(String query) async {
    final ticket = ++_ticket;
    if (query.trim().isEmpty) {
      emit(const CatalogSearchState());
      return;
    }
    var index = _index;
    if (index == null) {
      emit(CatalogSearchState(query: query, reading: true));
      index = _index = await (_building ??= _build());
    }
    if (isClosed || ticket != _ticket) return;
    emit(CatalogSearchState(query: query, results: index.search(query)));
  }

  /// Clears the query.
  void clear() {
    _ticket++;
    emit(const CatalogSearchState());
  }

  Future<CatalogSearchIndex> _build() async {
    final entries = <SearchEntry>[];
    for (final module in _bundle.modules) {
      final docs = module.tracks[_track]?.docs;
      // A module with no document in the track (For Everyone not written) is absent, as on the web.
      final path = docs?[_language] ?? docs?['en'];
      if (path == null) continue;
      try {
        entries.addAll(entriesOf(await _repository.readModuleDoc(path), number: module.number));
      } on ContentMissingException catch (error) {
        _log.warn('module document {} left out of search: {}', [path, error]);
      } on ContentCorruptException catch (error) {
        _log.warn('module document {} left out of search: {}', [path, error]);
      } on ContentFormatException catch (error) {
        _log.warn('module document {} left out of search: {}', [path, error]);
      }
    }
    // The levels after the modules: the web's search finds a level by its name and its blurb.
    entries.addAll(_bundle.levels.map(levelEntryOf));
    return CatalogSearchIndex(entries, lang: _language);
  }
}
