import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// The phone's own speech engine (plan 15.1) on `dev.lokumai.bazaar/speech`, which `Speech.kt` (Android's
/// TextToSpeech) and `AppDelegate.swift` (iOS's AVSpeechSynthesizer) answer: the app's own channel, as no speech
/// plugin ships a Swift package and iOS takes no CocoaPods. Every voice is the phone's; nothing leaves it.
///
/// Each speak carries an id, which the native side names back in `done` once those words are said, cut or failed, so
/// the end of words cut by a stop is never taken for the end of the words after them. A call that fails is logged and
/// reads as no voice, or as said.
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

  /// The words being said, by id, each completed once they end.
  final _saying = <int, Completer<void>>{};
  int _lastId = 0;

  Future<void> _heard(MethodCall call) async {
    if (call case MethodCall(method: 'done', arguments: final int id)) _end(id);
  }

  void _end(int id) {
    final saying = _saying.remove(id);
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

  /// Says [text] in [language] at [rate] times the voice's pace; completes once it is said, stopped or failed. The
  /// native side cuts any words still being said.
  Future<void> speak(String text, {required String language, required double rate}) async {
    final id = ++_lastId;
    final saying = _saying[id] = Completer<void>();
    try {
      final started = await _channel.invokeMethod<bool>('speak', {
        'id': id,
        'text': text,
        'tag': tags[language] ?? language,
        'rate': engineRate(rate, defaultTargetPlatform),
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

  /// The engine's rate for [rate] times the voice's own pace: Android's TextToSpeech takes the multiple as it is;
  /// iOS's AVSpeechUtterance takes 0.5 as the voice's pace and rises much faster, so its steps are a quarter as large.
  @visibleForTesting
  static double engineRate(double rate, TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? 0.5 + (rate - 1) / 4 : rate;
}
