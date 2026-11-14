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

    test('the level follows the tokens fed, and progress runs to the next, until feeds take it no higher', () {
      expect(const PocketModel(tokens: 23).level, 0);
      expect(const PocketModel(tokens: 24).level, 1);
      expect(const PocketModel(tokens: 52).progress, closeTo(0.5, 1e-9));
      expect(const PocketModel(tokens: 50000).level, PocketModel.feedLevels);
      expect(const PocketModel(tokens: 50000).toNext, isNull);
      expect(const PocketModel(tokens: 50000).progress, 1);
    });

    test('each module read is one level, however long it is (the owner, 2026-11-14)', () {
      var model = PocketModel(tokens: 100, lastFed: noon);
      expect(model.level, 2);
      model = model.readAt('alpha/first', 3000, noon);
      expect(model.level, 3, reason: 'a module of three thousand tokens, not seven levels');
      model = model.readAt('alpha/second', 200, noon);
      expect(model.level, 4);
      expect(model.toNext, 80, reason: 'feeds still take it on to their own next level');
      expect(PocketModel(tokens: 5000, readings: model.readings).level, PocketModel.feedLevels + 2);
    });

    test('marks where on its curve each level was reached: its feeds among its modules, and each module', () {
      final model = PocketModel(
        tokens: 100,
        readings: const [
          PocketReading(key: 'alpha/first', at: 40, tokens: 1000),
          PocketReading(key: 'alpha/second', at: 100, tokens: 500),
        ],
      );
      // 24 fed; the first module read at 40, ending at 1040; 80 fed at 1080; the second module at 1100, to 1600.
      expect(model.levelMarks, [24, 1040, 1080, 1600]);
      expect(model.levelMarks, hasLength(model.level));
    });

    test('a module it read counts toward its level, and is remembered as read', () {
      final model = PocketModel(
        tokens: 100,
        lastFed: noon,
      ).readAt('alpha/first', 2000, noon.add(const Duration(hours: 5)));
      expect(model.tokens, 100, reason: 'its own text stays where it was');
      expect(model.total, 2100);
      expect(model.level, 3, reason: 'two levels fed, one read');
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
