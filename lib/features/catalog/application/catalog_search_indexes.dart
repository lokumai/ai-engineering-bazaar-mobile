import 'dart:async';
import 'dart:isolate';

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// Builds the search index of [entries] in [lang].
typedef CatalogIndexMaker = Future<CatalogSearchIndex> Function(List<SearchEntry> entries, String lang);

/// Which index: the content's version, the track, the language, and whether it holds the levels too.
typedef CatalogIndexKey = ({String contentVersion, Track track, String language, bool levels});

/// The catalog's search indexes, kept above its page (review 11, architecture 3): the page's cubit went with the tab,
/// so each visit with a search kept read every module document again and built the index in one block on the screen's
/// thread, about seven dropped frames. The last [keep] built are kept, by content version, track, language and
/// whether the levels are in it; one that failed is not kept, so the next search builds it again.
final class CatalogSearchIndexes {
  CatalogSearchIndexes({this.keep = 4, CatalogIndexMaker? make}) : make = make ?? _makeHere;

  /// How many indexes it keeps.
  final int keep;

  /// How an index is built from its entries: on the calling isolate by default, in another in the app ([makeApart]).
  final CatalogIndexMaker make;

  final Map<CatalogIndexKey, Future<CatalogSearchIndex>> _kept = {};

  static Future<CatalogSearchIndex> _makeHere(List<SearchEntry> entries, String lang) async =>
      CatalogSearchIndex(entries, lang: lang);

  /// Builds the index in another isolate; the entries are plain data, and the index comes back without a copy.
  static Future<CatalogSearchIndex> makeApart(List<SearchEntry> entries, String lang) =>
      Isolate.run(() => CatalogSearchIndex(entries, lang: lang));

  /// The index for [key]: the one kept, or the one [build] builds, then kept.
  Future<CatalogSearchIndex> of(CatalogIndexKey key, Future<CatalogSearchIndex> Function() build) {
    final kept = _kept.remove(key);
    if (kept != null) return _kept[key] = kept;
    final building = _kept[key] = build();
    building.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_kept[key], building)) _kept.remove(key);
      },
    );
    while (_kept.length > keep) {
      _kept.remove(_kept.keys.first);
    }
    return building;
  }
}
