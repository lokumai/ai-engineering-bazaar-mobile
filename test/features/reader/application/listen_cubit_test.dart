import 'dart:async';

import 'package:ai_engineering_bazaar/features/reader/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/features/reader/domain/speech.dart';
import 'package:ai_engineering_bazaar/features/reader/domain/spoken_parts.dart';
import 'package:flutter_test/flutter_test.dart';

/// A voice that says each text until the test ends it with [finish], or a stop cuts it.
final class _Voice implements ISpeech {
  _Voice({this.speaks = true});

  final bool speaks;
  final said = <(String, String, double)>[];
  int stops = 0;
  Completer<void>? _saying;

  void finish() {
    final saying = _saying;
    _saying = null;
    saying?.complete();
  }

  @override
  Future<bool> canSpeak(String language) async => speaks;

  @override
  Future<void> speak(String text, {required String language, required double rate}) {
    said.add((text, language, rate));
    return (_saying = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    finish();
  }
}

const _parts = [
  SpokenPart(block: 0, text: 'One.'),
  SpokenPart(block: 2, text: 'Two.'),
  SpokenPart(block: 5, text: 'Three.'),
];

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Voice voice;
  late ListenCubit listen;

  Future<void> make({bool speaks = true, List<SpokenPart> parts = _parts}) async {
    voice = _Voice(speaks: speaks);
    listen = ListenCubit(speech: voice, parts: parts, language: 'tr');
    addTearDown(listen.close);
    await listen.check();
  }

  ListenOn on(int index, {bool playing = true, double rate = 1}) =>
      ListenOn(index: index, count: _parts.length, playing: playing, rate: rate);

  group('ListenCubit (plan 15.1)', () {
    test('no voice for the language, or nothing to read: no Listen', () async {
      await make(speaks: false);
      expect(listen.state, const ListenNone());
      await make(parts: const []);
      expect(listen.state, const ListenNone());
    });

    test('a voice: Listen; started, it reads each part in turn in the module\'s language, then is off', () async {
      await make();
      expect(listen.state, const ListenOff(rate: 1));

      listen.start();
      await _settle();
      expect(listen.state, on(0));
      expect(voice.said.single, ('One.', 'tr', 1.0));

      voice.finish();
      await _settle();
      expect(listen.state, on(1));
      voice.finish();
      await _settle();
      voice.finish();
      await _settle();
      expect(listen.state, const ListenOff(rate: 1));
      expect(voice.said.map((said) => said.$1), ['One.', 'Two.', 'Three.']);
    });

    test('paused, it stops the voice and stays on its part; played, it reads the part again', () async {
      await make();
      listen.start();
      await _settle();
      listen.pause();
      await _settle();
      expect(listen.state, on(0, playing: false));
      expect(voice.said, hasLength(1), reason: 'the cut part does not lead on to the next');

      listen.resume();
      await _settle();
      expect(listen.state, on(0));
      expect(voice.said.map((said) => said.$1), ['One.', 'One.']);
    });

    test('next and back move a part, playing or paused; next after the last stops', () async {
      await make();
      listen.start();
      await _settle();
      listen.next();
      await _settle();
      expect(listen.state, on(1));
      expect(voice.said.last.$1, 'Two.');

      listen.pause();
      listen.back();
      await _settle();
      expect(listen.state, on(0, playing: false));
      listen.back();
      expect(listen.state, on(0, playing: false), reason: 'the first part is as far back as it goes');

      listen
        ..next()
        ..next()
        ..next();
      expect(listen.state, const ListenOff(rate: 1));
    });

    test('Speed steps through the paces and reads the part again at the new one', () async {
      await make();
      listen.faster();
      expect(listen.state, const ListenOff(rate: 1.25));
      listen.start();
      await _settle();
      expect(voice.said.last.$3, 1.25);

      listen.faster();
      await _settle();
      expect(listen.state, on(0, rate: 1.5));
      expect(voice.said.last, ('One.', 'tr', 1.5));
      listen
        ..faster()
        ..faster();
      await _settle();
      expect((listen.state as ListenOn).rate, 1, reason: 'round to the voice\'s own pace');
    });

    test('stop ends the reading; closing stops the voice', () async {
      await make();
      listen.start();
      await _settle();
      listen.stop();
      await _settle();
      expect(listen.state, const ListenOff(rate: 1));
      expect(voice.said, hasLength(1));

      listen.start();
      await _settle();
      final stops = voice.stops;
      await listen.close();
      expect(voice.stops, greaterThan(stops));
    });
  });
}
