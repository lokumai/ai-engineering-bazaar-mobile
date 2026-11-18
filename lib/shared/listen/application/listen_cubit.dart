import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/spoken_parts.dart';

/// A module to read aloud: which one, its title for the bar over the navigation, its language and its parts.
final class ListenSession extends Equatable {
  const ListenSession({
    required this.module,
    required this.track,
    required this.title,
    required this.language,
    required this.parts,
  });

  final String module;
  final Track track;
  final String title;

  /// The module's language, which picks the voice.
  final String language;
  final List<SpokenPart> parts;

  @override
  List<Object?> get props => [module, track, title, language, parts];
}

/// The module read aloud by the phone's own voice (plan 15), for the whole app (the owner, 2026-11-18): it goes on
/// with the screen off, and while the reader moves to another tab or module, where a bar over the navigation holds it;
/// back on the module it is where the voice is. Started at a module's head, paused and played again, a part back or
/// on, at another pace, and stopped; another module started takes its place.
///
/// A module stopped, left paused for [restAfter], or put aside for another keeps its place, and started again it goes
/// on from there (the owner, 2026-11-18): the bar over the navigation leaves, the band is back, and the module's Listen
/// says it resumes. Read to its end, the place is let go. The places last while the app runs.
///
/// A `Cubit` because every call is atomic; a newer call cuts the reading under way by its turn, not by an event queue.
final class ListenCubit extends Cubit<ListenState> {
  ListenCubit({required this._speech, this.restAfter = const Duration(minutes: 2)}) : super(const ListenIdle(rate: 1));

  /// How long a pause lasts before the reading ends, its place kept.
  final Duration restAfter;

  /// The paces offered, in the order Speed steps through them; the first is the voice's own.
  static const rates = [1.0, 1.25, 1.5, 0.75];

  final ISpeech _speech;

  double _rate = rates.first;

  /// The module being read, or paused; null while none is.
  ListenSession? _session;

  /// The phone's answer for each language, asked once.
  final _voices = <String, Future<bool>>{};

  /// The reading under way; a call that starts another or stops it moves the turn on, so the one before ends.
  int _turn = 0;

  /// Where each module ended, by [_keyOf], to go on from when it is started again.
  final _kept = <String, int>{};

  /// Ends a pause that has lasted [restAfter].
  Timer? _rest;

  static String _keyOf(String module, Track track) => '${track.name}/$module';

  /// The part the module [module] of [track] goes on from when started, null for its head; null while it is read.
  int? keptAt(String module, Track track) => _kept[_keyOf(module, track)];

  /// The parts of the module being read; none while none is.
  List<SpokenPart> get parts => _session?.parts ?? const [];

  /// Whether the phone has a voice for [language]: a module in a language with none has no Listen.
  Future<bool> canSpeak(String language) => _voices[language] ??= _speech.canSpeak(language);

  /// Reads [session] from where it was left, or its head, in place of any module being read, whose place is kept.
  void start(ListenSession session) {
    if (session.parts.isEmpty) return;
    _keep();
    _session = session;
    final from = _kept.remove(_keyOf(session.module, session.track)) ?? 0;
    unawaited(_play(from < session.parts.length ? from : 0));
  }

  void pause() {
    if (state case final ListenOn on when on.playing) {
      _cut();
      _paused(on.index);
    }
  }

  /// Reads the paused part again from its start.
  void resume() {
    if (state case final ListenOn on when !on.playing) unawaited(_play(on.index));
  }

  /// The next part; after the last, the reading stops.
  void next() {
    if (state case ListenOn(:final index, :final playing)) _go(index + 1, playing: playing);
  }

  /// The part before, or the first one again.
  void back() {
    if (state case ListenOn(:final index, :final playing)) _go(index > 0 ? index - 1 : 0, playing: playing);
  }

  /// The next pace of [rates]; a part being read starts again at it.
  void faster() {
    _rate = rates[(rates.indexOf(_rate) + 1) % rates.length];
    switch (state) {
      case ListenOn(:final index, playing: true):
        unawaited(_play(index));
      case ListenOn(:final index, playing: false):
        _paused(index);
      case ListenIdle():
        emit(ListenIdle(rate: _rate));
    }
  }

  /// Ends the reading, its place kept.
  void stop() => _end(keep: true);

  void _end({required bool keep}) {
    final session = _session;
    if (state is! ListenOn || session == null) return;
    _cut();
    if (keep) {
      _keep();
    } else {
      _kept.remove(_keyOf(session.module, session.track));
    }
    _session = null;
    emit(ListenIdle(rate: _rate));
  }

  /// Keeps the place of the module being read, if one is.
  void _keep() {
    final session = _session;
    if (state case ListenOn(:final index) when session != null) _kept[_keyOf(session.module, session.track)] = index;
  }

  /// Paused on part [index], the reading ends after [restAfter] unless something is done.
  void _paused(int index) {
    emit(_on(index, playing: false));
    _rest?.cancel();
    _rest = Timer(restAfter, stop);
  }

  ListenOn _on(int index, {required bool playing}) {
    final session = _session!;
    return ListenOn(
      module: session.module,
      track: session.track,
      title: session.title,
      index: index,
      count: session.parts.length,
      playing: playing,
      rate: _rate,
    );
  }

  void _go(int index, {required bool playing}) {
    // Past the last part, as read to its end: no place kept.
    if (index >= parts.length) return _end(keep: false);
    if (playing) {
      unawaited(_play(index));
    } else {
      _paused(index);
    }
  }

  void _cut() {
    _rest?.cancel();
    _turn++;
    unawaited(_speech.stop());
  }

  /// Hands the phone every part from [from] on at once, so it reads on with the screen off, and follows each as it
  /// starts.
  Future<void> _play(int from) async {
    _rest?.cancel();
    final turn = ++_turn;
    final session = _session!;
    emit(_on(from, playing: true));
    await _speech.stop();
    if (turn != _turn || isClosed) return;
    await _speech.speak(
      [for (final part in session.parts.skip(from)) part.text],
      language: session.language,
      rate: _rate,
      onPart: (index) {
        if (turn == _turn && !isClosed) emit(_on(from + index, playing: true));
      },
    );
    if (turn != _turn || isClosed) return;
    // Read to its end: started again, it reads from its head.
    _kept.remove(_keyOf(session.module, session.track));
    _session = null;
    emit(ListenIdle(rate: _rate));
  }

  @override
  Future<void> close() {
    _cut();
    return super.close();
  }
}

sealed class ListenState extends Equatable {
  const ListenState();
}

/// No module being read: Listen at a module's head, at [rate] when started.
final class ListenIdle extends ListenState {
  const ListenIdle({required this.rate});

  final double rate;

  @override
  List<Object?> get props => [rate];
}

/// Reading part [index] of [count] of [module] on [track], or paused on it; the player stands at the module's foot,
/// and elsewhere a bar over the navigation.
final class ListenOn extends ListenState {
  const ListenOn({
    required this.module,
    required this.track,
    required this.title,
    required this.index,
    required this.count,
    required this.playing,
    required this.rate,
  });

  final String module;
  final Track track;
  final String title;
  final int index;
  final int count;
  final bool playing;
  final double rate;

  /// Whether it is reading the module [key] of [track].
  bool reads(String key, Track track) => module == key && this.track == track;

  @override
  List<Object?> get props => [module, track, title, index, count, playing, rate];
}
