import 'dart:async';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/listen_place.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/spoken_parts.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone that is handed every text of a speak at once, and reads them as the test moves it on with [reach] and
/// [finish], or a stop cuts them.
final class _Voice implements ISpeech {
  _Voice({this.speaks = true});

  final bool speaks;

  /// Each speak's texts, language and rate, and its title.
  final handed = <(List<String>, String, double)>[];
  final titles = <String>[];

  /// The phone's own stops: another app took the sound, or Pause on its notice.
  final interrupted = StreamController<void>.broadcast();
  final resumed = StreamController<void>.broadcast();

  /// What the phone was asked to show, in order.
  final shown = <ShownReading?>[];
  int stops = 0;
  int asked = 0;
  Completer<void>? _saying;
  void Function(int index)? _onPart;

  /// The phone starts the text at [index] of the last speak.
  void reach(int index) => _onPart?.call(index);

  /// The phone has said the last text.
  void finish() {
    final saying = _saying;
    _saying = null;
    saying?.complete();
  }

  @override
  Future<bool> canSpeak(String language) async {
    asked++;
    return speaks;
  }

  @override
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
  }) {
    handed.add((texts, language, rate));
    titles.add(title);
    _onPart = onPart;
    return (_saying = Completer<void>()).future;
  }

  @override
  Stream<void> get interruptions => interrupted.stream;

  @override
  Stream<void> get resumes => resumed.stream;

  @override
  Future<void> show(ShownReading? reading) async => shown.add(reading);

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

const _first = ListenSession(
  module: 'alpha/first',
  track: Track.engineers,
  title: 'First',
  language: 'tr',
  parts: _parts,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Voice voice;
  late ListenCubit listen;

  late MemoryListenPlaceStore store;

  void make({
    bool speaks = true,
    Duration restAfter = const Duration(minutes: 2),
    Map<String, ListenPlace> kept = const {},
  }) {
    voice = _Voice(speaks: speaks);
    store = MemoryListenPlaceStore(kept);
    listen = ListenCubit(speech: voice, store: store, restAfter: restAfter);
    addTearDown(listen.close);
  }

  ListenOn on(int index, {bool playing = true, double rate = 1, ListenSession session = _first}) => ListenOn(
    module: session.module,
    track: session.track,
    title: session.title,
    index: index,
    count: session.parts.length,
    playing: playing,
    rate: rate,
  );

  group('ListenCubit (plan 15)', () {
    test('asks the phone for a language once', () async {
      make(speaks: false);
      expect(await listen.canSpeak('fa'), isFalse);
      expect(await listen.canSpeak('fa'), isFalse);
      expect(voice.asked, 1);
    });

    test('started, it hands the phone every part at once and follows each as it starts, then is idle', () async {
      make();
      expect(listen.state, const ListenIdle(rate: 1));

      listen.start(_first);
      await _settle();
      expect(listen.state, on(0));
      expect(voice.handed.single.$1, ['One.', 'Two.', 'Three.'], reason: 'all at once: on with the screen off');
      expect((voice.handed.single.$2, voice.handed.single.$3), ('tr', 1.0));

      voice.reach(1);
      expect(listen.state, on(1));
      voice.reach(2);
      voice.finish();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1));
      expect(listen.parts, isEmpty);
    });

    test('paused, it stops the voice and stays on its part; played, it hands the phone the rest from there', () async {
      make();
      listen.start(_first);
      await _settle();
      voice.reach(1);
      listen.pause();
      await _settle();
      expect(listen.state, on(1, playing: false));

      listen.resume();
      await _settle();
      expect(listen.state, on(1));
      expect(voice.handed.last.$1, ['Two.', 'Three.']);
      voice.reach(1);
      expect(listen.state, on(2), reason: "the phone's place counts from where it was handed the rest");
    });

    test("the phone's own stop, a call or the notice's Pause, pauses on the part; the title names the notice "
        '(plan 18.1, 18.3)', () async {
      make();
      listen.start(_first);
      await _settle();
      expect(voice.titles.single, 'First');
      voice.reach(1);
      voice.interrupted.add(null);
      await _settle();
      expect(listen.state, on(1, playing: false));
    });

    test('the phone shows the reading while there is one, and Play there goes on from the part (plan 19.8)', () async {
      make();
      listen.start(_first);
      await _settle();
      voice.reach(1);
      voice.interrupted.add(null);
      await _settle();
      expect(listen.state, on(1, playing: false));
      voice.resumed.add(null);
      await _settle();
      expect(listen.state, on(1));
      expect(voice.handed.last.$1, ['Two.', 'Three.']);
      listen.stop();
      await _settle();
      expect(voice.shown, [
        (title: 'First', playing: true),
        (title: 'First', playing: false),
        (title: 'First', playing: true),
        null,
      ]);
    });

    test('next and back move a part, playing or paused; next after the last stops', () async {
      make();
      listen.start(_first);
      await _settle();
      listen.next();
      await _settle();
      expect(listen.state, on(1));
      expect(voice.handed.last.$1, ['Two.', 'Three.']);

      listen
        ..pause()
        ..back();
      await _settle();
      expect(listen.state, on(0, playing: false));
      listen.back();
      expect(listen.state, on(0, playing: false), reason: 'the first part is as far back as it goes');

      listen
        ..next()
        ..next()
        ..next();
      expect(listen.state, const ListenIdle(rate: 1));
    });

    test('Speed steps through the paces and hands the phone the part again at the new one', () async {
      make();
      listen.faster();
      expect(listen.state, const ListenIdle(rate: 1.25));
      listen.start(_first);
      await _settle();
      expect(voice.handed.last.$3, 1.25);

      listen.faster();
      await _settle();
      expect(listen.state, on(0, rate: 1.5));
      expect(voice.handed.last.$1, ['One.', 'Two.', 'Three.']);
      expect(voice.handed.last.$3, 1.5);
      listen
        ..faster()
        ..faster();
      await _settle();
      expect((listen.state as ListenOn).rate, 1, reason: "round to the voice's own pace");
    });

    test('another module started takes the place of the one being read (the owner, 2026-11-18)', () async {
      make();
      listen.start(_first);
      await _settle();
      const second = ListenSession(
        module: 'alpha/second',
        track: Track.engineers,
        title: 'Second',
        language: 'en',
        parts: [SpokenPart(block: 0, text: 'Hello.')],
      );
      listen.start(second);
      await _settle();
      expect(listen.state, on(0, session: second));
      expect((listen.state as ListenOn).reads('alpha/second', Track.engineers), isTrue);
      expect((listen.state as ListenOn).reads('alpha/first', Track.engineers), isFalse);
      voice.finish();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1));
    });

    test('stop ends the reading; closing stops the voice', () async {
      make();
      listen.start(_first);
      await _settle();
      listen.stop();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1));
      expect(voice.handed, hasLength(1));

      listen.start(_first);
      await _settle();
      final stops = voice.stops;
      await listen.close();
      expect(voice.stops, greaterThan(stops));
    });

    test('stopped, a module keeps its place, and started again goes on from it (the owner, 2026-11-18)', () async {
      make();
      listen.start(_first);
      await _settle();
      voice.reach(1);
      listen.stop();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1));
      expect(listen.keptAt('alpha/first', Track.engineers), 1);
      expect(listen.keptAt('alpha/first', Track.everyone), isNull, reason: 'its own track');

      listen.start(_first);
      await _settle();
      expect(listen.state, on(1));
      expect(voice.handed.last.$1, ['Two.', 'Three.']);
      expect(listen.keptAt('alpha/first', Track.engineers), isNull, reason: 'while it is read');
    });

    test('a pause left alone ends the reading, its place kept; anything done holds it off', () async {
      make(restAfter: const Duration(milliseconds: 40));
      listen.start(_first);
      await _settle();
      voice.reach(2);
      listen.pause();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      listen.back();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(listen.state, on(1, playing: false), reason: 'Back started the wait again');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(listen.state, const ListenIdle(rate: 1), reason: 'the bar leaves and the band is back');
      expect(listen.keptAt('alpha/first', Track.engineers), 1);

      listen.start(_first);
      await _settle();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(listen.state, on(1), reason: 'playing, nothing ends it');
    });

    test('another module started keeps the place of the one put aside', () async {
      make();
      listen.start(_first);
      await _settle();
      voice.reach(2);
      listen.start(
        const ListenSession(
          module: 'alpha/second',
          track: Track.engineers,
          title: 'Second',
          language: 'en',
          parts: [SpokenPart(block: 0, text: 'Hello.')],
        ),
      );
      await _settle();
      expect(listen.keptAt('alpha/first', Track.engineers), 2);
    });

    test('read to its end, or past its last part, a module keeps no place', () async {
      make();
      listen.start(_first);
      await _settle();
      voice.reach(2);
      voice.finish();
      await _settle();
      expect(listen.keptAt('alpha/first', Track.engineers), isNull);

      listen.start(_first);
      await _settle();
      listen
        ..next()
        ..next()
        ..next();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1));
      expect(listen.keptAt('alpha/first', Track.engineers), isNull);
    });

    test('every part heard to its end, the reading ends naming the module heard whole', () async {
      make();
      listen.start(_first);
      await _settle();
      voice
        ..reach(0)
        ..reach(1)
        ..reach(2)
        ..finish();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1, heardAll: (module: 'alpha/first', track: Track.engineers)));
      expect(store.kept, isEmpty, reason: 'heard whole, nothing is kept of it');
    });

    test('a part skipped with Next is not heard; heard over two sittings, it is whole', () async {
      make();
      listen.start(_first);
      await _settle();
      listen.next();
      await _settle();
      voice
        ..reach(0)
        ..reach(1)
        ..finish();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1), reason: 'the first part was skipped');
      expect(store.kept['engineers/alpha/first'], const ListenPlace(count: 3, heard: {1, 2}));

      listen.start(_first);
      await _settle();
      voice
        ..reach(0)
        ..reach(1);
      listen.stop();
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1), reason: 'stopped: not heard whole yet');
      expect(store.kept['engineers/alpha/first'], const ListenPlace(count: 3, index: 1, heard: {0, 1, 2}));

      listen.start(_first);
      await _settle();
      listen
        ..next()
        ..next();
      await _settle();
      expect((listen.state as ListenIdle).heardAll, (
        module: 'alpha/first',
        track: Track.engineers,
      ), reason: 'past the last part, every one heard before');
    });

    test('the places are read from the store and kept in it, so they last when the app is closed', () async {
      make(kept: {'engineers/alpha/first': const ListenPlace(count: 3, index: 2)});
      expect(listen.keptAt('alpha/first', Track.engineers), isNull, reason: 'not read yet');
      await listen.load();
      expect(listen.keptAt('alpha/first', Track.engineers), 2);
      expect(listen.state, const ListenIdle(rate: 1, loaded: true), reason: "the module's Listen hears of them");

      listen.start(_first);
      await _settle();
      expect(listen.state, on(2));
      listen.stop();
      await _settle();
      expect(store.kept['engineers/alpha/first']?.index, 2);
    });

    test('a place kept for a module of another length starts it from its head', () async {
      make(
        kept: {
          'engineers/alpha/first': const ListenPlace(count: 5, index: 4, heard: {0, 1, 2, 3}),
        },
      );
      await listen.load();
      listen.start(_first);
      await _settle();
      expect(listen.state, on(0));
    });

    test('a module with nothing to read does not start', () async {
      make();
      listen.start(const ListenSession(module: 'a/b', track: Track.engineers, title: 'B', language: 'en', parts: []));
      await _settle();
      expect(listen.state, const ListenIdle(rate: 1));
      expect(voice.handed, isEmpty);
    });
  });
}
