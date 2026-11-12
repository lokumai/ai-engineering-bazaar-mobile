@Tags(['unit'])
library;

import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('searchTerms normalises the words typed and drops the one-letter ones', () {
    expect(searchTerms('Görev a  RAG', 'tr'), ['gorev', 'rag']);
  });

  group('termQuality', () {
    test('the word itself answers best', () => expect(termQuality('agent', 'agent'), 1));

    test('a word of three letters or more answers the start of a longer word', () {
      expect(termQuality('emb', 'embedding'), greaterThan(0));
      expect(termQuality('em', 'embedding'), 0);
    });

    test('a long enough word may be one letter off', () {
      expect(termQuality('quantizaton', 'quantization'), greaterThan(0));
      expect(termQuality('cat', 'car'), 0);
    });
  });

  test('markRanges marks a whole word, else the parts the search finds alone', () {
    expect(markRanges('Agents call tools.', ['tool'], 'en'), [(12, 17)]);
    // A suffix joined by a non-joiner, and a Latin word run into a Persian one.
    expect(markRanges('ماژول\u200cها', ['ها'], 'fa'), [(6, 8)]);
    expect(markRanges('AIاست', ['ai'], 'fa'), [(0, 2)]);
    // A word that answers whole is marked whole: the stem starts it.
    expect(markRanges('ماژول\u200cها', ['ماژول'], 'fa'), [(0, 8)]);
  });

  test('joinedVariant joins a Persian prefix or suffix typed apart, and leaves other queries alone', () {
    expect(joinedVariant('می خواهم', 'fa'), 'میخواهم');
    expect(joinedVariant('مدل ها', 'fa'), 'مدلها');
    expect(joinedVariant('مدل', 'fa'), isNull);
    expect(joinedVariant('می خواهم', 'en'), isNull);
  });

  test('matchesTerms matches a word as written', () {
    expect(matchesTerms('Görevi', ['gorev'], 'tr'), isTrue);
    expect(matchesTerms('Tool', ['agent'], 'en'), isFalse);
  });
}
