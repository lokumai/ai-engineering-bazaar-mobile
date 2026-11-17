import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/term_marks.dart';
import 'package:flutter_test/flutter_test.dart';

GlossaryTerm _term(String name, {List<String>? forms, int index = 0, String module = 'alpha/first'}) =>
    GlossaryTerm(moduleKey: module, index: index, name: name, forms: forms ?? [name], definition: const []);

HeadingBlock _h(String id, {int depth = 2}) => HeadingBlock(
  depth: depth,
  id: id,
  mark: null,
  inlines: [TextInline(text: id)],
);

void main() {
  final wick = _term('Wick');
  final window = _term('Context window', index: 1);
  final context = _term('Context', index: 2);

  test('marks a term the first time in each section only, as a whole word, in any case', () {
    final first = TextInline(text: 'The wick burns. A wick again. Wicked is not it.');
    final second = TextInline(text: 'Still the WICK here.');
    final third = TextInline(text: 'The Wick of a new section.');
    final marks = termMarks(
      [
        _h('one'),
        ParagraphBlock(inlines: [first], lead: false),
        ParagraphBlock(inlines: [second], lead: false),
        _h('two'),
        ParagraphBlock(inlines: [third], lead: false),
      ],
      [wick],
    );
    expect(marks[first], [TermMark(start: 4, end: 8, term: wick)]);
    expect(marks[second], isNull, reason: 'once a section');
    expect(marks[third], [TermMark(start: 4, end: 8, term: wick)]);
  });

  test('a longer form wins over a shorter one it holds', () {
    final text = TextInline(text: 'The context window is full; the context grows.');
    final marks = termMarks(
      [
        ParagraphBlock(inlines: [text], lead: false),
      ],
      [context, window],
    );
    expect([for (final mark in marks[text]!) (mark.start, mark.term.name)], [(4, 'Context window'), (32, 'Context')]);
  });

  test('never in code, headings, tables, links, bold text, or the sections skipped', () {
    final linked = TextInline(text: 'wick');
    final bold = TextInline(text: 'wick');
    final skipped = TextInline(text: 'wick');
    final quoted = TextInline(text: 'a wick');
    final body = [
      _h('wick'),
      CodeBlock(language: 'text', lines: const []),
      ParagraphBlock(
        inlines: [
          LinkInline(
            target: const AnchorTarget(id: 'x'),
            inlines: [linked],
          ),
          StrongInline(inlines: [bold]),
        ],
        lead: false,
      ),
      QuoteBlock(
        label: null,
        blocks: [
          ParagraphBlock(inlines: [quoted], lead: false),
        ],
      ),
      _h('terms'),
      ParagraphBlock(inlines: [skipped], lead: false),
    ];
    final marks = termMarks(body, [wick], skip: {'terms'});
    expect(marks.keys, [quoted], reason: 'a quote is text; the rest is not');
  });

  test('two texts alike are two places', () {
    final a = TextInline(text: 'wick');
    final b = TextInline(text: 'wick');
    final marks = termMarks(
      [
        _h('one'),
        ParagraphBlock(inlines: [a], lead: false),
        _h('two'),
        ParagraphBlock(inlines: [b], lead: false),
      ],
      [wick],
    );
    expect(marks.length, 2);
  });

  test('a Turkish capital İ keeps the places right', () {
    final term = _term('token');
    final text = TextInline(text: 'İlk token burada.');
    final marks = termMarks(
      [
        ParagraphBlock(inlines: [text], lead: false),
      ],
      [term],
    );
    expect(text.text.substring(marks[text]!.single.start, marks[text]!.single.end), 'token');
  });
}
