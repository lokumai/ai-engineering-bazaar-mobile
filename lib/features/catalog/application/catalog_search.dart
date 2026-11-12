import 'dart:math' as math;

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';
import 'package:equatable/equatable.dart';

/// The catalog's search (plan 7.1), after the web's search window (web M59, D95, D99; `src/lib/search/`): one entry per
/// module (its title and its opening), one per `##` section of a written module (its heading and its prose), and one
/// per level (its title and its blurb, in English as the web shows a level's name on every page), in the reader's
/// language, found by words typed as the web finds them. The web's index is served outside the bundle, so the
/// app builds its own from the module documents it already has; the rules below are the web's.

/// What a search entry is.
enum SearchKind { module, section, level }

/// One thing the search can find.
final class SearchEntry extends Equatable {
  const SearchEntry({
    required this.kind,
    required this.moduleKey,
    required this.number,
    required this.module,
    required this.section,
    required this.sectionId,
    required this.text,
    required this.ready,
  });

  final SearchKind kind;

  /// The module key, `<level>/<module>`; a level's slug on a level entry.
  final String moduleKey;
  final int number;

  /// The module's title in the document's language, or a level's title; matched as a name on a module or a level
  /// entry only.
  final String module;

  /// A section's heading; empty on a module entry.
  final String section;

  /// The heading's id, which the reader scrolls to; null on a module entry.
  final String? sectionId;

  /// The prose searched and shown around a match.
  final String text;

  /// False for a planned module, found by its title and its promise only.
  final bool ready;

  @override
  List<Object?> get props => [kind, moduleKey, number, module, section, sectionId, text, ready];
}

/// The entries of one module document: the module, then each `##` section of a written module (web `searchDocs`).
/// Code, images and diagrams are left out, as on the web: a reader searching "agent" does not want every `agent.run()`.
List<SearchEntry> entriesOf(ModuleDoc doc, {required int number}) {
  final body = doc.body;
  final ready = body != null;
  final opening = <Block>[];
  final parts = <(HeadingBlock, List<Block>)>[];
  for (final block in body ?? const <Block>[]) {
    if (block is HeadingBlock && block.depth <= 2) {
      parts.add((block, []));
    } else if (parts.isEmpty) {
      opening.add(block);
    } else {
      parts.last.$2.add(block);
    }
  }
  final intro = ready ? plainOf(opening) : (doc.draft?.summary ?? '');
  return [
    SearchEntry(
      kind: SearchKind.module,
      moduleKey: doc.key,
      number: number,
      module: doc.title,
      section: '',
      sectionId: null,
      text: intro,
      ready: ready,
    ),
    for (final (heading, blocks) in parts)
      SearchEntry(
        kind: SearchKind.section,
        moduleKey: doc.key,
        number: number,
        module: doc.title,
        section: _squash(inlineText(heading.inlines)),
        sectionId: heading.id,
        text: plainOf(blocks),
        ready: true,
      ),
  ];
}

/// The entry of a level (web `searchDocs`): its title, matched as a name, and its blurb.
SearchEntry levelEntryOf(LevelEntry level) => SearchEntry(
  kind: SearchKind.level,
  moduleKey: level.slug,
  number: 0,
  module: level.title,
  section: '',
  sectionId: null,
  text: level.blurb,
  ready: true,
);

/// The words of [blocks] a reader meets, one space between blocks and between list items (web `plain`).
String plainOf(List<Block> blocks) => _squash(blocks.map(_blockText).join(' '));

String _blockText(Block block) => switch (block) {
  ParagraphBlock(:final inlines) => inlineText(inlines),
  HeadingBlock(:final inlines) => inlineText(inlines),
  ListBlock(:final items) => items.map((item) => item.blocks.map(_blockText).join(' ')).join(' '),
  QuoteBlock(:final blocks) => blocks.map(_blockText).join(' '),
  CalloutBlock(:final title, :final blocks) => [
    if (title != null) inlineText(title),
    ...blocks.map(_blockText),
  ].join(' '),
  TableBlock(:final head, :final rows) => [
    for (final cell in head) inlineText(cell.inlines),
    for (final row in rows)
      for (final cell in row) inlineText(cell.inlines),
  ].join(' '),
  _ => '',
};

/// The text of [inlines] as read.
String inlineText(List<Inline> inlines) => inlines.map(_inlineText).join();

String _inlineText(Inline inline) => switch (inline) {
  TextInline(:final text) => text,
  CodeInline(:final text) => text,
  BreakInline() => ' ',
  StrongInline(:final inlines) => inlineText(inlines),
  EmphasisInline(:final inlines) => inlineText(inlines),
  DeleteInline(:final inlines) => inlineText(inlines),
  LinkInline(:final inlines) => inlineText(inlines),
  _ => '',
};

String _squash(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// The sections a reader does not search for: a list of links, and a module's own recap (web D99).
const _lists = {'references', 'summary', 'kaynaklar', 'özet', 'منابع', 'خلاصه'};

/// One match, with where to show it.
final class SearchHit extends Equatable {
  const SearchHit({required this.entry, required this.score, required this.excerpt, required this.marks});

  final SearchEntry entry;
  final double score;

  /// The text around the first match, or the start of the text.
  final String excerpt;

  /// The matched words in [excerpt], as start and end offsets.
  final List<(int, int)> marks;

  @override
  List<Object?> get props => [entry, score, excerpt, marks];
}

/// The hits of one query.
final class SearchResults extends Equatable {
  const SearchResults({required this.hits, required this.total});

  /// No hit.
  static const none = SearchResults(hits: [], total: 0);

  /// The best hits, at most [CatalogSearchIndex.limit].
  final List<SearchHit> hits;

  /// How many entries matched, the ones not shown included.
  final int total;

  @override
  List<Object?> get props => [hits, total];
}

enum _Field { title, section, text }

/// The search over a set of entries in one language, built once and queried as the reader types (web
/// `searchOptions`): the title weighs 4, a heading 3 and the prose 1; a word of three letters or more also matches as
/// the start of a longer word; a word may be about one letter in seven off; and every word typed must match. A planned
/// module weighs 0.7 and a References or Summary section 0.4, so they come after the explanation of the same thing.
final class CatalogSearchIndex {
  CatalogSearchIndex(this.entries, {required this.lang}) {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      _add(i, _Field.title, entry.kind == SearchKind.section ? '' : entry.module);
      _add(i, _Field.section, entry.section);
      _add(i, _Field.text, entry.text);
    }
  }

  final List<SearchEntry> entries;
  final String lang;

  /// Each word once, with the entries and fields that hold it and how often.
  final _postings = <String, List<(int, _Field, int)>>{};

  /// The most hits a query returns.
  static const limit = 40;

  static const _boost = {_Field.title: 4.0, _Field.section: 3.0, _Field.text: 1.0};

  void _add(int entry, _Field field, String text) {
    final counts = <String, int>{};
    for (final word in tokenize(text)) {
      final term = normalise(word, lang);
      if (term.length < 2) continue;
      counts[term] = (counts[term] ?? 0) + 1;
    }
    counts.forEach((term, count) => (_postings[term] ??= []).add((entry, field, count)));
  }

  /// The terms of [query] as the index holds them.
  List<String> termsOf(String query) => searchTerms(query, lang);

  /// The hits for [query], best first, at most [limit], and how many there are in all. A Persian query with a prefix or
  /// a suffix typed apart from its word is searched joined as well (web `joinedVariant`), each entry at its better score.
  SearchResults search(String query) {
    final terms = termsOf(query);
    if (terms.isEmpty) return SearchResults.none;
    final variant = joinedVariant(query, lang);
    final variantTerms = variant == null ? const <String>[] : termsOf(variant);
    final total = {...?_scores(terms)};
    _scores(variantTerms)?.forEach((i, score) {
      if (score > (total[i] ?? 0)) total[i] = score;
    });
    if (total.isEmpty) return SearchResults.none;
    final marked = {...terms, ...variantTerms}.toList();
    final ranked = [for (final MapEntry(key: i, :value) in total.entries) (i, value * _rank(entries[i]))]
      ..sort((a, b) => b.$2.compareTo(a.$2) != 0 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
    return SearchResults(
      hits: [for (final (i, score) in ranked.take(limit)) _hit(entries[i], score, marked)],
      total: ranked.length,
    );
  }

  /// The score of each entry that every one of [terms] matches; null when none does or there are no terms.
  Map<int, double>? _scores(List<String> terms) {
    if (terms.isEmpty) return null;
    Map<int, double>? total;
    for (final term in terms) {
      final scores = <int, double>{};
      _postings.forEach((word, postings) {
        final q = termQuality(term, word);
        if (q == 0) return;
        for (final (entry, field, count) in postings) {
          final score = q * _boost[field]! * (1 + math.log(count));
          if (score > (scores[entry] ?? 0)) scores[entry] = score;
        }
      });
      // Every word typed must match (combineWith AND).
      total = total == null
          ? scores
          : {
              for (final MapEntry(:key, :value) in total.entries)
                if (scores[key] case final score?) key: value + score,
            };
      if (total.isEmpty) return null;
    }
    return total;
  }

  static double _rank(SearchEntry entry) {
    if (!entry.ready) return 0.7;
    return _lists.contains(entry.section.toLowerCase()) ? 0.4 : 1;
  }

  /// The window of text shown on a hit: about [_window] characters around the first matched word, cut at words.
  static const _window = 160;

  SearchHit _hit(SearchEntry entry, double score, List<String> terms) {
    final text = entry.text;
    final words = wordPattern.allMatches(text).toList();
    bool matches(String word) => matchesTerms(word, terms, lang);

    final first = words.indexWhere((m) => matches(m[0]!));
    var start = 0;
    if (first > 0) {
      start = math.max(0, words[first].start - _window ~/ 3);
      if (start > 0) {
        final next = words.firstWhere((m) => m.start >= start, orElse: () => words[first]);
        start = next.start;
      }
    }
    var end = math.min(text.length, start + _window);
    if (end < text.length) {
      final last = words.lastWhere((m) => m.end <= end, orElse: () => words[first < 0 ? 0 : first]);
      end = math.max(last.end, start);
    }
    final excerpt = '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}';
    final shift = start > 0 ? 1 - start : -start;
    final marks = [
      for (final m in words)
        if (m.start >= start && m.end <= end && matches(m[0]!)) (m.start + shift, m.end + shift),
    ];
    return SearchHit(entry: entry, score: score, excerpt: excerpt, marks: marks);
  }
}
