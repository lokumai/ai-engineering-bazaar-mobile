import 'package:ai_engineering_bazaar/features/reader/domain/spoken_parts.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter_test/flutter_test.dart';

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

HeadingBlock _h(String id, String text, {int depth = 2}) => HeadingBlock(
  depth: depth,
  id: id,
  mark: null,
  inlines: [TextInline(text: text)],
);

ListItem _item(String text) => ListItem(checked: null, blocks: [_p(text)]);

void main() {
  group('spokenParts (plan 15.1)', () {
    test('reads headings, paragraphs, lists, quotes and callouts, each block by its place', () {
      final parts = spokenParts([
        _h('why', 'Why tools'),
        const ParagraphBlock(
          inlines: [
            TextInline(text: 'Models '),
            StrongInline(inlines: [TextInline(text: 'call')]),
            TextInline(text: ' tools.'),
          ],
          lead: false,
        ),
        ListBlock(ordered: false, start: null, items: [_item('Name the tool'), _item('Read the answer.')]),
        QuoteBlock(label: null, blocks: [_p('A quote.')]),
        CalloutBlock(
          kind: CalloutKind.tip,
          title: const [TextInline(text: 'Tip')],
          blocks: [_p('Keep it short.')],
          action: null,
        ),
      ]);
      expect(parts, const [
        SpokenPart(block: 0, text: 'Why tools.'),
        SpokenPart(block: 1, text: 'Models call tools.'),
        SpokenPart(block: 2, text: 'Name the tool. Read the answer.'),
        SpokenPart(block: 3, text: 'A quote.'),
        SpokenPart(block: 4, text: 'Tip. Keep it short.'),
      ]);
    });

    test('passes over code, tables, pictures, diagrams, rules and empty blocks', () {
      final parts = spokenParts([
        const CodeBlock(
          language: 'py',
          lines: [
            [CodeToken(text: 'print(1)', role: null, bold: false)],
          ],
        ),
        const TableBlock(
          number: '1',
          title: null,
          rowHeaders: false,
          align: [null],
          head: [
            Cell(inlines: [TextInline(text: 'Head')]),
          ],
          rows: [],
        ),
        const DiagramBlock(number: '2', title: 'Flow', svgLight: '', svgDark: ''),
        const RuleBlock(),
        const UnknownBlock(type: 'widget'),
        _p('  '),
        _p('Said.'),
      ]);
      expect(parts, const [SpokenPart(block: 6, text: 'Said.')]);
    });

    test('stops at the References, in every language', () {
      for (final id in ['references', 'kaynaklar', 'منابع']) {
        final parts = spokenParts([_p('Read.'), _h(id, 'Refs'), _p('A link list.')]);
        expect(parts, const [SpokenPart(block: 0, text: 'Read.')], reason: id);
      }
      expect(spokenParts([_p('Read.'), _h('summary', 'Summary'), _p('Recap.')]), hasLength(3));
    });

    test('a heading that ends in its own mark gets no second one', () {
      expect(spokenParts([_h('q', 'Why?'), _h('c', 'Steps:', depth: 3)]).map((part) => part.text), ['Why?', 'Steps:']);
    });
  });
}
