import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';
import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PocketModelEvent extends Equatable {
  const PocketModelEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the kept model, which reads and speaks [language].
final class PocketModelStarted extends PocketModelEvent {
  const PocketModelStarted({this.language = 'en'});

  final String language;

  @override
  List<Object?> get props => [language];
}

/// The app's language changed: the model reads and speaks this one, and has read as much of its text.
final class PocketModelLanguageSet extends PocketModelEvent {
  const PocketModelLanguageSet(this.language);

  final String language;

  @override
  List<Object?> get props => [language];
}

/// The reader fed it tokens.
final class PocketModelFed extends PocketModelEvent {
  const PocketModelFed();
}

/// The reader asked it to speak.
final class PocketModelAsked extends PocketModelEvent {
  const PocketModelAsked();
}

/// The reader asked to start it over: it forgets what it read and starts again at level 0.
final class PocketModelReset extends PocketModelEvent {
  const PocketModelReset();
}

/// The reader gave it the course module [key] to read (plan 9.6): one they finished.
final class PocketModelModuleRead extends PocketModelEvent {
  const PocketModelModuleRead(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}

/// The reader tapped it.
final class PocketModelPetted extends PocketModelEvent {
  const PocketModelPetted();
}

/// The reader set its temperature.
final class PocketModelTemperatureSet extends PocketModelEvent {
  const PocketModelTemperatureSet(this.temperature);

  final double temperature;

  @override
  List<Object?> get props => [temperature];
}

/// An overfit model has rested.
final class _PocketModelRecovered extends PocketModelEvent {
  const _PocketModelRecovered();
}

/// What the model last did, for the card to show once: [PocketModelReady.beat] counts each.
enum PocketAction { none, woke, fed, levelUp, overfit, refused, recovered, spoke, petted, studied }

sealed class PocketModelState extends Equatable {
  const PocketModelState();
}

final class PocketModelLoading extends PocketModelState {
  const PocketModelLoading();

  @override
  List<Object?> get props => [];
}

/// The model and what is going on with it.
///
/// One state with fields, by the rule's second exception (a transactional snapshot): the model, whether it is awake,
/// its temperature, what it said and what it last did change together and are drawn together.
final class PocketModelReady extends PocketModelState {
  const PocketModelReady({
    required this.model,
    required this.awake,
    this.curve = const [],
    this.known = 0,
    this.read = const [],
    this.temperature = 0.8,
    this.speech,
    this.action = PocketAction.none,
    this.beat = 0,
  });

  final PocketModel model;

  /// Its training curve, from the first token to now, measured on text it never read.
  final List<LossPoint> curve;

  /// The words it has read at least once.
  final int known;

  /// The words the last feed read, for the card to show.
  final List<String> read;

  /// Whether it is awake: a model asleep stays so until the reader wakes it.
  final bool awake;
  final double temperature;

  /// What it said last, or null before it spoke.
  final Babble? speech;
  final PocketAction action;

  /// Counts the actions, so the card plays each one once, the same action twice included.
  final int beat;

  PocketModelReady copyWith({
    PocketModel? model,
    List<LossPoint>? curve,
    int? known,
    List<String>? read,
    bool? awake,
    double? temperature,
    Babble? speech,
    PocketAction? action,
    bool clearSpeech = false,
  }) => PocketModelReady(
    model: model ?? this.model,
    curve: curve ?? this.curve,
    known: known ?? this.known,
    read: read ?? this.read,
    awake: awake ?? this.awake,
    temperature: temperature ?? this.temperature,
    speech: clearSpeech ? null : speech ?? this.speech,
    action: action ?? this.action,
    beat: action == null ? beat : beat + 1,
  );

  @override
  List<Object?> get props => [model, curve, known, read, awake, temperature, speech, action, beat];
}

/// The pocket model on Home (plan 9.2): it keeps the model on the device, and turns the reader's taps into tokens its
/// language model ([TinyLm]) reads, sentences it writes, and moods. The language model is rebuilt from the kept count
/// at the start and when the app's language changes, and reads on with each feed.
///
/// A model found asleep (not fed for hours) wakes on the first tap of any kind. Fed too fast it overfits: it learns
/// nothing and repeats itself until it has rested ([PocketModel.overfitRest]), and the bloc says when it recovers.
/// Events run one at a time, so fast taps are counted in order and each is kept.
final class PocketModelBloc extends Bloc<PocketModelEvent, PocketModelState> {
  PocketModelBloc({required this._store, this._texts, math.Random? random})
    : _random = random ?? math.Random(),
      super(const PocketModelLoading()) {
    on<PocketModelEvent>(_on, transformer: EventTransformers.queue());
  }

  final IPocketModelStore _store;

  /// Where it reads the course's modules; none in a test that gives it none.
  final IPocketTexts? _texts;
  final math.Random _random;
  Timer? _rest;

  /// Its language model, which has read as many tokens as [PocketModelReady.model] was fed, and its modules.
  TinyLm? _lm;

  /// The modules' sentences read so far, by language and key, so a curve does not read them again.
  final Map<(String, String), List<List<String>>> _sentences = {};

  /// What it said last, a few answers back, for its repetition penalty.
  final List<List<String>> _recent = [];

  Future<List<List<String>>?> _load(String key, String language) async {
    final kept = _sentences[(language, key)];
    if (kept != null) return kept;
    final read = await _texts?.sentences(key, language);
    if (read != null) _sentences[(language, key)] = read;
    return read;
  }

  /// The language model of [model] in [language]: its text read to the count, and each module it read that can still
  /// be read; and its training curve.
  Future<(TinyLm, List<LossPoint>)> _build(PocketModel model, String language) async {
    final lm = TinyLm.trained(language, model.tokens);
    final readings = <(int, List<List<String>>)>[];
    for (final reading in model.readings) {
      final sentences = await _load(reading.key, language);
      if (sentences == null) continue;
      lm.read(sentences, topic: reading.key);
      readings.add((reading.at, sentences));
    }
    return (lm, TinyLm.curve(language, model.tokens, readings: readings));
  }

  /// The curve of [model] in [language], from the modules' sentences already read.
  List<LossPoint> _curveOf(PocketModel model, String language) => TinyLm.curve(
    language,
    model.tokens,
    readings: [
      for (final reading in model.readings)
        if (_sentences[(language, reading.key)] case final sentences?) (reading.at, sentences),
    ],
  );

  Future<void> _on(PocketModelEvent event, Emitter<PocketModelState> emit) async {
    final now = clock.now();
    switch (event) {
      case PocketModelStarted(:final language):
        final model = await _store.load() ?? PocketModel.fresh;
        final (lm, curve) = await _build(model, language);
        _lm = lm;
        emit(
          PocketModelReady(model: model, curve: curve, known: lm.known, awake: model.moodAt(now) != PocketMood.asleep),
        );
        return;
      case _ when state is! PocketModelReady:
        return;
      default:
    }
    final ready = state as PocketModelReady;
    if (event case PocketModelLanguageSet(:final language)) {
      if (_lm?.language == language) return;
      final (lm, curve) = await _build(ready.model, language);
      _lm = lm;
      _recent.clear();
      emit(ready.copyWith(curve: curve, known: lm.known, read: const [], clearSpeech: true));
      return;
    }
    if (event is PocketModelReset) {
      _rest?.cancel();
      await _store.save(PocketModel.fresh);
      _recent.clear();
      final lm = _lm = TinyLm(_lm?.language ?? 'en');
      emit(
        PocketModelReady(
          model: PocketModel.fresh,
          curve: TinyLm.curve(lm.language, 0),
          awake: true,
          temperature: ready.temperature,
          beat: ready.beat + 1,
        ),
      );
      return;
    }
    if (!ready.awake && event is! PocketModelTemperatureSet && event is! _PocketModelRecovered) {
      emit(ready.copyWith(awake: true, action: PocketAction.woke, clearSpeech: true));
      return;
    }
    switch (event) {
      case PocketModelFed():
        final wasOverfit = ready.model.overfitAt(now);
        final model = ready.model.fedAt(now);
        await _store.save(model);
        final lm = _lm!;
        final read = model.tokens > lm.trained ? lm.train(model.tokens - lm.trained) : const <String>[];
        final overfit = model.overfitAt(now);
        if (overfit) _restIn(PocketModel.overfitRest);
        final action = switch (()) {
          _ when wasOverfit => PocketAction.refused,
          _ when overfit => PocketAction.overfit,
          _ when model.level > ready.model.level => PocketAction.levelUp,
          _ => PocketAction.fed,
        };
        emit(
          ready.copyWith(
            model: model,
            curve: model.tokens == ready.model.tokens ? null : _curveOf(model, lm.language),
            known: lm.known,
            read: read,
            action: action,
            speech: overfit ? _say(ready.temperature, overfit: true) : null,
            clearSpeech: !overfit,
          ),
        );
      case PocketModelAsked():
        emit(
          ready.copyWith(
            speech: _say(ready.temperature, overfit: ready.model.overfitAt(now)),
            action: PocketAction.spoke,
          ),
        );
      case PocketModelModuleRead(:final key):
        if (ready.model.hasRead(key)) return;
        final lm = _lm!;
        final sentences = await _load(key, lm.language);
        if (sentences == null) return;
        final count = lm.read(sentences, topic: key);
        final model = ready.model.readAt(key, count, now);
        await _store.save(model);
        emit(
          ready.copyWith(
            model: model,
            curve: _curveOf(model, lm.language),
            known: lm.known,
            read: sentences.first,
            action: model.level > ready.model.level ? PocketAction.levelUp : PocketAction.studied,
            clearSpeech: true,
          ),
        );
      case PocketModelPetted():
        emit(ready.copyWith(action: PocketAction.petted));
      case PocketModelTemperatureSet(:final temperature):
        emit(ready.copyWith(temperature: temperature.clamp(0, 2).toDouble()));
      case _PocketModelRecovered():
        if (ready.model.overfitAt(now)) return;
        final model = ready.model.rested();
        await _store.save(model);
        emit(ready.copyWith(model: model, action: PocketAction.recovered, clearSpeech: true));
      case PocketModelStarted() || PocketModelLanguageSet() || PocketModelReset():
    }
  }

  /// What it says: overfit, the word it read most, again and again; otherwise what its language model writes. Once it
  /// has read modules, it speaks of one of them (the last read a third of the time, else any), and thinks over more
  /// sentences the more it read ([TinyLm.thoughtsFor]).
  Babble _say(double temperature, {required bool overfit}) {
    final lm = _lm!;
    final word = lm.favourite;
    if (overfit && word != null) {
      return (tokens: List.filled(4 + _random.nextInt(3), word), hallucinating: false);
    }
    final topics = lm.topics;
    final topic = topics.isEmpty
        ? null
        : _random.nextInt(3) == 0
        ? topics.last
        : topics[_random.nextInt(topics.length)];
    final said = lm.write(
      temperature: temperature,
      random: _random,
      recent: _recent,
      topic: topic,
      thoughts: TinyLm.thoughtsFor(topics.length),
    );
    _recent.add(said.tokens);
    if (_recent.length > 3) _recent.removeAt(0);
    return said;
  }

  void _restIn(Duration rest) {
    _rest?.cancel();
    _rest = Timer(rest, () {
      if (!isClosed) add(const _PocketModelRecovered());
    });
  }

  @override
  Future<void> close() {
    _rest?.cancel();
    return super.close();
  }
}
