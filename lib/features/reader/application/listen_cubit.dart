import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/features/reader/domain/speech.dart';
import 'package:ai_engineering_bazaar/features/reader/domain/spoken_parts.dart';

/// A module read aloud by the phone's own voice (plan 15.1), one part at a time: started at its head, paused and
/// played again, a part back or on, at another pace, and stopped. Leaving the module stops it.
///
/// A `Cubit` because every call is atomic; a newer call cuts the reading under way by its turn, not by an event queue.
final class ListenCubit extends Cubit<ListenState> {
  ListenCubit({required this._speech, required this.parts, required this.language}) : super(const ListenChecking());

  /// The paces offered, in the order Speed steps through them; the first is the voice's own.
  static const rates = [1.0, 1.25, 1.5, 0.75];

  final ISpeech _speech;
  final List<SpokenPart> parts;

  /// The module's language, which picks the voice.
  final String language;

  double _rate = rates.first;

  /// The reading under way; a call that starts another or stops it moves the turn on, so the one before ends.
  int _turn = 0;

  /// Asks the phone for a voice in the module's language: none, or nothing to read, and the module has no Listen.
  Future<void> check() async {
    final can = parts.isNotEmpty && await _speech.canSpeak(language);
    if (isClosed) return;
    emit(can ? ListenOff(rate: _rate) : const ListenNone());
  }

  /// Reads from the module's head.
  void start() {
    if (state is ListenOff) unawaited(_play(0));
  }

  void pause() {
    if (state case ListenOn(:final index, playing: true)) {
      _cut();
      emit(ListenOn(index: index, count: parts.length, playing: false, rate: _rate));
    }
  }

  /// Reads the paused part again from its start.
  void resume() {
    if (state case ListenOn(:final index, playing: false)) unawaited(_play(index));
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
        emit(ListenOn(index: index, count: parts.length, playing: false, rate: _rate));
      case ListenOff():
        emit(ListenOff(rate: _rate));
      case ListenChecking() || ListenNone():
        break;
    }
  }

  void stop() {
    if (state is! ListenOn) return;
    _cut();
    emit(ListenOff(rate: _rate));
  }

  void _go(int index, {required bool playing}) {
    if (index >= parts.length) return stop();
    if (playing) {
      unawaited(_play(index));
    } else {
      emit(ListenOn(index: index, count: parts.length, playing: false, rate: _rate));
    }
  }

  void _cut() {
    _turn++;
    unawaited(_speech.stop());
  }

  Future<void> _play(int from) async {
    final turn = ++_turn;
    await _speech.stop();
    for (var index = from; index < parts.length; index++) {
      if (turn != _turn || isClosed) return;
      emit(ListenOn(index: index, count: parts.length, playing: true, rate: _rate));
      await _speech.speak(parts[index].text, language: language, rate: _rate);
    }
    if (turn == _turn && !isClosed) emit(ListenOff(rate: _rate));
  }

  @override
  Future<void> close() {
    _cut();
    return super.close();
  }
}

sealed class ListenState extends Equatable {
  const ListenState();

  @override
  List<Object?> get props => const [];
}

/// Asking the phone for a voice.
final class ListenChecking extends ListenState {
  const ListenChecking();
}

/// No voice for the module's language, or nothing in it to read: no Listen.
final class ListenNone extends ListenState {
  const ListenNone();
}

/// A voice to read with, not reading: Listen at the module's head.
final class ListenOff extends ListenState {
  const ListenOff({required this.rate});

  final double rate;

  @override
  List<Object?> get props => [rate];
}

/// Reading part [index] of [count], or paused on it; the player stands at the page's foot.
final class ListenOn extends ListenState {
  const ListenOn({required this.index, required this.count, required this.playing, required this.rate});

  final int index;
  final int count;
  final bool playing;
  final double rate;

  @override
  List<Object?> get props => [index, count, playing, rate];
}
