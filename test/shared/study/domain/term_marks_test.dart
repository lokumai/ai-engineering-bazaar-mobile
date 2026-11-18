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

  group('termUsage (the owner, 2026-11-18: a term card shows the sentence that uses it)', () {
    ModuleNotes notes(List<String> texts) => ModuleNotes(
      moduleKey: 'alpha/first',
      sections: [for (final (i, text) in texts.indexed) NoteSection(id: 's$i', title: 'S$i', text: text)],
    );

    test('the first sentence that uses the term as a whole word, in any case, with where it stands', () {
      final usage = termUsage(
        notes(['A lamp needs oil. Wicked weather came. The WICK draws the oil up! It burns.', 'A wick again.']),
        wick,
      );
      expect(usage, const TermUsage(text: 'The WICK draws the oil up!', start: 4, end: 8));
    });

    test('a later section when the first does not use it; null when none does', () {
      expect(termUsage(notes(['Nothing here.', 'Trim the wick.']), wick)?.text, 'Trim the wick.');
      expect(termUsage(notes(['Nothing here.']), wick), isNull);
    });

    test('a longer form before a shorter one, and a Persian question mark ends a sentence', () {
      final usage = termUsage(
        notes(['چرا؟ The context window fills.']),
        _term('Window', forms: ['context window', 'window']),
      );
      expect(usage, const TermUsage(text: 'The context window fills.', start: 4, end: 18));
    });

    test('a long sentence is cut to whole words around the term, with an ellipsis where it was cut', () {
      final words = List.generate(60, (i) => 'word$i');
      final sentence = [...words.take(30), 'wick', ...words.skip(30)].join(' ');
      final usage = termUsage(notes(['$sentence.']), wick)!;
      expect(usage.text.length, lessThanOrEqualTo(usageLength + 4));
      expect(usage.text, startsWith('… word'));
      expect(usage.text, endsWith(' …'));
      expect(usage.text.substring(usage.start, usage.end), 'wick');
      expect(usage.text.split(' ').skip(1).take(1).single, matches(RegExp(r'^word\d+$')), reason: 'a whole word');
    });
  });
}
