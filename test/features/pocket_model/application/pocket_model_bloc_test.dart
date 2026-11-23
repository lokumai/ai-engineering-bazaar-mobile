import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_corpus.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/signature.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
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

  // Plan 10.3 (the owner, 2026-11-16): Chat on a sleeping model said nothing, so a new reader would not know it talks.
  test('asked to chat while asleep, it wakes and answers at once', () {
    final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon.subtract(const Duration(days: 1))));
    run(store, (async, bloc) {
      final actions = <PocketAction>[];
      final listening = bloc.stream.listen((state) => actions.add((state as PocketModelReady).action));
      bloc.add(const PocketModelAsked());
      async.flushMicrotasks();
      listening.cancel();

      expect(actions, [PocketAction.woke, PocketAction.spoke], reason: 'it wakes, then speaks');
      expect(ready(bloc).awake, isTrue);
      expect(ready(bloc).speech?.tokens, isNotEmpty);
    });
  });

  test('woken by Chat at a level with its own talk, it says good morning', () {
    final woke = {for (final (_, s) in PocketCorpus.chat('en')['woke']!) s};
    final store = MemoryPocketModelStore(
      PocketModel(tokens: PocketModel.levels[4], lastFed: noon.subtract(const Duration(days: 1))),
    );
    run(store, (async, bloc) {
      bloc.add(const PocketModelAsked());
      async.flushMicrotasks();

      expect(woke, contains(ready(bloc).speech!.tokens.join(' ')));
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

  test('the temperature set is kept, and the next start begins at it', () {
    final store = MemoryPocketModelStore();
    run(store, (async, bloc) {
      expect(ready(bloc).temperature, PocketModelReady.defaultTemperature, reason: 'none set yet');
      bloc.add(const PocketModelTemperatureSet(1.5));
      async.flushMicrotasks();
      expect(store.temperature, 1.5);
    });
    run(store, (async, bloc) => expect(ready(bloc).temperature, 1.5));
  });

  // The owner, 2026-11-16: looking at a sleeping model and closing its sheet woke it.
  test('asleep, its sheet closing leaves it asleep', () {
    final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon.subtract(const Duration(days: 1))));
    run(store, (async, bloc) {
      bloc.add(const PocketModelHushed());
      async.flushMicrotasks();
      expect(ready(bloc).awake, isFalse);
      expect(ready(bloc).action, PocketAction.none);
    });
  });

  group('back from the background', () {
    test('left awake there longer than its sleep, it has fallen asleep', () {
      final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon));
      run(store, (async, bloc) {
        async.elapse(PocketModel.sleepAfter);
        bloc.add(const PocketModelResumed());
        async.flushMicrotasks();
        expect(ready(bloc).awake, isFalse);
        expect(ready(bloc).action, PocketAction.none, reason: 'falling asleep is not a tap');
      });
    });

    test('back sooner, it is still awake', () {
      final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon));
      run(store, (async, bloc) {
        async.elapse(const Duration(hours: 2));
        bloc.add(const PocketModelResumed());
        async.flushMicrotasks();
        expect(ready(bloc).awake, isTrue);
      });
    });

    test('woken in the night without a feed, it stays awake until its sleep has passed since then', () {
      final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon.subtract(const Duration(days: 1))));
      run(store, (async, bloc) {
        bloc.add(const PocketModelPetted());
        async.flushMicrotasks();
        expect(ready(bloc).awake, isTrue);

        async.elapse(const Duration(minutes: 5));
        bloc.add(const PocketModelResumed());
        async.flushMicrotasks();
        expect(ready(bloc).awake, isTrue, reason: 'its last feed is old, but it was woken five minutes ago');

        async.elapse(PocketModel.sleepAfter);
        bloc.add(const PocketModelResumed());
        async.flushMicrotasks();
        expect(ready(bloc).awake, isFalse);
      });
    });

    test('asleep, coming back does not wake it', () {
      final store = MemoryPocketModelStore(PocketModel(tokens: 40, lastFed: noon.subtract(const Duration(days: 1))));
      run(store, (async, bloc) {
        bloc.add(const PocketModelResumed());
        async.flushMicrotasks();
        expect(ready(bloc).awake, isFalse);
      });
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

    // A module whose text would not open held up every module after it, and the tap did nothing.
    test('one it cannot read is passed over for the next one waiting', () {
      final store = MemoryPocketModelStore();
      run(store, (async, bloc) {
        bloc.add(const PocketModelModuleRead('beta/missing', others: ['alpha/first']));
        async.flushMicrotasks();
        expect(ready(bloc).model.readings.single.key, 'alpha/first');
        expect(ready(bloc).action, isIn([PocketAction.studied, PocketAction.levelUp]));
      });
    });

    test('when none of them can be read, it says so', () {
      run(MemoryPocketModelStore(), (async, bloc) {
        final beat = ready(bloc).beat;
        bloc.add(const PocketModelModuleRead('beta/missing', others: ['beta/gone']));
        async.flushMicrotasks();
        expect(ready(bloc).model, PocketModel.fresh);
        expect(ready(bloc).action, PocketAction.unreadable);
        expect(ready(bloc).beat, beat + 1);
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

    // Review 5, finding 17: the model reads its text again to the count at start, one token at a time.
    test('caps a count past what a reader can feed, so a damaged file cannot hold the start', () {
      final model = decodePocketModel(
        '{"tokens": 9007199254740991, "read": [{"key": "alpha/first", "at": 9007199254740991, "tokens": 30}]}',
      );
      expect(model?.tokens, PocketModel.maxTokens);
      expect(model?.readings.single.at, PocketModel.maxTokens);
      expect(PocketModel(tokens: PocketModel.maxTokens).fedAt(noon).tokens, PocketModel.maxTokens);
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

  // The owner, 2026-11-19: the author's name, found only by a reader who keeps going.
  group('the signature', () {
    /// A model fed to the top that read [count] modules the test cannot open, so its level is 7 + [count].
    PocketModel readMany(int count) => PocketModel(
      tokens: PocketModel.levels.last,
      readings: [for (var i = 0; i < count; i++) PocketReading(key: 'gone/$i', at: PocketModel.levels.last, tokens: 1)],
      lastFed: noon,
    );

    /// How many of [chats] chats are the signature.
    int signed(PocketModelBloc bloc, FakeAsync async, int chats) {
      var count = 0;
      for (var i = 0; i < chats; i++) {
        bloc.add(const PocketModelAsked());
        async.flushMicrotasks();
        if (listEquals(ready(bloc).speech?.tokens, signatureIn('en'))) count++;
      }
      return count;
    }

    test('the module that takes it to its level has it say who wrote it, once', () {
      final store = MemoryPocketModelStore(readMany(signatureLevel - PocketModel.feedLevels - 1));
      run(store, (async, bloc) {
        expect(ready(bloc).model.level, signatureLevel - 1);
        bloc.add(const PocketModelModuleRead('alpha/first'));
        async.flushMicrotasks();
        expect(ready(bloc).model.level, signatureLevel);
        expect(ready(bloc).action, PocketAction.levelUp);
        expect(ready(bloc).speech?.tokens, ['Arda', 'Cengaver', 'wrote', 'me']);
      });
    });

    test('from its level on, a chat now and then says it, about one in $signatureOdds', () {
      run(MemoryPocketModelStore(readMany(signatureLevel - PocketModel.feedLevels)), (async, bloc) {
        final count = signed(bloc, async, 1000);
        expect(count, inInclusiveRange(2, 25));
      });
    });

    test('below its level, it never says it', () {
      run(MemoryPocketModelStore(readMany(signatureLevel - PocketModel.feedLevels - 1)), (async, bloc) {
        expect(signed(bloc, async, 1000), 0);
      });
    });

    test('it says it in the app\'s language, the name the same in each', () {
      for (final language in ['en', 'tr', 'fa']) {
        expect(signatureIn(language), containsAllInOrder(['Arda', 'Cengaver']), reason: language);
      }
      expect(signatureIn('de'), signatureIn('en'));
    });
  });

  // Review 5, finding 3: each feed rebuilt the whole training curve on the screen's thread, a stutter that grew with
  // every module read. It is drawn elsewhere now; the feed shows at once and the curve follows.
  group('its curve is drawn away from the feed', () {
    test('a feed shows at once; the curve drawn for it follows, and only the latest drawn is kept', () {
      fakeAsync((async) {
        withClock(async.getClock(noon), () {
          final asked = <(int, Completer<List<LossPoint>>)>[];
          final bloc = PocketModelBloc(
            store: MemoryPocketModelStore(),
            texts: texts,
            random: math.Random(3),
            drawCurve: (language, tokens, readings) {
              final drawn = Completer<List<LossPoint>>();
              asked.add((tokens, drawn));
              return drawn.future;
            },
          )..add(const PocketModelStarted());
          async.flushMicrotasks();
          expect(asked.map((ask) => ask.$1), [0]);
          asked.single.$2.complete([(tokens: 0, loss: 9)]);
          async.flushMicrotasks();
          expect(ready(bloc).curve, [(tokens: 0, loss: 9.0)]);

          bloc
            ..add(const PocketModelFed())
            ..add(const PocketModelFed());
          async.flushMicrotasks();
          expect(ready(bloc).model.tokens, 2 * PocketModel.feedTokens, reason: 'the feeds wait for no curve');
          expect(ready(bloc).curve, [(tokens: 0, loss: 9.0)], reason: 'the old curve until the new is drawn');
          expect(asked.map((ask) => ask.$1), [0, PocketModel.feedTokens], reason: 'one drawn at a time');

          // The first feed's curve comes after the second feed: it is not kept, and the latest is drawn.
          asked[1].$2.complete([(tokens: PocketModel.feedTokens, loss: 8)]);
          async.flushMicrotasks();
          expect(ready(bloc).curve, [(tokens: 0, loss: 9.0)]);
          expect(asked.map((ask) => ask.$1), [0, PocketModel.feedTokens, 2 * PocketModel.feedTokens]);
          asked[2].$2.complete([(tokens: 2 * PocketModel.feedTokens, loss: 7)]);
          async.flushMicrotasks();
          expect(ready(bloc).curve, [(tokens: 2 * PocketModel.feedTokens, loss: 7.0)]);
          expect(ready(bloc).action, PocketAction.fed, reason: 'a curve drawn plays no action again');

          bloc.close();
          async.flushMicrotasks();
        });
      });
    });

    test('started in a language, its curve is drawn in it', () {
      run(MemoryPocketModelStore(const PocketModel(tokens: 400)), (async, bloc) {
        expect(ready(bloc).curve.last.loss, TinyLm.trained('en', 400).loss());
      });
      fakeAsync((async) {
        final bloc = PocketModelBloc(store: MemoryPocketModelStore(const PocketModel(tokens: 400)), texts: texts)
          ..add(const PocketModelStarted(language: 'tr'));
        async.flushMicrotasks();
        expect(ready(bloc).curve.last.loss, TinyLm.trained('tr', 400).loss());
        bloc.close();
        async.flushMicrotasks();
      });
    });
  });
}
