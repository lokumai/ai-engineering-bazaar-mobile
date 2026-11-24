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
      contains('AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)'),
      reason: 'other sound pauses while it reads, as on iOS (plan 20.11)',
    );
    expect(speech, isNot(contains('MAY_DUCK')));
    expect(speech, contains('channel.invokeMethod("interrupted", id)'));
    expect(speech, contains('AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->'), reason: 'a short prompt pauses it');
    expect(speech, contains('if (current != null || ducked) return@Runnable'), reason: "the prompt's end comes back");
    expect(speech, contains('current?.let { done(it) }'), reason: 'a stop ends the speak without the engine');
    // Review 4, finding 5: headphones lost during a prompt keep the reading paused, and a prompt's end that Dart does
    // not read on from gives the sound back.
    final noisy = RegExp(r'ACTION_AUDIO_BECOMING_NOISY\) return\s+main\.post \{([^}]*)\}').firstMatch(speech)![1]!;
    expect(noisy, allOf(contains('ducked = false'), contains('interrupt()'), contains('releaseSoon()')));
    final gain = RegExp(r'AUDIOFOCUS_GAIN -> if \(ducked\) \{([\s\S]*?)\n            \}').firstMatch(speech)![1]!;
    expect(gain, allOf(contains('control("play")'), contains('releaseSoon()')));
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
      for (final name in ['listen_channel', 'listen_reading', 'listen_pause', 'listen_play', 'listen_paused']) {
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
    final service = read('android/app/src/main/kotlin/dev/lokumai/bazaar/ListenService.kt');
    expect(service, contains('style.setMediaSession'));
    expect(service, contains('R.string.listen_paused'), reason: 'a paused reading keeps its notice, with Play');
    expect(speech, contains('if (!shown) ListenService.stop(context)'));
    expect(speech, contains('private val onPlay: () -> Unit = { main.post { control("play") } }'));
    expect(speech, contains('ListenService.onPlay = onPlay'));
    // A new activity's callbacks survive the old one's close (review 6, finding 12).
    expect(speech, contains('if (ListenService.onPlay === onPlay) ListenService.onPlay = null'));
    expect(speech, contains('if (ListenService.onPause === onPause) ListenService.onPause = null'));

    final swift = read('ios/Runner/AppDelegate.swift');
    expect(swift, contains('AVAudioSession.interruptionNotification'));
    expect(swift, contains('channel.invokeMethod("interrupted", arguments: id)'));
    expect(swift, contains('MPNowPlayingInfoCenter.default().nowPlayingInfo'));
    for (final command in ['playCommand', 'pauseCommand', 'togglePlayPauseCommand']) {
      expect(swift, contains('center.$command.addTarget'), reason: command);
    }
    expect(swift, contains('channel.invokeMethod("control", arguments: command)'));
    expect(
      swift,
      contains('setCategory(.playback, mode: .spokenAudio, options: [])'),
      reason: 'an app that mixes with other sound is never the one the lock screen shows',
    );

    final dart = read('lib/infrastructure/speech/phone_speech.dart');
    expect(dart, contains("method: 'control', arguments: 'pause'"));
    expect(dart, contains("method: 'control', arguments: 'play'"));
  });

  // Review 7, finding 1: an engine that lost its voice service after an update failed every call while it still
  // counted as started, until the app was closed.
  test('Android builds the engine again when a started one fails', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    expect(speech, contains('(started != TextToSpeech.SUCCESS || suspect) && waiting.isEmpty()'));
    expect(speech, contains('return@whenStarted canSpeak(locale, result, again = false)'));
    expect(speech, contains('return@whenStarted speak(id, texts, locale, rate, result, again = false)'));
    final failed = speech.indexOf('if (!queued) {');
    expect(speech.indexOf('suspect = true', failed), lessThan(speech.indexOf('result.success(queued)', failed)));
  });

  // Review 8, finding 2: a speak waiting for the engine outlived a stop, and was then read with no player.
  test('Android says nothing of a speak a stop came after', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    final stop = speech.indexOf('"stop" -> {');
    expect(speech.indexOf('stoppedThrough = lastAsked', stop), greaterThan(stop));
    expect(speech, contains('lastAsked = id'));
    expect(speech, contains('if (stoppedThrough?.let { id <= it } == true) {'));
    // Review 8, finding 13: no new engine while a reading is on.
    expect(speech, contains('asked > 1 && current == null'));
  });

  test('Android keeps a reading started in the app and says nothing while another app holds the sound '
      '(plan 19.9, 19.10)', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    final speak = speech.indexOf('"speak" ->');
    expect(
      speech.indexOf('ListenService.start(context, title)', speak),
      lessThan(speech.indexOf('speak(id, texts, Locale.forLanguageTag(tag), rate, result, again = true)', speak)),
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

  // Review 8, finding 18: the methods were tied by name, their arguments by hand only. A key renamed on one side reads
  // as missing on the other: a reading that never starts, or one spoken in the wrong voice, with no test failing.
  test('each method reads on each native side only arguments the Dart side sends it, and Dart reads those of part', () {
    final dart = read('lib/infrastructure/speech/phone_speech.dart');
    final sent = {
      for (final call in RegExp(r"_channel\.invokeMethod<\w+>\('(\w+)'([^;]*);").allMatches(dart))
        call[1]!: {...RegExp(r"'(\w+)':").allMatches(call[2]!).map((key) => key[1]!)},
    };
    expect(sent.keys, unorderedEquals(methods));
    expect(sent['speak'], containsAll(['id', 'texts', 'tag', 'rate', 'title', 'interface']));

    /// The keys each method's branch reads, the branches found by [branch] in [text] from [start].
    Map<String, Set<String>> reads(String text, String start, RegExp branch, List<RegExp> keys) {
      final handler = text.substring(text.indexOf(start));
      final branches = branch.allMatches(handler).toList();
      return {
        for (final (i, match) in branches.indexed)
          ?match[1]: {
            for (final key in keys)
              ...key
                  .allMatches(handler.substring(match.end, i + 1 < branches.length ? branches[i + 1].start : null))
                  .map((found) => found[1]!),
          },
      };
    }

    final kotlin = reads(
      read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt'),
      'override fun onMethodCall',
      RegExp(r'\n {12}(?:"(\w+)"|else) ->'),
      [RegExp(r'call\.argument<.+?>\("(\w+)"\)'), RegExp(r'reading\?\.get\("(\w+)"\)')],
    );
    final swift = reads(
      read('ios/Runner/AppDelegate.swift'),
      'private func handle(_ call: FlutterMethodCall, _ result: FlutterResult) {\n    let arguments',
      RegExp(r'\n    (?:case "(\w+)"|default):'),
      [RegExp(r'arguments\["(\w+)"\]'), RegExp(r'reading\?\["(\w+)"\]')],
    );
    for (final (side, branches) in [('Kotlin', kotlin), ('Swift', swift)]) {
      for (final method in methods) {
        expect(branches, contains(method), reason: '$side $method');
        expect(sent[method], containsAll(branches[method]!), reason: '$side $method reads ${branches[method]}');
      }
    }
    expect(kotlin['speak'], containsAll(['id', 'texts', 'tag', 'rate', 'title', 'interface']));
    expect(swift['speak'], containsAll(['id', 'texts', 'tag', 'rate']));
    expect(kotlin['canSpeak'], {'tag'});
    expect(swift['canSpeak'], {'language'});
    expect(kotlin['show'], {'title', 'playing'});
    expect(swift['show'], {'title', 'playing'});

    expect(dart, contains("MethodCall(method: 'part', arguments: {'id': final int id, 'index': final int index})"));
  });

  test('iOS keeps reading with the screen off: the audio background mode', () {
    final plist = read('ios/Runner/Info.plist');
    expect(plist, matches(RegExp(r'<key>UIBackgroundModes</key>\s*<array>\s*<string>audio</string>')));
  });

  test('the tags the Dart side speaks in are the content languages', () {
    expect(PhoneSpeech.tags, {'en': 'en-US', 'tr': 'tr-TR', 'fa': 'fa-IR'});
  });

  test('Listen stops safely, pauses when the headphones go, waits for a call on iOS too (plan 20.1, 20.3, 20.8)', () {
    final speech = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Speech.kt');
    expect(speech, contains('AudioManager.ACTION_AUDIO_BECOMING_NOISY'), reason: 'headphones taken off');
    expect(speech, contains('context.unregisterReceiver(noisy)'));
    expect(speech, contains('main.postDelayed(release, RELEASE_MS)'));
    final service = read('android/app/src/main/kotlin/dev/lokumai/bazaar/ListenService.kt');
    expect(service, contains('if (!starts.stop()) return'), reason: 'a stop before the foreground start waits for it');
    expect(service, contains('Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)'));
    expect(service, isNot(contains('getLaunchIntentForPackage')), reason: 'an icon change turns the old entry off');

    final ios = read('ios/Runner/AppDelegate.swift');
    expect(ios, contains('AVAudioSession.routeChangeNotification'));
    expect(ios, contains('.oldDeviceUnavailable'));
    expect(ios, contains('let active = (try? session.setActive(true)) != nil'));
    expect(ios, contains('connection.videoRotationAngle = angle'), reason: "the scanner's picture turns (plan 20.9)");
  });
}
