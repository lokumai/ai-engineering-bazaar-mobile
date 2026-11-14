import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final noon = DateTime.utc(2026, 11, 14, 12);

  /// Runs [body] in fake time starting at noon, with the bloc over [store].
  void run(MemoryPocketModelStore store, void Function(FakeAsync async, PocketModelBloc bloc) body) {
    fakeAsync((async) {
      withClock(async.getClock(noon), () {
        final bloc = PocketModelBloc(store: store, random: math.Random(3))..add(const PocketModelStarted());
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

  test('a tap pets it', () {
    run(MemoryPocketModelStore(), (async, bloc) {
      bloc.add(const PocketModelPetted());
      async.flushMicrotasks();
      expect(ready(bloc).action, PocketAction.petted);
    });
  });

  group('the stored text', () {
    test('keeps the tokens and the last feed', () {
      final model = PocketModel(tokens: 88, lastFed: noon);
      expect(decodePocketModel(encodePocketModel(model)), model);
      expect(decodePocketModel(encodePocketModel(PocketModel.fresh)), PocketModel.fresh);
    });

    test('reads anything else as nothing', () {
      for (final text in ['', 'nope', '[]', '{"tokens": -1}', '{"tokens": "8"}']) {
        expect(decodePocketModel(text), isNull, reason: text);
      }
    });
  });
}
