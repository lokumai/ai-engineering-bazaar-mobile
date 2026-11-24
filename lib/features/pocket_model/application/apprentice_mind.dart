import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/module_sentences.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/signature.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';

/// What the bloc needs to know of the language model it no longer holds: its [language], the words it [known]s, whether
/// it [canTalk] and in which [kinds] of its own talk, and whether it has read any module ([hasTopics]).
typedef MindView = ({String language, int known, bool canTalk, List<String> kinds, bool hasTopics});

/// The Apprentice's language model and what it has been given to read, where it lives: on the screen's isolate in a
/// test, and in an isolate of its own in the app.
final class MindState {
  MindState(this.random, {this.apart = false});

  /// Its dice, for what it writes.
  final math.Random random;

  /// Whether its training curve is drawn in yet another isolate, so a curve does not hold up its answers.
  final bool apart;

  /// Its language model, once built.
  TinyLm? lm;

  /// The modules' texts it was given, by language and key, sent to it once each.
  final Map<(String, String), ModuleText> texts = {};

  MindView get view {
    final lm = this.lm!;
    return (
      language: lm.language,
      known: lm.known,
      canTalk: lm.canTalk,
      kinds: [...lm.kinds],
      hasTopics: lm.topics.isNotEmpty,
    );
  }
}

/// A job for the mind, run where it lives; what it returns crosses back.
typedef MindTask<R> = FutureOr<R> Function(MindState mind);

/// Where the Apprentice's language model is kept and worked (review 11, architecture 2 and features 3): it was rebuilt,
/// fed and asked on the screen's isolate, a run of dropped frames at each start, each language change and each Chat
/// answer, which grew with every module read. Jobs run one after another, in the order sent.
abstract interface class IApprenticeMind {
  Future<R> run<R>(MindTask<R> task);

  Future<void> close();
}

/// The mind on the calling isolate, with the bloc's own dice: for tests.
final class LocalMind implements IApprenticeMind {
  LocalMind(math.Random random) : _state = MindState(random);

  final MindState _state;

  @override
  Future<R> run<R>(MindTask<R> task) => Future.sync(() => task(_state));

  @override
  Future<void> close() async {}
}

/// The mind in an isolate of its own, started at its first job and killed when it closes. A job's closure crosses to it
/// with what it captured, so each job is made by a static function of [MindJobs] and captures only its arguments.
final class IsolateMind implements IApprenticeMind {
  IsolateMind() {
    _replies.listen(_reply);
  }

  final ReceivePort _replies = ReceivePort();
  final Map<int, Completer<Object?>> _waiting = {};
  Completer<SendPort>? _started;
  Isolate? _isolate;
  int _next = 0;
  bool _closed = false;

  Future<SendPort> _start() {
    final started = _started;
    if (started != null) return started.future;
    final starting = _started = Completer<SendPort>();
    Isolate.spawn(_serve, _replies.sendPort, debugName: 'apprentice').then((isolate) {
      if (_closed) {
        isolate.kill();
      } else {
        _isolate = isolate;
      }
    }, onError: starting.completeError);
    return starting.future;
  }

  @override
  Future<R> run<R>(MindTask<R> task) async {
    if (_closed) throw StateError('the mind is closed');
    final port = await _start();
    final id = _next++;
    final answer = _waiting[id] = Completer<Object?>();
    port.send((id, task));
    return await answer.future as R;
  }

  void _reply(Object? message) {
    switch (message) {
      case final SendPort port:
        _started?.complete(port);
      case (final int id, final Object? value, final String? error, final String? stack):
        final answer = _waiting.remove(id);
        if (answer == null) return;
        if (error == null) {
          answer.complete(value);
        } else {
          answer.completeError(RemoteError(error, stack ?? ''));
        }
    }
  }

  static void _serve(SendPort replies) {
    final requests = ReceivePort();
    replies.send(requests.sendPort);
    final mind = MindState(math.Random(), apart: true);
    requests.listen((message) async {
      final (id, task) = message as (int, FutureOr<Object?> Function(MindState));
      try {
        replies.send((id, await task(mind), null, null));
      } on Object catch (error, stackTrace) {
        replies.send((id, null, '$error', '$stackTrace'));
      }
    });
  }

  @override
  Future<void> close() async {
    _closed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _replies.close();
    for (final answer in _waiting.values) {
      answer.completeError(StateError('the mind is closed'));
    }
    _waiting.clear();
  }
}

/// The jobs the bloc sends its mind. Each is made here, in a static function, so its closure captures nothing but its
/// arguments and crosses to another isolate.
abstract final class MindJobs {
  /// Keeps the text of module [key] in [language], sent once.
  static MindTask<void> learn(String language, String key, ModuleText text) =>
      (mind) => mind.texts[(language, key)] = text;

  /// Builds the model of [language] read to [tokens], at [level], and each of [keys] it was given the text of.
  static MindTask<MindView> build(String language, int tokens, int level, List<String> keys) => (mind) {
    final lm = mind.lm = TinyLm.trained(language, tokens)..level = level;
    for (final key in keys) {
      final text = mind.texts[(language, key)];
      if (text == null) continue;
      lm.read(text.sentences, topic: key, sections: text.sections);
    }
    return mind.view;
  };

  /// A model that has read nothing, in its language, at level 0.
  static MindTask<MindView> fresh(int level) => (mind) {
    mind.lm = TinyLm(mind.lm?.language ?? 'en')..level = level;
    return mind.view;
  };

  /// Reads on to [tokens], at [level]: the words it read, if any.
  static MindTask<(List<String>, MindView)> feed(int tokens, int level) => (mind) {
    final lm = mind.lm!..level = level;
    final read = tokens > lm.trained ? lm.train(tokens - lm.trained) : const <String>[];
    return (read, mind.view);
  };

  /// Reads module [key], whose text it was given: the tokens it read.
  static MindTask<int> read(String key) => (mind) {
    final lm = mind.lm!;
    final text = mind.texts[(lm.language, key)]!;
    return lm.read(text.sentences, topic: key, sections: text.sections);
  };

  /// Sets its level.
  static MindTask<MindView> level(int level) => (mind) {
    mind.lm!.level = level;
    return mind.view;
  };

  /// What it says ([PocketModelBloc]'s rules), and whether the bloc keeps it among what it said [recent]ly.
  static MindTask<(Babble, bool)> say(
    double temperature,
    List<List<String>> recent, {
    required bool overfit,
    String? kind,
  }) => (mind) {
    final lm = mind.lm!;
    final random = mind.random;
    final word = lm.favourite;
    if (overfit && word != null) {
      return ((tokens: List.filled(4 + random.nextInt(3), word), hallucinating: false), false);
    }
    // Past [signatureLevel], now and then it says who wrote it (the owner, 2026-11-19).
    if (lm.level >= signatureLevel && random.nextInt(signatureOdds) == 0) {
      return ((tokens: signatureIn(lm.language), hallucinating: false), false);
    }
    if (kind != null) return (lm.talk(kind, temperature: temperature, random: random, recent: recent), true);
    final topics = lm.topics;
    final topic = topics.isEmpty
        ? null
        : random.nextInt(3) == 0
        ? topics.last
        : topics[random.nextInt(topics.length)];
    final said = lm.write(
      temperature: temperature,
      random: random,
      recent: recent,
      topic: topic,
      thoughts: TinyLm.thoughtsFor(topics.length),
      leadIn: topic != null && lm.level >= 3 && random.nextDouble() < 0.3,
    );
    return (said, true);
  };

  /// Its training curve at [tokens], with each module of [readings] read at its place, from the texts it was given; in
  /// one more isolate when [MindState.apart], so it does not hold up an answer.
  static MindTask<List<LossPoint>> curve(String language, int tokens, List<(int, String)> readings) => (mind) {
    final read = [
      for (final (at, key) in readings)
        if (mind.texts[(language, key)] case final text?) (at, text.sentences),
    ];
    return mind.apart
        ? Isolate.run(() => TinyLm.curve(language, tokens, readings: read))
        : TinyLm.curve(language, tokens, readings: read);
  };
}
