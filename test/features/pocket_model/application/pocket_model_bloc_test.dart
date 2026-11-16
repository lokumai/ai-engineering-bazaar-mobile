import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_corpus.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final noon = DateTime.utc(2026, 11, 14, 12);

  const module = [
    ['a', 'transformer', 'stacks', 'attention', 'layers'],
    ['each', 'layer', 'refines', 'the', 'tokens'],
  ];
  const texts = MemoryPocketTexts({'alpha/first': module});

  /// Runs [body] in fake time starting at noon, with the bloc over [store].
  void run(
    MemoryPocketModelStore store,
    void Function(FakeAsync async, PocketModelBloc bloc) body, {
    IPocketTexts? pocketTexts = texts,
  }) {
    fakeAsync((async) {
      withClock(async.getClock(noon), () {
        final bloc = PocketModelBloc(store: store, texts: pocketTexts, random: math.Random(3))
          ..add(const PocketModelStarted());
        async.flushMicrotasks();
        body(async, bloc);
        bloc.close();
        async.flushMicrotasks();
      });
    });
  }

  PocketModelReady ready(PocketModelBloc bloc) => bloc.state as PocketModelReady;

  test('a device with nothing kept starts a fresh model, awake', () {
    run(MemoryPocketModelStore(), (async, bloc) {
      expect(ready(bloc).model, PocketModel.fresh);
      expect(ready(bloc).awake, isTrue);
      expect(ready(bloc).known, 0);
      expect(ready(bloc).curve, [(tokens: 0, loss: TinyLm('en').loss())]);
    });
  });

  test('a model left for hours is asleep, and the first tap only wakes it', () {
    final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon.subtract(const Duration(days: 1))));
    run(store, (async, bloc) {
      expect(ready(bloc).awake, isFalse);
      bloc.add(const PocketModelFed());
      async.flushMicrotasks();
      expect(ready(bloc).awake, isTrue);
      expect(ready(bloc).action, PocketAction.woke);
      expect(ready(bloc).model.tokens, 40, reason: 'waking is not a feed');
    });
  });

  test('a feed adds tokens and keeps them, and its model reads that many of its text', () {
    final store = MemoryPocketModelStore();
    run(store, (async, bloc) {
      bloc.add(const PocketModelFed());
      async.flushMicrotasks();
      expect(ready(bloc).model.tokens, PocketModel.feedTokens);
      expect(ready(bloc).action, PocketAction.fed);
      expect(store.kept?.tokens, PocketModel.feedTokens);
      final first = TinyLm('en').train(PocketModel.feedTokens);
      expect(ready(bloc).read, first);
      expect(ready(bloc).known, TinyLm.trained('en', PocketModel.feedTokens).known);
      expect(ready(bloc).curve.last, (tokens: 8, loss: TinyLm.trained('en', 8).loss()));

      bloc.add(const PocketModelFed());
      async.flushMicrotasks();
      expect(ready(bloc).read, TinyLm.trained('en', 8).train(PocketModel.feedTokens), reason: 'it reads on');
    });
  });

  test('a kept count rebuilds the model that read it', () {
    run(MemoryPocketModelStore(const PocketModel(tokens: 400)), (async, bloc) {
      expect(ready(bloc).known, TinyLm.trained('en', 400).known);
      expect(ready(bloc).curve.last.loss, TinyLm.trained('en', 400).loss());
      expect(ready(bloc).read, isEmpty);
    });
  });

  test('the feed that reaches a level says so', () {
    run(MemoryPocketModelStore(const PocketModel(tokens: 20)), (async, bloc) {
      bloc.add(const PocketModelFed());
      async.flushMicrotasks();
      expect(ready(bloc).action, PocketAction.levelUp);
      expect(ready(bloc).model.level, 1);
    });
  });

  test('fed too fast it overfits and repeats itself, refuses more, and recovers after its rest', () {
    run(MemoryPocketModelStore(), (async, bloc) {
      for (var i = 0; i < PocketModel.overfitFeeds; i++) {
        bloc.add(const PocketModelFed());
        async.elapse(const Duration(milliseconds: 300));
      }
      expect(ready(bloc).action, PocketAction.overfit);
      expect(ready(bloc).speech?.tokens.toSet(), {TinyLm.trained('en', ready(bloc).model.tokens).favourite});
      final tokens = ready(bloc).model.tokens;

      bloc.add(const PocketModelFed());
      async.flushMicrotasks();
      expect(ready(bloc).action, PocketAction.refused);
      expect(ready(bloc).model.tokens, tokens);

      async.elapse(PocketModel.overfitRest + const Duration(seconds: 1));
      expect(ready(bloc).action, PocketAction.recovered);
      expect(ready(bloc).model.overfitAt(clock.now()), isFalse);
      expect(ready(bloc).speech, isNull);
    });
  });

  test('asked, it writes in the language set, and each answer is a new beat', () {
    run(MemoryPocketModelStore(const PocketModel(tokens: 400)), (async, bloc) {
      bloc
        ..add(const PocketModelLanguageSet('tr'))
        ..add(const PocketModelTemperatureSet(0.1))
        ..add(const PocketModelAsked());
      async.flushMicrotasks();
      expect(ready(bloc).known, TinyLm.trained('tr', 400).known, reason: 'it read as much of the Turkish text');
      expect(
        ready(bloc).speech?.tokens,
        TinyLm.trained('tr', 400).write(temperature: 0.1, random: math.Random(1)).tokens,
        reason: 'cold, its likeliest Turkish sentence',
      );
      final beat = ready(bloc).beat;
      bloc.add(const PocketModelAsked());
      async.flushMicrotasks();
      expect(ready(bloc).beat, beat + 1);
      expect(ready(bloc).action, PocketAction.spoke);
    });
  });

  test('the temperature is held between 0 and 2', () {
    run(MemoryPocketModelStore(), (async, bloc) {
      bloc.add(const PocketModelTemperatureSet(5));
      async.flushMicrotasks();
      expect(ready(bloc).temperature, 2);
      bloc.add(const PocketModelTemperatureSet(-1));
      async.flushMicrotasks();
      expect(ready(bloc).temperature, 0);
    });
  });

  test('started over, it forgets what it read and keeps level 0, awake', () {
    final store = MemoryPocketModelStore(PocketModel(tokens: 900, lastFed: noon.subtract(const Duration(days: 1))));
    run(store, (async, bloc) {
      bloc.add(const PocketModelReset());
      async.flushMicrotasks();
      expect(ready(bloc).model, PocketModel.fresh);
      expect(ready(bloc).awake, isTrue);
      expect(ready(bloc).known, 0);
      expect(ready(bloc).curve, hasLength(1));
      expect(store.kept, PocketModel.fresh);

      bloc.add(const PocketModelFed());
      async.flushMicrotasks();
      expect(ready(bloc).read, TinyLm('en').train(PocketModel.feedTokens), reason: 'it reads its text from the top');
    });
  });

  group('a module the reader finished', () {
    test('it reads it whole: its words, its tokens toward its level, kept with the model', () {
      final store = MemoryPocketModelStore(PocketModel(tokens: 1590, lastFed: noon));
      run(store, (async, bloc) {
        final known = ready(bloc).known;
        bloc.add(const PocketModelModuleRead('alpha/first'));
        async.flushMicrotasks();
        expect(ready(bloc).model.total, 1602);
        expect(ready(bloc).action, PocketAction.levelUp, reason: 'its tokens reached level 7');
        expect(ready(bloc).known, greaterThan(known));
        expect(ready(bloc).read, module.first);
        expect(ready(bloc).curve.last.tokens, 1602);
        expect(store.kept?.readings.single.key, 'alpha/first');

        bloc.add(const PocketModelModuleRead('alpha/first'));
        async.flushMicrotasks();
        expect(ready(bloc).model.total, 1602, reason: 'a module is read once');
      });
    });

    test('a module it read is read again when it starts, so it knows its words', () {
      final store = MemoryPocketModelStore(
        PocketModel(
          tokens: 40,
          readings: const [PocketReading(key: 'alpha/first', at: 40, tokens: 12)],
          lastFed: noon,
        ),
      );
      run(store, (async, bloc) {
        expect(ready(bloc).known, (TinyLm.trained('en', 40)..read(module)).known);
        expect(ready(bloc).curve.last.tokens, 52);
      });
    });

    test('asked, it speaks of a module it read, even one small beside all its own text', () {
      final store = MemoryPocketModelStore(
        PocketModel(
          tokens: 1600,
          readings: const [PocketReading(key: 'alpha/first', at: 1600, tokens: 12)],
          lastFed: noon,
        ),
      );
      run(store, (async, bloc) {
        bloc.add(const PocketModelTemperatureSet(0.6));
        final words = {'transformer', 'stacks', 'attention', 'layers', 'layer', 'refines'};
        var onTopic = 0;
        for (var i = 0; i < 10; i++) {
          bloc.add(const PocketModelAsked());
          async.flushMicrotasks();
          if (ready(bloc).speech!.tokens.any(words.contains)) onTopic++;
        }
        expect(onTopic, greaterThanOrEqualTo(7));
      });
    });

    test('one it cannot read is left alone', () {
      run(MemoryPocketModelStore(), (async, bloc) {
        bloc.add(const PocketModelModuleRead('beta/missing'));
        async.flushMicrotasks();
        expect(ready(bloc).model, PocketModel.fresh);
      });
      run(MemoryPocketModelStore(), pocketTexts: null, (async, bloc) {
        bloc.add(const PocketModelModuleRead('alpha/first'));
        async.flushMicrotasks();
        expect(ready(bloc).model, PocketModel.fresh);
      });
    });

    test('a feed after it draws the module in the curve', () {
      run(MemoryPocketModelStore(), (async, bloc) {
        bloc.add(const PocketModelModuleRead('alpha/first'));
        async.flushMicrotasks();
        bloc.add(const PocketModelFed());
        async.flushMicrotasks();
        expect(ready(bloc).curve.map((point) => point.tokens), contains(12));
        expect(ready(bloc).curve.last.tokens, 20);
      });
    });
  });

  test('it does not say the same thing twice running', () {
    run(MemoryPocketModelStore(PocketModel(tokens: 1600, lastFed: noon)), (async, bloc) {
      bloc.add(const PocketModelTemperatureSet(0.6));
      final said = <String>[];
      for (var i = 0; i < 6; i++) {
        bloc.add(const PocketModelAsked());
        async.flushMicrotasks();
        said.add(ready(bloc).speech!.tokens.join(' '));
      }
      for (var i = 1; i < said.length; i++) {
        expect(said[i], isNot(said[i - 1]));
      }
    });
  });

  test('a tap pets it', () {
    run(MemoryPocketModelStore(), (async, bloc) {
      bloc.add(const PocketModelPetted());
      async.flushMicrotasks();
      expect(ready(bloc).action, PocketAction.petted);
    });
  });

  group('the stored text', () {
    test('keeps the tokens, the modules read and the last feed', () {
      final model = PocketModel(tokens: 88, lastFed: noon);
      expect(decodePocketModel(encodePocketModel(model)), model);
      final reader = PocketModel(
        tokens: 88,
        readings: const [PocketReading(key: 'alpha/first', at: 40, tokens: 1200)],
        lastFed: noon,
      );
      expect(decodePocketModel(encodePocketModel(reader)), reader);
      expect(decodePocketModel(encodePocketModel(PocketModel.fresh)), PocketModel.fresh);
    });

    test('reads anything else as nothing', () {
      for (final text in ['', 'nope', '[]', '{"tokens": -1}', '{"tokens": "8"}']) {
        expect(decodePocketModel(text), isNull, reason: text);
      }
    });

    test('leaves out a module read that is not one, and keeps the rest', () {
      final model = decodePocketModel(
        '{"tokens": 8, "read": [{"key": "alpha/first", "at": 0, "tokens": 30}, {"key": 3}, "x", '
        '{"key": "alpha/second", "at": -1, "tokens": 5}]}',
      );
      expect(model?.tokens, 8);
      expect(model?.readings, const [PocketReading(key: 'alpha/first', at: 0, tokens: 30)]);
    });
  });

  test('warm, it talks to the reader of its own now and then: after a module, it mostly thanks them (the owner)', () {
    final thanks = {for (final (_, s) in PocketCorpus.chat('en')['thanks']!) s};
    var thanked = 0;
    for (var seed = 0; seed < 12; seed++) {
      fakeAsync((async) {
        withClock(async.getClock(noon), () {
          final bloc = PocketModelBloc(
            store: MemoryPocketModelStore(PocketModel(tokens: 400, lastFed: noon)),
            texts: texts,
            random: math.Random(seed),
          )..add(const PocketModelStarted());
          async.flushMicrotasks();
          bloc
            ..add(const PocketModelModuleRead('alpha/first'))
            ..add(const PocketModelAsked());
          async.flushMicrotasks();
          final said = ready(bloc).speech!.tokens.join(' ');
          if (thanks.contains(said) || said.contains('thank')) thanked++;
          bloc.close();
          async.flushMicrotasks();
        });
      });
    }
    expect(thanked, greaterThan(4));
  });
}
