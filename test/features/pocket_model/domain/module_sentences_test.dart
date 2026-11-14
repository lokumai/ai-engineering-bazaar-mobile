import 'package:ai_engineering_bazaar/features/pocket_model/domain/module_sentences.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

List<Inline> _text(String text) => [TextInline(text: text)];

void main() {
  group('a module as it reads it', () {
    test('its prose, sentence by sentence, in lower case, without the marks between the words', () {
      final doc = testDoc(
        body: [
          ParagraphBlock(inlines: _text('A model reads tokens. Then it guesses the next one!'), lead: false),
          HeadingBlock(depth: 2, id: 'why', mark: null, inlines: _text('Why attention matters')),
        ],
      );
      expect(sentencesOf(doc), [
        ['a', 'model', 'reads', 'tokens'],
        ['then', 'it', 'guesses', 'the', 'next', 'one'],
        ['why', 'attention', 'matters'],
      ]);
    });

    test('lists, quotes and callouts are prose; code, tables and inline code are not', () {
      final doc = testDoc(
        body: [
          ListBlock(
            ordered: false,
            start: null,
            items: [
              ListItem(checked: null, blocks: [ParagraphBlock(inlines: _text('Each item is read too'), lead: false)]),
            ],
          ),
          QuoteBlock(label: null, blocks: [ParagraphBlock(inlines: _text('A quote is read as well'), lead: false)]),
          CalloutBlock(
            kind: CalloutKind.note,
            title: _text('A callout title here'),
            blocks: [ParagraphBlock(inlines: _text('And its words are read'), lead: false)],
            action: null,
          ),
          const CodeBlock(
            language: 'python',
            lines: [
              [CodeToken(text: 'print("not read at all")', role: null, bold: false)],
            ],
          ),
          ParagraphBlock(
            inlines: [
              ..._text('Call '),
              const CodeInline(text: 'agent.run()'),
              ..._text(' to start it now'),
            ],
            lead: false,
          ),
        ],
      );
      final words = sentencesOf(doc).expand((sentence) => sentence).toList();
      expect(words, containsAll(['item', 'quote', 'callout', 'title', 'its']));
      expect(words, isNot(contains('print')));
      expect(words, isNot(contains('agent.run')));
      expect(sentencesOf(doc).last, ['call', 'to', 'start', 'it', 'now']);
    });

    test('a sentence of fewer than three words is left out, and a long one is cut', () {
      final long = List.generate(30, (i) => 'w$i').join(' ');
      final doc = testDoc(body: [ParagraphBlock(inlines: _text('Too short. $long'), lead: false)]);
      final sentences = sentencesOf(doc);
      expect(sentences.map((sentence) => sentence.length), [24, 6]);
    });

    test("after the prose, each quiz question and its right answer, never a wrong one nor a question's code", () {
      final doc = testDoc(
        body: [ParagraphBlock(inlines: _text('The prose comes first here.'), lead: false)],
        quiz: const [
          QuizItem(
            question: 'What does attention weigh in `layer.forward`?',
            options: ['The colour of the screen', 'The other tokens of the sentence'],
            answer: 1,
            explain: 'It weighs every token against the others.',
          ),
        ],
      );
      expect(sentencesOf(doc), [
        ['the', 'prose', 'comes', 'first', 'here'],
        ['what', 'does', 'attention', 'weigh', 'in'],
        ['the', 'other', 'tokens', 'of', 'the', 'sentence'],
      ]);
    });

    test('a planned module has no prose', () {
      expect(sentencesOf(testDoc()), isEmpty);
    });
  });

  group('the words', () {
    test('Turkish keeps its dotted and dotless i apart', () {
      expect(wordsOf('Işık İçinde', 'tr'), ['ışık', 'içinde']);
      expect(wordsOf('Işık', 'en'), isNot(['ışık']));
    });

    test('a word keeps its own apostrophe, hyphen and joiner, and loses them at its ends', () {
      expect(wordsOf("the model's 'self-attention' layer", 'en'), ['the', "model's", 'self-attention', 'layer']);
      expect(wordsOf('\u0645\u06cc\u200c\u062e\u0648\u0627\u0646\u062f\u060c \u0645\u062f\u0644', 'fa'), [
        '\u0645\u06cc\u200c\u062e\u0648\u0627\u0646\u062f',
        '\u0645\u062f\u0644',
      ]);
    });
  });
}
