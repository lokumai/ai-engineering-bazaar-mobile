import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_corpus.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the text it reads', () {
    for (final language in ['en', 'tr', 'fa']) {
      test('in $language there is more than the top level reads, and nothing held out is read', () {
        final training = PocketCorpus.training(language);
        final heldOut = PocketCorpus.heldOut(language);
        expect(TinyLm(language).epoch, greaterThan(PocketModel.levels.last));
        expect(heldOut.where(training.contains), isEmpty);
        for (final sentence in [...training, ...heldOut]) {
          expect(sentence, isNot(contains('  ')), reason: sentence);
          expect(sentence.trim(), sentence, reason: sentence);
          expect(sentence, isNot(contains(RegExp(r'[.,!?;:]'))), reason: 'words only: $sentence');
        }
      });
    }

    test('another language reads the English text', () {
      expect(PocketCorpus.training('de'), PocketCorpus.training('en'));
    });
  });

  group('the model', () {
    test('reads its text in order, a sentence end being a token too', () {
      final model = TinyLm('en');
      final first = PocketCorpus.training('en').first.split(' ');
      expect(model.train(first.length + 1), first, reason: 'the end of the sentence is read, not shown');
      expect(model.trained, first.length + 1);
      expect(model.known, first.toSet().length);
    });

    test('reads from the top again after the last token', () {
      final model = TinyLm('en')..trainTo(TinyLm('en').epoch);
      final first = PocketCorpus.training('en').first.split(' ');
      expect(model.train(first.length), first);
    });

    test('a model rebuilt from a count is the one that read it a feed at a time', () {
      final fed = TinyLm('en');
      for (var i = 0; i < 40; i++) {
        fed.train(PocketModel.feedTokens);
      }
      final rebuilt = TinyLm.trained('en', 40 * PocketModel.feedTokens);
      expect(rebuilt.known, fed.known);
      expect(rebuilt.loss(), fed.loss());
      expect(
        rebuilt.write(temperature: 0.8, random: math.Random(4)).tokens,
        fed.write(temperature: 0.8, random: math.Random(4)).tokens,
      );
    });

    test('its chances add up to one, for any context', () {
      final model = TinyLm.trained('en', 600);
      final vocabulary = {
        for (final s in [...PocketCorpus.training('en'), ...PocketCorpus.heldOut('en')]) ...s.split(' '),
        TinyLm.end,
      };
      for (final (a, b) in [('<s>', '<s>'), ('the', 'model'), ('a', 'camel'), ('nothing', 'read')]) {
        final sum = vocabulary.fold(0.0, (sum, word) => sum + model.chance(a, b, word, smooth: true));
        expect(sum, closeTo(1, 1e-9), reason: '$a $b');
      }
    });
  });

  group('its loss', () {
    test('starts where every word is as likely as any other, and falls as it reads', () {
      final vocabulary = {
        for (final s in [...PocketCorpus.training('en'), ...PocketCorpus.heldOut('en')]) ...s.split(' '),
        TinyLm.end,
      }.length;
      expect(TinyLm('en').loss(), closeTo(math.log(vocabulary), 1e-9));
      // A new subject in the text can lift it a little for a while; over two levels it always falls.
      final losses = [for (final level in PocketModel.levels) TinyLm.trained('en', level).loss()];
      for (var i = 2; i < losses.length; i++) {
        expect(losses[i], lessThan(losses[i - 2]), reason: 'level $i');
      }
      expect(losses.last, lessThan(losses[1] - 1));
    });

    test('rises again when it reads the same text over and over: it overfits', () {
      final model = TinyLm('en');
      final once = (model..trainTo(model.epoch)).loss();
      final thrice = (model..trainTo(model.epoch * 3)).loss();
      expect(thrice, greaterThan(once));
    });

    test('the curve runs from none read to now', () {
      expect(TinyLm.curve('en', 0), hasLength(1));
      final curve = TinyLm.curve('en', 800, points: 9);
      expect(curve, hasLength(9));
      expect(curve.first.tokens, 0);
      expect(curve.last.tokens, 800);
      expect(curve.last.loss, TinyLm.trained('en', 800).loss());
      expect(curve.first.loss, greaterThan(curve.last.loss));
    });
  });

  group('what it writes', () {
    test('before it reads anything, noise', () {
      final said = TinyLm('en').write(temperature: 0.8, random: math.Random(1));
      for (final token in said.tokens) {
        expect(token, matches(RegExp(r'^[a-z]{2,5}$')));
      }
    });

    test('only words it has read', () {
      final model = TinyLm.trained('en', 300);
      final read = TinyLm('en').train(300).toSet();
      for (var seed = 0; seed < 30; seed++) {
        final said = model.write(temperature: 1.6, random: math.Random(seed));
        expect(read.containsAll(said.tokens), isTrue);
        expect(said.tokens.length, inInclusiveRange(1, TinyLm.longest));
      }
    });

    test('cold, its likeliest sentence, every time, and one it read', () {
      final model = TinyLm.trained('en', 1600);
      final said = model.write(temperature: 0.1, random: math.Random(1)).tokens;
      expect(model.write(temperature: 0.1, random: math.Random(99)).tokens, said);
      expect(said, isNotEmpty);
    });

    test('hot, it joins words it never read together, and says so', () {
      final model = TinyLm.trained('en', 1600);
      final hot = [for (var seed = 0; seed < 20; seed++) model.write(temperature: 1.9, random: math.Random(seed))];
      final warm = [for (var seed = 0; seed < 20; seed++) model.write(temperature: 0.7, random: math.Random(seed))];
      expect(
        hot.where((said) => said.hallucinating).length,
        greaterThan(warm.where((said) => said.hallucinating).length),
      );
      expect(hot.where((said) => said.hallucinating).length, greaterThan(14));
    });

    test('it speaks the language of its text', () {
      final tr = TinyLm.trained('tr', 400).write(temperature: 0.1, random: math.Random(1));
      expect(PocketCorpus.training('tr').join(' ').split(' ').toSet().containsAll(tr.tokens), isTrue);
      final fa = TinyLm.trained('fa', 400).write(temperature: 0.8, random: math.Random(1));
      expect(fa.tokens.join(' '), matches(RegExp('[\u0600-\u06ff]')));
    });

    test('the word it read most is the one an overfit model repeats', () {
      final model = TinyLm.trained('en', 400);
      final counts = <String, int>{};
      for (final word in TinyLm('en').train(400)) {
        counts[word] = (counts[word] ?? 0) + 1;
      }
      final most = counts.values.reduce(math.max);
      expect(counts[model.favourite], most);
      expect(TinyLm('en').favourite, isNull);
    });
  });
}
