import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

HeadingBlock _h(String id, String text, {int depth = 2}) => HeadingBlock(
  depth: depth,
  id: id,
  mark: null,
  inlines: [TextInline(text: text)],
);

ParagraphBlock _p(List<Inline> inlines) => ParagraphBlock(inlines: inlines, lead: false);

ListBlock _list(List<List<Inline>> items) => ListBlock(
  ordered: false,
  start: null,
  items: [
    for (final inlines in items) ListItem(checked: null, taskIndex: null, blocks: [_p(inlines)]),
  ],
);

StrongInline _b(String text) => StrongInline(inlines: [TextInline(text: text)]);

TextInline _t(String text) => TextInline(text: text);

/// A term list of the module's shape: `**Lantern**: a light you carry.` and `**Wick** and **flame**: what burns.`
ListBlock _terms() => _list([
  [_b('Lantern'), _t(': a light you carry.')],
  [_b('Wick'), _t(' and '), _b('flame'), _t(': what burns.')],
  [_b('Glass'), _t(' (the chimney): '), _t('keeps the wind out.')],
]);

void main() {
  test('finds the Key Terms by shape and place, and the Summary after them', () {
    final doc = testDoc(
      body: [
        _h('lamps', 'Lamps'),
        _p([_t('Some text.')]),
        _h('a-list', 'A list of the same shape, mid-module'),
        _list([
          [_b('Not'), _t(': a term.')],
        ]),
        _h('words', 'Any Name At All'),
        _terms(),
        _h('wrap', 'Another Name'),
        _p([_t('The lamp burns oil.')]),
        _p([_t('The wick draws it up.')]),
        _h('sub', 'A part of it', depth: 3),
        _p([_t('Still the summary.')]),
        _h('refs', 'Sources'),
        _p([_t('A book.')]),
      ],
      quiz: const [
        QuizItem(question: 'Q', options: ['a', 'b'], answer: 0, explain: 'E'),
      ],
    );
    final notes = notesOf('alpha/first', doc);
    expect(notes.termsHeading, 'words');
    expect([for (final term in notes.terms) term.name], ['Lantern', 'Wick and flame', 'Glass (the chimney)']);
    expect(
      [for (final term in notes.terms) term.forms],
      [
        ['Lantern'],
        ['Wick', 'flame'],
        ['Glass'],
      ],
    );
    expect(
      [for (final term in notes.terms) term.definitionText],
      ['a light you carry.', 'what burns.', 'keeps the wind out.'],
    );
    expect([for (final term in notes.terms) term.index], [0, 1, 2]);
    expect(notes.summaryHeading, 'wrap');
    expect(notes.summary, hasLength(4), reason: 'its paragraphs and its subsection, up to the next level-2 heading');
    expect(notes.quiz, hasLength(1));
    expect(
      [for (final section in notes.sections) section.id],
      ['lamps', 'a-list'],
      reason: 'the sections that teach: not the Key Terms, the Summary with its subsection, or the References',
    );
    expect(notes.sections.first, const NoteSection(id: 'lamps', title: 'Lamps', text: 'Some text.'));
  });

  test('a list of that shape only mid-module is not the Key Terms', () {
    final doc = testDoc(
      body: [
        _h('kinds', 'Three Kinds'),
        _terms(),
        _h('one', 'One'),
        _p([_t('a')]),
        _h('two', 'Two'),
        _p([_t('b')]),
        _h('three', 'Three'),
        _p([_t('c')]),
      ],
    );
    final notes = notesOf('alpha/first', doc);
    expect(notes.terms, isEmpty);
    expect(notes.summary, isEmpty, reason: 'no Key Terms, no place to find the Summary by');
  });

  test('Key Terms right before the last heading leave no Summary', () {
    final doc = testDoc(
      body: [
        _h('a', 'A'),
        _p([_t('x')]),
        _h('terms', 'Terms'),
        _terms(),
        _h('refs', 'Sources'),
      ],
    );
    final notes = notesOf('alpha/first', doc);
    expect(notes.terms, hasLength(3));
    expect(notes.summary, isEmpty);
  });

  test('a list whose items do not all start with a bold term then a colon is not the Key Terms', () {
    for (final odd in [
      [_t('plain '), _b('bold'), _t(': x')],
      [_b('No colon'), _t(' here')],
      [_b('Empty'), _t(': ')],
    ]) {
      final doc = testDoc(
        body: [
          _h('terms', 'Terms'),
          _list([
            [_b('Fine'), _t(': yes.')],
            odd,
          ]),
          _h('sum', 'Sum'),
          _p([_t('s')]),
          _h('refs', 'Sources'),
        ],
      );
      expect(notesOf('alpha/first', doc).terms, isEmpty, reason: '$odd');
    }
  });

  test('a module without a body has no notes but its quiz', () {
    final notes = notesOf('alpha/first', testDoc());
    expect((notes.terms, notes.summary, notes.quiz), (const <GlossaryTerm>[], const <Block>[], const <QuizItem>[]));
  });
}
