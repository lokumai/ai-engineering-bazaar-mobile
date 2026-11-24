import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// The phone's own speech engine (plan 15.1) on `dev.lokumai.bazaar/speech`, which `Speech.kt` (Android's
/// TextToSpeech) and `AppDelegate.swift` (iOS's AVSpeechSynthesizer) answer: the app's own channel, as no speech
/// plugin ships a Swift package and iOS takes no CocoaPods. Every voice is the phone's; nothing leaves it.
///
/// A speak hands the phone every text at once, in the best voice it has for the language, so it reads on with the
/// screen off (the owner, 2026-11-18). It carries an id, which the native side names back in `part` with the place of
/// each text as it starts, and in `done` once the last is said, or they are cut or failed, so the end of words cut by a
/// stop is never taken for the end of the words after them. A call that fails is logged and reads as no voice, or as
/// said.
final class PhoneSpeech {
  PhoneSpeech([this._channel = const MethodChannel(name)]) {
    _channel.setMethodCallHandler(_heard);
  }

  /// The channel's name on both native sides.
  static const name = 'dev.lokumai.bazaar/speech';

  /// The tag each content language is spoken in.
  static const tags = {'en': 'en-US', 'tr': 'tr-TR', 'fa': 'fa-IR'};

  static final _log = AppLogger.getLogger('PhoneSpeech');

  final MethodChannel _channel;

  /// The words being said, by id, each completed once they end, with where each text's start is told.
  final _saying = <int, (Completer<void>, void Function(int index))>{};
  int _lastId = 0;

  final _interruptions = StreamController<void>.broadcast();
  final _resumes = StreamController<void>.broadcast();

  /// Each time the phone stopped the reading itself (`interrupted`, plan 18.3): another app took the sound, as a call
  /// does; or the reader pressed Pause on the lock screen, the notice or the headphones (`control` `pause`, plan 19.8).
  Stream<void> get interruptions => _interruptions.stream;

  /// Each time the reader pressed Play on the lock screen or the headphones (`control` `play`, plan 19.8).
  Stream<void> get resumes => _resumes.stream;

  Future<void> _heard(MethodCall call) async {
    switch (call) {
      case MethodCall(method: 'done', arguments: final int id):
        _end(id);
      case MethodCall(method: 'part', arguments: {'id': final int id, 'index': final int index}):
        _saying[id]?.$2(index);
      case MethodCall(method: 'interrupted', arguments: final int id) when _saying.containsKey(id):
        _interruptions.add(null);
      case MethodCall(method: 'control', arguments: 'pause'):
        _interruptions.add(null);
      case MethodCall(method: 'control', arguments: 'play'):
        _resumes.add(null);
      default:
        break;
    }
  }

  void _end(int id) {
    final saying = _saying.remove(id)?.$1;
    if (saying != null && !saying.isCompleted) saying.complete();
  }

  /// Whether the phone has a voice for [language], the content's code.
  Future<bool> canSpeak(String language) async {
    try {
      return await _channel.invokeMethod<bool>('canSpeak', {'language': language, 'tag': tags[language] ?? language}) ??
          false;
    } on PlatformException catch (error) {
      _log.warn('no voice for {}: {}', [language, error.code]);
      return false;
    } on MissingPluginException {
      _log.debug('no speech channel on this platform');
      return false;
    }
  }

  /// Says [texts] one after another in [language] at [rate] times the voice's pace, telling [onPart] the place of each
  /// as it starts; completes once the last is said, or they are stopped or failed. The native side cuts any words still
  /// being said.
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
    String? noticeLanguage,
  }) async {
    final id = ++_lastId;
    final saying = Completer<void>();
    _saying[id] = (saying, onPart);
    try {
      final started = await _channel.invokeMethod<bool>('speak', {
        'id': id,
        'texts': texts,
        'tag': tags[language] ?? language,
        'rate': engineRate(rate, defaultTargetPlatform),
        'title': title,
        'interface': ?noticeLanguage,
      });
      if (started != true) _end(id);
    } on PlatformException catch (error) {
      _log.warn('speech not started: {}', [error.code]);
      _end(id);
    } on MissingPluginException {
      _end(id);
    }
    return saying.future;
  }

  /// Shows the reading on the phone's lock screen and to the headphones' buttons, [title] and whether it is [playing],
  /// or nothing when [title] is null (plan 19.8). A phone that cannot show it shows nothing.
  Future<void> show({String? title, bool playing = false}) async {
    try {
      await _channel.invokeMethod<void>('show', title == null ? null : {'title': title, 'playing': playing});
    } on PlatformException catch (error) {
      _log.warn('reading not shown: {}', [error.code]);
    } on MissingPluginException {
      // Nothing to show it on.
    }
  }

  /// Stops what is being said; every word asked for ends.
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      _log.warn('speech not stopped: {}', [error.code]);
    } on MissingPluginException {
      // Nothing is said without the channel.
    }
    for (final id in [..._saying.keys]) {
      _end(id);
    }
  }

  /// The engine's rate for [rate], a step of the player's paces: iOS's AVSpeechUtterance takes 0.5 as the voice's pace
  /// and rises much faster, so its steps are a quarter as large; Android's TextToSpeech takes a plain multiple, given
  /// here as the pace iOS reads each step at, so both phones read alike (plan 18.13).
  @visibleForTesting
  static double engineRate(double rate, TargetPlatform platform) {
    final ios = 0.5 + (rate - 1) / 4;
    if (platform == TargetPlatform.iOS) return ios;
    return androidPace(rate);
  }

  /// The pace iOS reads each of the player's steps at, measured on Apple's voices in English and Turkish
  /// (2026-11-19: the same text read at 0.4375, 0.5, 0.5625 and 0.625 took 0.91, 1, 1.35 and 1.71 of the time at 0.5,
  /// inverted), as the multiple Android's engine takes.
  @visibleForTesting
  static double androidPace(double rate) => switch (rate) {
    0.75 => 0.91,
    1.25 => 1.35,
    1.5 => 1.71,
    _ => rate,
  };
}
