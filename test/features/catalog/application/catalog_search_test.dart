@Tags(['unit'])
library;

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

HeadingBlock _h(String id, String text, {int depth = 2}) => HeadingBlock(
  depth: depth,
  id: id,
  mark: null,
  inlines: [TextInline(text: text)],
);

SearchEntry _entry(
  String text, {
  SearchKind kind = SearchKind.section,
  String module = 'A module',
  String section = 'A section',
  String key = 'alpha/first',
  bool ready = true,
}) => SearchEntry(
  kind: kind,
  moduleKey: key,
  number: 1,
  module: module,
  section: kind == SearchKind.module ? '' : section,
  sectionId: kind == SearchKind.module ? null : 'a-section',
  text: text,
  ready: ready,
);

void main() {
  group('normalise, as the web does', () {
    test('English is lower-cased', () => expect(normalise('Agent', 'en'), 'agent'));

    test('Turkish folds its letters, so a word typed on an English keyboard finds it', () {
      expect(normalise('Görev', 'tr'), 'gorev');
      expect(normalise('IŞIK', 'tr'), 'isik');
      expect(normalise('İçerik', 'tr'), 'icerik');
    });

    test('Persian makes the Arabic forms Persian and drops the non-joiner and the digits', () {
      expect(normalise('كتاب', 'fa'), 'کتاب');
      expect(normalise('ي', 'fa'), 'ی');
      expect(normalise('می\u200cخوام', 'fa'), 'میخوام');
      expect(normalise('۱۲', 'fa'), '12');
    });
  });

  test('tokenize splits on space and punctuation and keeps a joined Persian word whole and in parts', () {
    expect(tokenize('Tool-calling, agents: (RAG).'), ['Tool', 'calling', 'agents', 'RAG']);
    expect(tokenize('a\u200cb'), ['a', 'b', 'a\u200cb']);
    expect(tokenize('LLMها'), ['LLM', 'ها']);
  });

  group('entriesOf', () {
    test('a written module gives itself, by its opening, then one entry per ## section', () {
      final doc = testDoc(
        title: 'Tool Belts',
        body: [
          _p('An opening.'),
          _h('why', 'Why tools'),
          _p('Models call tools.'),
          _h('deep', 'A deeper heading', depth: 3),
          const CodeBlock(
            language: 'py',
            lines: [
              [CodeToken(text: 'agent.run()', role: null, bold: false)],
            ],
          ),
          _p('More prose.'),
          _h('refs', 'References'),
          const ListBlock(
            ordered: false,
            start: null,
            items: [
              ListItem(
                checked: null,
                blocks: [
                  ParagraphBlock(inlines: [TextInline(text: 'One')], lead: false),
                ],
              ),
              ListItem(
                checked: null,
                blocks: [
                  ParagraphBlock(inlines: [TextInline(text: 'Two')], lead: false),
                ],
              ),
            ],
          ),
        ],
      );

      final entries = entriesOf(doc, number: 4);

      expect(entries.map((e) => (e.kind, e.section, e.sectionId, e.text)), [
        (SearchKind.module, '', null, 'An opening.'),
        (SearchKind.section, 'Why tools', 'why', 'Models call tools. A deeper heading More prose.'),
        (SearchKind.section, 'References', 'refs', 'One Two'),
      ]);
      expect(entries.every((e) => e.module == 'Tool Belts' && e.number == 4 && e.ready), isTrue);
    });

    test('a planned module is found by its title and its promise only', () {
      final doc = testDoc(
        title: 'Later',
        draft: const Draft(summary: 'What it will teach.', parts: ['One'], written: null),
      );

      expect(entriesOf(doc, number: 9), [
        const SearchEntry(
          kind: SearchKind.module,
          moduleKey: 'alpha/first',
          number: 9,
          module: 'Later',
          section: '',
          sectionId: null,
          text: 'What it will teach.',
          ready: false,
        ),
      ]);
    });
  });

  group('CatalogSearchIndex', () {
    test('every word typed must match', () {
      final index = CatalogSearchIndex([_entry('agents call tools'), _entry('agents read files')], lang: 'en');

      expect(index.search('agents tools').hits.map((h) => h.entry.text), ['agents call tools']);
      expect(index.search('agents nothing').hits, isEmpty);
    });

    test('a word of three letters or more matches the start of a longer word; a shorter one does not', () {
      final index = CatalogSearchIndex([_entry('embeddings in a vector store')], lang: 'en');

      expect(index.search('embed').hits, hasLength(1));
      expect(index.search('em').hits, isEmpty);
    });

    test('a word one letter off still matches when it is long enough', () {
      final index = CatalogSearchIndex([_entry('quantization')], lang: 'en');

      expect(index.search('quantizaton').hits, hasLength(1));
      expect(index.search('cat').hits, isEmpty);
    });

    test('a module title weighs more than a heading, and a heading more than prose', () {
      final index = CatalogSearchIndex([
        _entry('about prompts', section: 'Other', key: 'prose'),
        _entry('nothing here', section: 'Prompts', key: 'heading'),
        _entry('', kind: SearchKind.module, module: 'Prompts', key: 'title'),
      ], lang: 'en');

      expect(index.search('prompts').hits.map((h) => h.entry.moduleKey), ['title', 'heading', 'prose']);
    });

    test('a planned module and a References section come after the explanation', () {
      final index = CatalogSearchIndex([
        _entry('evaluation', section: 'References', key: 'refs'),
        _entry('evaluation', kind: SearchKind.module, module: 'X', key: 'planned', ready: false),
        _entry('evaluation', key: 'written'),
      ], lang: 'en');

      expect(index.search('evaluation').hits.map((h) => h.entry.moduleKey), ['written', 'planned', 'refs']);
    });

    test('Turkish finds a word typed without its letters', () {
      final index = CatalogSearchIndex([_entry('Ajanın görevi araç çağırmak.')], lang: 'tr');

      expect(index.search('gorev').hits, hasLength(1));
      expect(index.search('cagirmak').hits, hasLength(1));
    });

    test('the excerpt is the words around the first match, with the matched words marked', () {
      final long = '${List.filled(40, 'filler').join(' ')} the retrieval step ${List.filled(40, 'tail').join(' ')}';
      final hit = CatalogSearchIndex([_entry(long)], lang: 'en').search('retrieval').hits.single;

      expect(hit.excerpt, startsWith('…'));
      expect(hit.excerpt, endsWith('…'));
      expect(hit.excerpt.length, lessThan(long.length));
      expect(hit.marks, hasLength(1));
      final (start, end) = hit.marks.single;
      expect(hit.excerpt.substring(start, end), 'retrieval');
    });

    test('a short text is shown whole, its matches marked', () {
      final hit = CatalogSearchIndex([_entry('Tools, and more tools.')], lang: 'en').search('tools').hits.single;

      expect(hit.excerpt, 'Tools, and more tools.');
      expect([for (final (s, e) in hit.marks) hit.excerpt.substring(s, e)], ['Tools', 'tools']);
    });

    test('at most limit hits are kept, and the total counts them all', () {
      final index = CatalogSearchIndex([
        for (var i = 0; i < CatalogSearchIndex.limit + 5; i++) _entry('agents $i'),
      ], lang: 'en');

      final results = index.search('agents');
      expect(results.hits, hasLength(CatalogSearchIndex.limit));
      expect(results.total, CatalogSearchIndex.limit + 5);
    });

    test('an empty or one-letter query finds nothing', () {
      final index = CatalogSearchIndex([_entry('a b c')], lang: 'en');

      expect(index.search('  ').hits, isEmpty);
      expect(index.search('a').hits, isEmpty);
    });
  });
}
