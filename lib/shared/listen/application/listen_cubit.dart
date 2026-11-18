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
/// A `Cubit` because every call is atomic; a newer call cuts the reading under way by its turn, not by an event queue.
final class ListenCubit extends Cubit<ListenState> {
  ListenCubit({required this._speech}) : super(const ListenIdle(rate: 1));

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

  /// The parts of the module being read; none while none is.
  List<SpokenPart> get parts => _session?.parts ?? const [];

  /// Whether the phone has a voice for [language]: a module in a language with none has no Listen.
  Future<bool> canSpeak(String language) => _voices[language] ??= _speech.canSpeak(language);

  /// Reads [session] from its head, in place of any module being read.
  void start(ListenSession session) {
    if (session.parts.isEmpty) return;
    _session = session;
    unawaited(_play(0));
  }

  void pause() {
    if (state case final ListenOn on when on.playing) {
      _cut();
      emit(_on(on.index, playing: false));
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
        emit(_on(index, playing: false));
      case ListenIdle():
        emit(ListenIdle(rate: _rate));
    }
  }

  void stop() {
    if (state is! ListenOn) return;
    _cut();
    _session = null;
    emit(ListenIdle(rate: _rate));
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
    if (index >= parts.length) return stop();
    if (playing) {
      unawaited(_play(index));
    } else {
      emit(_on(index, playing: false));
    }
  }

  void _cut() {
    _turn++;
    unawaited(_speech.stop());
  }

  /// Hands the phone every part from [from] on at once, so it reads on with the screen off, and follows each as it
  /// starts.
  Future<void> _play(int from) async {
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
