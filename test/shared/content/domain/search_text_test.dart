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

  test('matchesTerms matches a word as written', () {
    expect(matchesTerms('Görevi', ['gorev'], 'tr'), isTrue);
    expect(matchesTerms('Tool', ['agent'], 'en'), isFalse);
  });
}
