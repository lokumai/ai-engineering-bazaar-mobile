import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final noon = DateTime.utc(2026, 11, 14, 12);

  group('the model', () {
    test('a fresh one is level 0, newborn, with no curve', () {
      expect(PocketModel.fresh.level, 0);
      expect(PocketModel.fresh.moodAt(noon), PocketMood.newborn);
      expect(PocketModel.fresh.curve(), isEmpty);
      expect(PocketModel.fresh.toNext, 24);
    });

    test('a feed gives tokens and is remembered', () {
      final fed = PocketModel.fresh.fedAt(noon);
      expect(fed.tokens, PocketModel.feedTokens);
      expect(fed.lastFed, noon);
      expect(fed.moodAt(noon), PocketMood.content);
    });

    test('the level follows the tokens, and progress runs to the next', () {
      expect(const PocketModel(tokens: 23).level, 0);
      expect(const PocketModel(tokens: 24).level, 1);
      expect(const PocketModel(tokens: 52).progress, closeTo(0.5, 1e-9));
      expect(const PocketModel(tokens: 5000).level, PocketModel.levels.length - 1);
      expect(const PocketModel(tokens: 5000).toNext, isNull);
      expect(const PocketModel(tokens: 5000).progress, 1);
    });

    test('the loss falls as it trains, and the curve ends at the loss now', () {
      expect(PocketModel.lossAt(0), greaterThan(PocketModel.lossAt(200)));
      expect(PocketModel.lossAt(200), greaterThan(PocketModel.lossAt(2000)));
      expect(PocketModel.lossAt(100000), greaterThanOrEqualTo(0.08));
      const model = PocketModel(tokens: 400);
      final curve = model.curve(points: 10);
      expect(curve, hasLength(10));
      expect(curve.last, model.loss);
      expect(curve.first, greaterThan(curve.last));
    });

    test('it grows hungry, then falls asleep', () {
      final fed = PocketModel(tokens: 40, lastFed: noon);
      expect(fed.moodAt(noon.add(const Duration(hours: 2))), PocketMood.content);
      expect(fed.moodAt(noon.add(const Duration(hours: 4))), PocketMood.hungry);
      expect(fed.moodAt(noon.add(const Duration(hours: 11))), PocketMood.asleep);
    });

    test('fed too fast it overfits, takes no tokens, and recovers after a rest', () {
      var model = PocketModel.fresh;
      for (var i = 0; i < PocketModel.overfitFeeds; i++) {
        model = model.fedAt(noon.add(Duration(seconds: i)));
      }
      final at = noon.add(const Duration(seconds: 7));
      expect(model.overfitAt(at), isTrue);
      final tokens = model.tokens;
      expect(model.fedAt(at).tokens, tokens, reason: 'an overfit model learns nothing');
      expect(model.overfitAt(at.add(PocketModel.overfitRest)), isFalse);
      expect(model.rested().overfitAt(at), isFalse);
    });

    test('feeds spaced apart never overfit', () {
      var model = PocketModel.fresh;
      for (var i = 0; i < 20; i++) {
        model = model.fedAt(noon.add(Duration(seconds: i * 3)));
      }
      expect(model.overfitAt(noon.add(const Duration(seconds: 60))), isFalse);
      expect(model.tokens, 20 * PocketModel.feedTokens);
    });
  });

  group('the babble', () {
    Babble say(int level, {double temperature = 0.8, bool overfit = false, String language = 'en', int seed = 1}) =>
        babble(language: language, level: level, temperature: temperature, overfit: overfit, random: math.Random(seed));

    test('at level 0 it strings letters', () {
      final said = say(0);
      expect(said.tokens.length, inInclusiveRange(2, 3));
      for (final token in said.tokens) {
        expect(token, matches(RegExp(r'^[a-z]{2,5}$')));
      }
    });

    test('at level 1 it says words, not phrases', () {
      expect(say(1).tokens.length, inInclusiveRange(2, 4));
    });

    test('cold, it says its likeliest phrase every time', () {
      expect(say(5, temperature: 0.1, seed: 1).tokens, say(5, temperature: 0.1, seed: 9).tokens);
      expect(say(5, temperature: 0.1).tokens.join(' '), 'more tokens more wisdom');
    });

    test('hot, it hallucinates', () {
      expect(say(5, temperature: 1.8).hallucinating, isTrue);
      expect(say(5).hallucinating, isFalse);
    });

    test('overfit, it repeats one word', () {
      final said = say(5, overfit: true);
      expect(said.tokens.toSet(), {'tokens'});
      expect(said.tokens.length, greaterThanOrEqualTo(4));
    });

    test('it speaks the language it is asked in, English for any other', () {
      expect(say(5, temperature: 0.1, language: 'tr').tokens.first, 'daha');
      expect(say(0, language: 'fa').tokens.first, isNot(matches(RegExp('[a-z]'))));
      expect(say(5, temperature: 0.1, language: 'de').tokens.first, 'more');
    });

    test('a high level keeps a phrase whole at a calm temperature', () {
      final said = say(7, temperature: 0.8).tokens.join(' ');
      expect(said.split(' ').length, greaterThan(3));
    });
  });
}
