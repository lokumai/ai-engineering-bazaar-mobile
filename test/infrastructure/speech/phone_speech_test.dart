import 'dart:async';

import 'package:ai_engineering_bazaar/infrastructure/speech/phone_speech.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const _channel = MethodChannel(PhoneSpeech.name);

final _messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// The native side calling [method] with [arguments].
Future<void> _native(String method, Object? arguments) async {
  await _messenger.handlePlatformMessage(
    _channel.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );
}

/// The native side naming the words with [id] as done.
Future<void> _done(int id) => _native('done', id);

void _none(int index) {}

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late List<MethodCall> calls;

  /// A native side with voices for [voices], which starts every speak unless [starts] is false.
  void native({Set<String> voices = const {}, bool starts = true, bool fails = false}) {
    calls = [];
    _messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (fails) throw PlatformException(code: 'engine');
      return switch (call.method) {
        'canSpeak' => voices.contains((call.arguments as Map)['language']),
        'speak' => starts,
        _ => null,
      };
    });
    addTearDown(() => _messenger.setMockMethodCallHandler(_channel, null));
  }

  group('PhoneSpeech (plan 15.1)', () {
    test("asks the phone for a voice by the content's language and its tag", () async {
      native(voices: const {'tr'});
      final speech = PhoneSpeech();
      expect(await speech.canSpeak('tr'), isTrue);
      expect(await speech.canSpeak('fa'), isFalse);
      expect(calls.last.arguments, {'language': 'fa', 'tag': 'fa-IR'});
    });

    test('a failing engine, or none, has no voice, and its words end at once', () async {
      native(fails: true);
      expect(await PhoneSpeech().canSpeak('en'), isFalse);
      await expectLater(PhoneSpeech().speak(['Hello.'], language: 'en', rate: 1, onPart: _none), completes);
      await expectLater(PhoneSpeech().stop(), completes);

      _messenger.setMockMethodCallHandler(_channel, null);
      expect(await PhoneSpeech().canSpeak('en'), isFalse);
      await expectLater(PhoneSpeech().speak(['Hello.'], language: 'en', rate: 1, onPart: _none), completes);
      await expectLater(PhoneSpeech().stop(), completes);
    });

    test('hands the phone every text with an id, follows each start, and ends them when the phone names that id done '
        '(the owner, 2026-11-18)', () async {
      native();
      final speech = PhoneSpeech();
      var firstEnded = false;
      var secondEnded = false;
      final started = <int>[];
      unawaited(speech.speak(['Bir.'], language: 'tr', rate: 1.25, onPart: _none).then((_) => firstEnded = true));
      final second = speech.speak(['İki.', 'Üç.'], language: 'tr', rate: 1.25, onPart: started.add)
        ..then((_) => secondEnded = true);
      await pumpEventQueue();
      expect(calls.last.arguments, {
        'id': 2,
        'texts': ['İki.', 'Üç.'],
        'tag': 'tr-TR',
        'rate': 1.35,
        'title': '',
      });
      await _native('part', {'id': 2, 'index': 1});
      await _native('part', {'id': 1, 'index': 0});
      expect(started, [1], reason: "another speak's start is not this one's");

      await _done(1);
      await pumpEventQueue();
      expect((firstEnded, secondEnded), (true, false), reason: 'the end of the words cut is not the end of these');
      await _done(2);
      await second;
      expect(secondEnded, isTrue);
    });

    test('words the phone does not start end at once', () async {
      native(starts: false);
      await expectLater(PhoneSpeech().speak(['Hello.'], language: 'en', rate: 1, onPart: _none), completes);
    });

    test('a stop ends every word asked for', () async {
      native();
      final speech = PhoneSpeech();
      final saying = speech.speak(['Hello.'], language: 'en', rate: 1, onPart: _none);
      await pumpEventQueue();
      await speech.stop();
      await expectLater(saying, completes);
      expect(calls.last.method, 'stop');
    });

    test('hands the phone the title, which its notice names (plan 18.1)', () async {
      native();
      unawaited(PhoneSpeech().speak(['Hello.'], language: 'en', rate: 1, title: 'Tokens', onPart: _none));
      await pumpEventQueue();
      expect((calls.last.arguments as Map)['title'], 'Tokens');
    });

    test("the phone's own stop of the words being said is an interruption; another's is not (plan 18.3)", () async {
      native();
      final speech = PhoneSpeech();
      var interruptions = 0;
      final listening = speech.interruptions.listen((_) => interruptions++);
      addTearDown(listening.cancel);
      unawaited(speech.speak(['Hello.'], language: 'en', rate: 1, onPart: _none));
      await pumpEventQueue();
      await _native('interrupted', 9);
      await _native('interrupted', 1);
      await pumpEventQueue();
      expect(interruptions, 1);
    });

    test("each engine's rate for a pace: Android's iOS's measured pace, iOS's in quarter steps (plan 18.13)", () {
      expect(PhoneSpeech.engineRate(1, TargetPlatform.android), 1);
      expect(PhoneSpeech.engineRate(0.75, TargetPlatform.android), 0.91);
      expect(PhoneSpeech.engineRate(1.25, TargetPlatform.android), 1.35);
      expect(PhoneSpeech.engineRate(1.5, TargetPlatform.android), 1.71);
      expect(PhoneSpeech.engineRate(1, TargetPlatform.iOS), 0.5);
      expect(PhoneSpeech.engineRate(1.5, TargetPlatform.iOS), 0.625);
      expect(PhoneSpeech.engineRate(0.75, TargetPlatform.iOS), 0.4375);
    });
  });
}
