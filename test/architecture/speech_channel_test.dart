import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/speech/phone_speech.dart';
import 'package:flutter_test/flutter_test.dart';

/// The phone's voice, which reads a module aloud (plan 15.1), is the app's own channel on both native sides: no speech
/// plugin ships a Swift package, and iOS takes no CocoaPods (`platform_folders_test`). Each side answers every method
/// the Dart side calls, on the channel it names, names each text's start back in `part` and each speak's id in `done`,
/// and picks the best voice installed; iOS reads on with the screen off (the owner, 2026-11-18).
void main() {
  String read(String path) => File(path).readAsStringSync();
  const methods = ['canSpeak', 'speak', 'stop', 'show'];

  test('Android answers on the channel, starts with the engine and shuts down with it', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    expect(speech, contains('const val CHANNEL = "${PhoneSpeech.name}"'));
    for (final method in methods) {
      expect(speech, contains('"$method" ->'), reason: method);
    }
    expect(speech, contains('channel.invokeMethod("done", id)'));
    expect(speech, contains('channel.invokeMethod("part", mapOf("id" to part.id, "index" to part.index))'));
    expect(speech, contains('TextToSpeech.QUEUE_ADD'), reason: 'every part queued with the engine');
    expect(speech, contains('pickVoice(tts, locale)'));
    final activity = read('android/app/src/main/kotlin/dev/lokumai/bazaar/MainActivity.kt');
    expect(activity, contains('Speech(this, flutterEngine.dartExecutor.binaryMessenger)'));
    expect(activity, contains('speech?.close()'));
  });

  test('Android reads on in the background and makes way for a call, as iOS does (plan 18.1, 18.3, 18.4, 18.13)', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    expect(speech, contains('ListenService.start(context, title)'));
    expect(speech, contains('ListenService.stop(context)'));
    expect(
      speech,
      contains('AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK'),
      reason: "other sound lowered, as iOS's",
    );
    expect(speech, contains('channel.invokeMethod("interrupted", id)'));
    expect(speech, contains('TextToSpeech.getMaxSpeechInputLength()'), reason: 'a long text said in pieces');
    expect(speech, contains('tts.playSilentUtterance(GAP_MS'), reason: "iOS's pause after each text");
    expect(read('lib/infrastructure/speech/phone_speech.dart'), contains("method: 'interrupted'"));

    final manifest = read('android/app/src/main/AndroidManifest.xml');
    for (final permission in ['FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MEDIA_PLAYBACK']) {
      expect(manifest, contains('<uses-permission android:name="android.permission.$permission"/>'));
    }
    expect(manifest, contains('android:name=".ListenService"'));
    expect(manifest, contains('android:foregroundServiceType="mediaPlayback"'));
    final service = read('android/app/src/main/kotlin/dev/lokumai/bazaar/ListenService.kt');
    expect(service, contains('ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK'));
    for (final values in ['values', 'values-tr', 'values-fa']) {
      final strings = read('android/app/src/main/res/$values/strings.xml');
      for (final name in ['listen_channel', 'listen_reading', 'listen_pause']) {
        expect(strings, contains('<string name="$name">'), reason: '$values $name');
      }
    }
  });

  test('the lock screen and the headphones reach the player on both phones, and a call pauses it (plan 19.8)', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    expect(speech, contains('MediaSession(context, "Listen")'));
    expect(speech, contains('control("play")'));
    expect(speech, contains('control("pause")'));
    expect(speech, contains('channel.invokeMethod("control", command)'));
    expect(speech, contains('ListenService.session = session.sessionToken'));
    expect(read('android/app/src/main/kotlin/dev/lokumai/bazaar/ListenService.kt'), contains('style.setMediaSession'));

    final swift = read('ios/Runner/AppDelegate.swift');
    expect(swift, contains('AVAudioSession.interruptionNotification'));
    expect(swift, contains('channel.invokeMethod("interrupted", arguments: id)'));
    expect(swift, contains('MPNowPlayingInfoCenter.default().nowPlayingInfo'));
    for (final command in ['playCommand', 'pauseCommand', 'togglePlayPauseCommand']) {
      expect(swift, contains('center.$command.addTarget'), reason: command);
    }
    expect(swift, contains('channel.invokeMethod("control", arguments: command)'));

    final dart = read('lib/infrastructure/speech/phone_speech.dart');
    expect(dart, contains("method: 'control', arguments: 'pause'"));
    expect(dart, contains("method: 'control', arguments: 'play'"));
  });

  test('Android keeps a reading started in the app and says nothing while another app holds the sound '
      '(plan 19.9, 19.10)', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    final speak = speech.indexOf('"speak" ->');
    expect(
      speech.indexOf('ListenService.start(context, title)', speak),
      lessThan(speech.indexOf('whenStarted { tts ->', speak)),
      reason: 'the service starts before the engine answers',
    );
    expect(speech, contains('if (focus != AudioManager.AUDIOFOCUS_REQUEST_GRANTED)'));
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
