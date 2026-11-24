import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/apprentice_mind.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/module_sentences.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/signature.dart';
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

/// The reader gave it the course module [key] to read (plan 9.6): one they finished. One it cannot read is passed
/// over for the next of [others] it can, so one module that does not open does not hold up the rest.
final class PocketModelModuleRead extends PocketModelEvent {
  const PocketModelModuleRead(this.key, {this.others = const []});

  final String key;

  /// The other finished modules waiting after [key], in order.
  final List<String> others;

  @override
  List<Object?> get props => [key, others];
}

/// The reader closed the sheet, or petted it fast while it had spoken: its words go.
final class PocketModelHushed extends PocketModelEvent {
  const PocketModelHushed();
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

/// The app came back from the background: a model left awake there for [PocketModel.sleepAfter] has fallen asleep.
final class PocketModelResumed extends PocketModelEvent {
  const PocketModelResumed();
}

/// An overfit model has rested.
final class _PocketModelRecovered extends PocketModelEvent {
  const _PocketModelRecovered();
}

/// What the model last did, for the card to show once: [PocketModelReady.beat] counts each.
enum PocketAction { none, woke, fed, levelUp, overfit, refused, recovered, spoke, petted, studied, unreadable }

/// Its training curve, drawn away from the screen's thread for [model] in [language] (review 5, finding 3).
final class _PocketCurveDrawn extends PocketModelEvent {
  const _PocketCurveDrawn(this.model, this.language, this.curve);

  final PocketModel model;
  final String language;
  final List<LossPoint> curve;

  @override
  List<Object?> get props => [model, language, curve];
}

/// Draws the training curve of a model in a language that has read so many tokens and, at their places, these
/// modules' sentences ([TinyLm.curve]). A test may give one; otherwise the bloc's mind draws it.
typedef CurveDrawer = Future<List<LossPoint>> Function(
  String language,
  int tokens,
  List<(int, List<List<String>>)> readings,
);

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
    this.temperature = defaultTemperature,
    this.speech,
    this.action = PocketAction.none,
    this.beat = 0,
  });

  /// The temperature it starts at, before the reader sets one.
  static const double defaultTemperature = 0.8;

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
/// A model found asleep (not fed for hours) wakes on the first tap of any kind, and asked to chat, answers as it wakes. Fed too fast it overfits: it learns
/// nothing and repeats itself until it has rested ([PocketModel.overfitRest]), and the bloc says when it recovers.
/// Events run one at a time, so fast taps are counted in order and each is kept.
final class PocketModelBloc extends Bloc<PocketModelEvent, PocketModelState> {
  PocketModelBloc({required this._store, this._texts, math.Random? random, this._drawCurve, IApprenticeMind? mind})
    : _random = random ?? math.Random(),
      _mind = mind ?? LocalMind(random ?? math.Random()),
      super(const PocketModelLoading()) {
    on<PocketModelEvent>(_on, transformer: EventTransformers.queue());
  }

  final IPocketModelStore _store;

  /// Where it reads the course's modules; none in a test that gives it none.
  final IPocketTexts? _texts;

  /// A test's curve drawer; null, the mind draws it (review 5, finding 3), from the texts it was sent once each.
  final CurveDrawer? _drawCurve;

  /// Where its language model lives and works: an isolate of its own in the app (review 11, architecture 2).
  final IApprenticeMind _mind;

  /// Each curve asked for; one is drawn at a time, and the latest asked for is the one kept.
  int _curveAsked = 0;
  bool _drawing = false;
  final math.Random _random;
  Timer? _rest;

  /// What it knows of its language model, which has read as many tokens as [PocketModelReady.model] was fed, and its
  /// modules.
  MindView? _lm;

  /// The modules' texts read so far, by language and key, so a curve does not read them again.
  final Map<(String, String), ModuleText> _read = {};

  /// What it said last, a few answers back, for its repetition penalty.
  final List<List<String>> _recent = [];

  /// When it was last woken, or found awake: it falls asleep again [PocketModel.sleepAfter] after this or its last
  /// feed, whichever came later.
  DateTime? _wokeAt;

  Future<ModuleText?> _load(String key, String language) async {
    final kept = _read[(language, key)];
    if (kept != null) return kept;
    final read = await _texts?.text(key, language);
    if (read != null) {
      _read[(language, key)] = read;
      // The mind is sent each text once, so a curve or a rebuild sends none again.
      await _mind.run(MindJobs.learn(language, key, read));
    }
    return read;
  }

  /// The language model of [model] in [language]: its text read to the count, and each module it read that can still
  /// be read.
  Future<MindView> _build(PocketModel model, String language) async {
    final keys = <String>[];
    for (final reading in model.readings) {
      if (await _load(reading.key, language) != null) keys.add(reading.key);
    }
    return _mind.run(MindJobs.build(language, model.tokens, model.level, keys));
  }

  /// Whether [a] and [b] draw the same curve: the same tokens and the same modules read, at the same moments.
  static bool _sameCurve(PocketModel a, PocketModel b) {
    if (a.tokens != b.tokens || a.readings.length != b.readings.length) return false;
    for (var i = 0; i < a.readings.length; i++) {
      if (a.readings[i] != b.readings[i]) return false;
    }
    return true;
  }

  /// Draws the curve of the model as it now stands, after the state that shows it was emitted. Each feed rebuilt the
  /// whole curve on the screen's thread, a stutter that grew with every module read (review 5, finding 3): it is now
  /// drawn by the mind, or a test's [_drawCurve], one at a time, and only the latest is kept.
  void _redraw() {
    _curveAsked++;
    if (!_drawing) unawaited(_drawLatest());
  }

  Future<void> _drawLatest() async {
    _drawing = true;
    try {
      while (!isClosed) {
        final asked = _curveAsked;
        final ready = state;
        final lm = _lm;
        if (ready is! PocketModelReady || lm == null) return;
        final model = ready.model;
        final language = lm.language;
        final draw = _drawCurve;
        final curve = draw == null
            ? await _mind.run(
                MindJobs.curve(language, model.tokens, [
                  for (final reading in model.readings) (reading.at, reading.key),
                ]),
              )
            : await draw(language, model.tokens, [
                for (final reading in model.readings)
                  if (_read[(language, reading.key)] case final text?) (reading.at, text.sentences),
              ]);
        if (isClosed) return;
        if (asked == _curveAsked) {
          add(_PocketCurveDrawn(model, language, curve));
          return;
        }
      }
    } on Object catch (error, stackTrace) {
      // A curve that could not be drawn (an isolate refused) leaves the last one shown; it was an error no one caught
      // at every feed (review 6, finding 14).
      if (!isClosed) addError(error, stackTrace);
    } finally {
      _drawing = false;
    }
  }

  Future<void> _on(PocketModelEvent event, Emitter<PocketModelState> emit) async {
    final now = clock.now();
    switch (event) {
      case PocketModelStarted(:final language):
        final model = await _store.load() ?? PocketModel.fresh;
        final temperature = await _store.loadTemperature();
        final lm = _lm = await _build(model, language);
        final awake = model.moodAt(now) != PocketMood.asleep;
        if (awake) _wokeAt = now;
        emit(
          PocketModelReady(
            model: model,
            known: lm.known,
            awake: awake,
            temperature: temperature ?? PocketModelReady.defaultTemperature,
          ),
        );
        _redraw();
        return;
      case _ when state is! PocketModelReady:
        return;
      default:
    }
    final ready = state as PocketModelReady;
    if (event case _PocketCurveDrawn(:final model, :final language, :final curve)) {
      // A curve for the model as it still stands; one overtaken by a feed, a module read or a new language waits for
      // its own. Only what the curve is drawn from counts: a feed refused while overfit changes the model's burst, not
      // its curve, and the curve was dropped with none asked again (review 8).
      final same = _sameCurve(model, ready.model);
      if (same && language == _lm?.language) emit(ready.copyWith(curve: curve));
      return;
    }
    if (event case PocketModelLanguageSet(:final language)) {
      if (_lm?.language == language) return;
      final lm = _lm = await _build(ready.model, language);
      _recent.clear();
      emit(ready.copyWith(known: lm.known, read: const [], clearSpeech: true));
      _redraw();
      return;
    }
    if (event is PocketModelReset) {
      _rest?.cancel();
      await _store.save(PocketModel.fresh);
      _recent.clear();
      _wokeAt = now;
      final lm = await _mind.run(MindJobs.fresh(PocketModel.fresh.level));
      _lm = lm;
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
    // Only the reader's own tap wakes it: not its sheet closing, its temperature, its rest or the app coming back.
    if (!ready.awake &&
        event is! PocketModelTemperatureSet &&
        event is! _PocketModelRecovered &&
        event is! PocketModelHushed &&
        event is! PocketModelResumed) {
      _wokeAt = now;
      final woken = ready.copyWith(awake: true, action: PocketAction.woke, clearSpeech: true);
      emit(woken);
      // Asked to chat, it answers as it wakes: a reader who taps Chat and sees nothing said may not tap it again (plan
      // 10.3, the owner, 2026-11-16). It says good morning when its level reaches its own talk, else what it can.
      if (event is PocketModelAsked) {
        final lm = _lm!;
        final kind = lm.canTalk && ready.temperature >= cold ? 'woke' : null;
        emit(
          woken.copyWith(
            speech: await _say(ready.temperature, overfit: ready.model.overfitAt(now), kind: kind),
            action: PocketAction.spoke,
          ),
        );
      }
      return;
    }
    switch (event) {
      case PocketModelFed():
        final wasOverfit = ready.model.overfitAt(now);
        final model = ready.model.fedAt(now);
        await _store.save(model);
        final (read, lm) = await _mind.run(MindJobs.feed(model.tokens, model.level));
        _lm = lm;
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
            known: lm.known,
            read: read,
            action: action,
            speech: overfit ? await _say(ready.temperature, overfit: true) : null,
            clearSpeech: !overfit,
          ),
        );
        if (model.tokens != ready.model.tokens) _redraw();
      case PocketModelAsked():
        final kind = _kindFor(ready, now);
        emit(
          ready.copyWith(
            speech: await _say(ready.temperature, overfit: ready.model.overfitAt(now), kind: kind),
            action: PocketAction.spoke,
          ),
        );
      case PocketModelModuleRead(:final key, :final others):
        // A second tap while the first read was loading: the module it names is read, and the next one waiting is
        // not taken in its place (review 7, finding 15).
        if (ready.model.hasRead(key)) return;
        final language = _lm!.language;
        String? found;
        ModuleText? text;
        for (final waiting in [key, ...others]) {
          if (ready.model.hasRead(waiting)) continue;
          text = await _load(waiting, language);
          if (text != null) {
            found = waiting;
            break;
          }
        }
        if (found == null || text == null) {
          // None of them could be read now: it says so, where a tap that did nothing would look broken.
          if (![key, ...others].every(ready.model.hasRead)) emit(ready.copyWith(action: PocketAction.unreadable));
          return;
        }
        final sentences = text.sentences;
        final count = await _mind.run(MindJobs.read(found));
        final model = ready.model.readAt(found, count, now);
        final lm = await _mind.run(MindJobs.level(model.level));
        _lm = lm;
        final signed = ready.model.level < signatureLevel && model.level >= signatureLevel;
        await _store.save(model);
        emit(
          ready.copyWith(
            model: model,
            known: lm.known,
            read: sentences.first,
            action: model.level > ready.model.level ? PocketAction.levelUp : PocketAction.studied,
            // The module that takes it to [signatureLevel] has it say who wrote it, once (the owner, 2026-11-19).
            speech: signed ? (tokens: signatureIn(lm.language), hallucinating: false) : null,
            clearSpeech: !signed,
          ),
        );
        _redraw();
      case PocketModelPetted():
        emit(ready.copyWith(action: PocketAction.petted));
      case PocketModelHushed():
        if (ready.speech != null) emit(ready.copyWith(clearSpeech: true));
      case PocketModelTemperatureSet(:final temperature):
        final held = temperature.clamp(0, 2).toDouble();
        emit(ready.copyWith(temperature: held));
        await _store.saveTemperature(held);
      case PocketModelResumed():
        final fed = ready.model.lastFed;
        final woke = _wokeAt;
        final since = [?fed, ?woke].fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
        if (ready.awake && since != null && now.difference(since) >= PocketModel.sleepAfter) {
          emit(ready.copyWith(awake: false, action: PocketAction.none, clearSpeech: true));
        }
      case _PocketModelRecovered():
        if (ready.model.overfitAt(now)) return;
        final model = ready.model.rested();
        await _store.save(model);
        emit(ready.copyWith(model: model, action: PocketAction.recovered, clearSpeech: true));
      case PocketModelStarted() || PocketModelLanguageSet() || PocketModelReset() || _PocketCurveDrawn():
    }
  }

  /// What it would say to the reader now, of its own talk (`corpus/chat.dart`): thanks just after a module, good
  /// morning just awake, that it is hungry when it is, hello to start with; otherwise a question, a cheer, a word about
  /// itself or the bazaar. Null leaves it to speak of what it read; cold, it always does, its likeliest sentence, so
  /// the temperature shows what it does.
  String? _kindFor(PocketModelReady ready, DateTime now) {
    final lm = _lm!;
    if (!lm.canTalk || ready.temperature < cold) return null;
    final moment = switch (ready.action) {
      PocketAction.studied || PocketAction.levelUp when ready.model.readings.isNotEmpty => 'thanks',
      PocketAction.woke => 'woke',
      _ when ready.model.moodAt(now) == PocketMood.hungry => 'hungry',
      _ when _recent.isEmpty => 'hello',
      _ => null,
    };
    // A moment is mostly answered; otherwise it talks now and then, more while it has read no module.
    if (moment != null && _random.nextDouble() < 0.75) return moment;
    if (_random.nextDouble() >= (lm.hasTopics ? 0.3 : 0.5)) return null;
    final kinds = [
      for (final kind in const ['curious', 'cheer', 'self', 'bazaar', 'hello'])
        if (lm.kinds.contains(kind)) kind,
    ];
    return kinds.isEmpty ? null : kinds[_random.nextInt(kinds.length)];
  }

  /// What it says: overfit, the word it read most, again and again; with a [kind], its own talk to the reader of that
  /// kind ([TinyLm.talk]); otherwise what its language model writes. Once it has read modules, it speaks of one of
  /// them (the last read a third of the time, else any), thinks over more sentences the more it read
  /// ([TinyLm.thoughtsFor]), and from level 3 now and then tells it as one tells a friend ("did you know"). From
  /// [signatureLevel], one time in [signatureOdds] it says who wrote it instead. Its mind writes it ([MindJobs.say]),
  /// away from the screen's thread in the app (review 11, features 3).
  Future<Babble> _say(double temperature, {required bool overfit, String? kind}) async {
    final (said, kept) = await _mind.run(MindJobs.say(temperature, [..._recent], overfit: overfit, kind: kind));
    if (kept) _remember(said);
    return said;
  }

  void _remember(Babble said) {
    _recent.add(said.tokens);
    if (_recent.length > 3) _recent.removeAt(0);
  }

  void _restIn(Duration rest) {
    _rest?.cancel();
    _rest = Timer(rest, () {
      if (!isClosed) add(const _PocketModelRecovered());
    });
  }

  @override
  Future<void> close() async {
    _rest?.cancel();
    await super.close();
    await _mind.close();
  }
}
