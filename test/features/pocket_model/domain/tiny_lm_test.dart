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
        expect(TinyLm(language).epoch, greaterThan(PocketModel.levels[PocketModel.feedLevels]));
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
      final losses = [
        for (final level in PocketModel.levels.take(PocketModel.feedLevels + 1)) TinyLm.trained('en', level).loss(),
      ];
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

  group('a module it reads', () {
    final module = [
      ['a', 'transformer', 'stacks', 'attention', 'layers'],
      ['each', 'layer', 'refines', 'the', 'tokens'],
    ];

    test('is read whole: its tokens, each sentence end too, and its new words', () {
      final model = TinyLm.trained('en', 200);
      final known = model.known;
      expect(model.read(module), 12);
      expect(model.readTokens, 12);
      expect(model.total, 212);
      expect(model.trained, 200, reason: 'its own text stays where it was');
      expect(model.known, greaterThan(known));
    });

    test('its chances still add up to one with the module\'s words', () {
      final model = TinyLm.trained('en', 200)..read(module);
      final vocabulary = {
        for (final s in [...PocketCorpus.training('en'), ...PocketCorpus.heldOut('en')]) ...s.split(' '),
        for (final sentence in module) ...sentence,
        TinyLm.end,
      };
      for (final (a, b) in [('<s>', '<s>'), ('each', 'layer'), ('the', 'model')]) {
        final sum = vocabulary.fold(0.0, (sum, word) => sum + model.chance(a, b, word, smooth: true));
        expect(sum, closeTo(1, 1e-9), reason: '$a $b');
      }
    });

    test('it can write what the module taught it', () {
      final model = TinyLm('en')..read(module);
      expect(model.write(temperature: 0.1, random: math.Random(1)).tokens.first, anyOf('a', 'each'));
    });

    test('the curve reads it at its place, a point before and one after', () {
      final curve = TinyLm.curve('en', 400, points: 5, readings: [(100, module)]);
      final tokens = curve.map((point) => point.tokens).toList();
      expect(tokens, [0, 100, 112, 212, 312, 412]);
      expect(tokens, orderedEquals([...tokens]..sort()));
      expect(curve.last.loss, (TinyLm.trained('en', 400)..read(module)).loss());
    });

    test('a module read before any feed is drawn too', () {
      final curve = TinyLm.curve('en', 0, readings: [(0, module)]);
      expect(curve.map((point) => point.tokens), [0, 12]);
    });
  });

  group('its repetition penalty', () {
    test('warm, it does not say the same sentence twice running, nor lean on a recent answer\'s words', () {
      final model = TinyLm.trained('en', 1600);
      final random = math.Random(5);
      final recent = <List<String>>[];
      for (var i = 0; i < 12; i++) {
        final said = model.write(temperature: 0.6, random: random, recent: recent).tokens;
        expect(recent.any((before) => before.join(' ') == said.join(' ')), isFalse, reason: said.join(' '));
        recent.add(said);
        if (recent.length > 3) recent.removeAt(0);
      }
    });

    test('cold, it says its likeliest sentence regardless', () {
      final model = TinyLm.trained('en', 1600);
      final said = model.write(temperature: 0.1, random: math.Random(1)).tokens;
      expect(model.write(temperature: 0.1, random: math.Random(1), recent: [said]).tokens, said);
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

  group('the more modules it read, the more it thinks, and on topic', () {
    List<List<String>> module(String text) => [for (final line in text.split('. ')) line.split(' ')];
    final stars = module(
      'stars burn hydrogen deep inside their cores. a telescope gathers starlight from distant galaxies. '
      'astronomers measure stars by their brightness and colour. a galaxy holds billions of stars and planets. '
      'planets orbit stars along elliptical paths. light from distant galaxies travels for millions of years',
    );
    final bread = module(
      'bakers knead dough until gluten forms. yeast ferments sugar and releases carbon dioxide. '
      'the dough rises slowly overnight in a warm kitchen. bakers shape loaves before baking them hot. '
      'a crust forms when the oven browns the dough. flour water salt and yeast make bread',
    );

    test('it thinks over one sentence before any module, three more for each, at most twenty', () {
      expect(
        [
          for (final n in [0, 1, 2, 6, 7, 40]) TinyLm.thoughtsFor(n),
        ],
        [1, 4, 7, 19, 20, 20],
      );
    });

    test('a module it reads with its key is a topic; read without one, none', () {
      final model = TinyLm.trained('en', 400)
        ..read(stars, topic: 'sky/stars')
        ..read(bread);
      expect(model.topics, ['sky/stars']);
    });

    test('asked to keep to a topic, it speaks of that module, not of another it read', () {
      final model = TinyLm.trained('en', 400)
        ..read(stars, topic: 'sky/stars')
        ..read(bread, topic: 'kitchen/bread');
      final starWords = {for (final s in stars) ...s};
      final breadWords = {for (final s in bread) ...s}.difference(starWords);
      var onStars = 0;
      var onBread = 0;
      for (var seed = 0; seed < 30; seed++) {
        final said = model
            .write(temperature: 0.8, random: math.Random(seed), topic: 'sky/stars', thoughts: TinyLm.thoughtsFor(2))
            .tokens;
        onStars += said.where((w) => starWords.contains(w) && w.length > 3).length;
        onBread += said.where((w) => breadWords.contains(w) && w.length > 3).length;
      }
      expect(onStars, greaterThan(onBread * 4));
    });

    test('it judges a sentence it read smoother than the same words shuffled', () {
      final model = TinyLm.trained('en', 400)..read(bread, topic: 'kitchen/bread');
      final read = 'the dough rises slowly overnight in a warm kitchen'.split(' ');
      final shuffled = 'kitchen warm a in overnight slowly rises dough the'.split(' ');
      expect(model.judge(read, topic: 'kitchen/bread'), greaterThan(model.judge(shuffled, topic: 'kitchen/bread')));
    });

    test('with more thoughts, what it says reads smoother to it than what it says at once', () {
      final model = TinyLm.trained('en', 1600)
        ..read(stars, topic: 'sky/stars')
        ..read(bread, topic: 'kitchen/bread');
      double mean(int thoughts) {
        var sum = 0.0;
        for (var seed = 0; seed < 30; seed++) {
          final said = model.write(temperature: 1.0, random: math.Random(seed), topic: 'sky/stars', thoughts: thoughts);
          sum += model.judge(said.tokens, topic: 'sky/stars');
        }
        return sum / 30;
      }

      expect(mean(10), greaterThan(mean(1)));
    });

    test('the more modules it read, the more of a word\'s chance its topic decides, at most four fifths', () {
      expect(
        [
          for (final n in [0, 1, 2, 4, 7, 20]) TinyLm.topicShare(n),
        ],
        [0.5, 0.5, 0.55, 0.65, 0.8, 0.8],
      );
    });

    // One module of two sections far apart: the stars, then the bread.
    final both = [...stars, ...bread];

    test('most sentences on a topic start as one of its sentences starts', () {
      final model = TinyLm.trained('en', 400)..read(both, topic: 'mixed/both', sections: [0, stars.length]);
      final (taught, _) = TinyLm.splitOut(both);
      final openings = {for (final s in taught) '${s[0]} ${s[1]}'};
      var opened = 0;
      for (var seed = 0; seed < 40; seed++) {
        final said = model.write(temperature: 1.2, random: math.Random(seed), topic: 'mixed/both').tokens;
        if (said.length >= 2 && openings.contains('${said[0]} ${said[1]}')) opened++;
      }
      expect(opened, greaterThan(24));
    });

    test('a sentence cut before its end is judged lower than the same words ended', () {
      final model = TinyLm.trained('en', 400)..read(bread, topic: 'kitchen/bread');
      final words = 'the dough rises slowly overnight in a warm kitchen'.split(' ');
      expect(
        model.judge(words, topic: 'kitchen/bread', finished: false),
        lessThan(model.judge(words, topic: 'kitchen/bread') - 0.9),
      );
    });

    test('it says up to eighteen words, so most of what it says ends of itself', () {
      expect(TinyLm.longest, 18);
      final model = TinyLm.trained('en', 1600)
        ..read(stars, topic: 'sky/stars')
        ..read(bread, topic: 'kitchen/bread');
      var cut = 0;
      for (var seed = 0; seed < 30; seed++) {
        final said = model.write(temperature: 1.0, random: math.Random(seed), topic: 'sky/stars', thoughts: 7);
        if (said.tokens.length == TinyLm.longest) cut++;
      }
      expect(cut, lessThan(3));
    });
  });
}
