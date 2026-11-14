import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final noon = DateTime.utc(2026, 11, 14, 12);

  group('the model', () {
    test('a fresh one is level 0, newborn, with no curve', () {
      expect(PocketModel.fresh.level, 0);
      expect(PocketModel.fresh.moodAt(noon), PocketMood.newborn);
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
      expect(const PocketModel(tokens: 50000).level, PocketModel.levels.length - 1);
      expect(const PocketModel(tokens: 50000).toNext, isNull);
      expect(const PocketModel(tokens: 50000).progress, 1);
    });

    test('a module it read counts toward its level, and is remembered as read', () {
      final model = PocketModel(
        tokens: 100,
        lastFed: noon,
      ).readAt('alpha/first', 2000, noon.add(const Duration(hours: 5)));
      expect(model.tokens, 100, reason: 'its own text stays where it was');
      expect(model.total, 2100);
      expect(model.level, 7);
      expect(model.hasRead('alpha/first'), isTrue);
      expect(model.hasRead('alpha/second'), isFalse);
      expect(model.readings.single, const PocketReading(key: 'alpha/first', at: 100, tokens: 2000));
      expect(model.moodAt(noon.add(const Duration(hours: 5))), PocketMood.content, reason: 'a module feeds it');
      expect(model.fedAt(noon.add(const Duration(hours: 6))).readings, model.readings);
      expect(model.rested().readings, model.readings);
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
}
