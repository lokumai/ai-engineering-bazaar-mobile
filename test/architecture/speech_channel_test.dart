import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/speech/phone_speech.dart';
import 'package:flutter_test/flutter_test.dart';

/// The phone's voice, which reads a module aloud (plan 15.1), is the app's own channel on both native sides: no speech
/// plugin ships a Swift package, and iOS takes no CocoaPods (`platform_folders_test`). Each side answers every method
/// the Dart side calls, on the channel it names, names each text's start back in `part` and each speak's id in `done`,
/// and picks the best voice installed; iOS reads on with the screen off (the owner, 2026-11-18).
void main() {
  String read(String path) => File(path).readAsStringSync();
  const methods = ['canSpeak', 'speak', 'stop'];

  test('Android answers on the channel, starts with the engine and shuts down with it', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    expect(speech, contains('const val CHANNEL = "${PhoneSpeech.name}"'));
    for (final method in methods) {
      expect(speech, contains('"$method" ->'), reason: method);
    }
    expect(speech, contains('channel.invokeMethod("done", id)'));
    expect(speech, contains('channel.invokeMethod("part", mapOf("id" to id, "index" to index))'));
    expect(speech, contains('TextToSpeech.QUEUE_ADD'), reason: 'every part queued with the engine');
    expect(speech, contains('pickVoice(tts, locale)'));
    final activity = read('android/app/src/main/kotlin/dev/lokumai/bazaar/MainActivity.kt');
    expect(activity, contains('Speech(this, flutterEngine.dartExecutor.binaryMessenger)'));
    expect(activity, contains('speech?.close()'));
  });

  test("Android 11 and later show the app the phone's speech engine", () {
    expect(
      read('android/app/src/main/AndroidManifest.xml'),
      contains('<action android:name="android.intent.action.TTS_SERVICE"/>'),
    );
  });

  test('iOS answers on the channel with AVSpeechSynthesizer', () {
    final swift = read('ios/Runner/AppDelegate.swift');
    expect(swift, contains('static let channel = "${PhoneSpeech.name}"'));
    for (final method in methods) {
      expect(swift, contains('case "$method":'), reason: method);
    }
    expect(swift, contains('channel.invokeMethod("done", arguments: id)'));
    expect(swift, contains('channel.invokeMethod("part", arguments: ["id": part.id, "index": part.index])'));
    expect(swift, contains('Speech.bestVoice(for: tag)'));
    expect(swift, contains('speech = Speech(messenger: registrar.messenger())'));
  });

  test('iOS keeps reading with the screen off: the audio background mode', () {
    final plist = read('ios/Runner/Info.plist');
    expect(plist, matches(RegExp(r'<key>UIBackgroundModes</key>\s*<array>\s*<string>audio</string>')));
  });

  test('the tags the Dart side speaks in are the content languages', () {
    expect(PhoneSpeech.tags, {'en': 'en-US', 'tr': 'tr-TR', 'fa': 'fa-IR'});
  });
}
