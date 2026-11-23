import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/listen_place.dart';
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
    this.noticeLanguage,
  });

  final String module;
  final Track track;
  final String title;

  /// The module's language, which picks the voice.
  final String language;
  final List<SpokenPart> parts;

  /// The app's own language, which the phone's notice of the reading speaks; null leaves it to the phone.
  final String? noticeLanguage;

  @override
  List<Object?> get props => [module, track, title, language, parts, noticeLanguage];
}

/// The module read aloud by the phone's own voice (plan 15), for the whole app (the owner, 2026-11-18): it goes on
/// with the screen off, and while the reader moves to another tab or module, where a bar over the navigation holds it;
/// back on the module it is where the voice is. Started at a module's head, paused and played again, a part back or
/// on, at another pace, and stopped; another module started takes its place.
///
/// A module stopped, left paused for [restAfter], or put aside for another keeps its place, and started again it goes
/// on from there (the owner, 2026-11-18): the bar over the navigation leaves, the band is back, and the module's Listen
/// says it resumes. Each part heard to its end is kept too, a part skipped with Next is not; once every part is heard,
/// over one sitting or many, the reading ends with [ListenIdle.heardAll], which the app marks completed. Read to its
/// end, the place to go on from is let go. The places are kept in the [IListenPlaceStore], so they last when the app
/// is closed.
///
/// A `Cubit` because every call is atomic; a newer call cuts the reading under way by its turn, not by an event queue.
final class ListenCubit extends Cubit<ListenState> {
  ListenCubit({required this._speech, IListenPlaceStore? store, this.restAfter = const Duration(minutes: 2)})
    : _store = store ?? MemoryListenPlaceStore(),
      super(const ListenIdle(rate: 1)) {
    // The phone stopped the reading itself (a call, or Pause on Android's notice): the player pauses where it was,
    // as the reader's own Pause does (plan 18.3).
    _interruptions = _speech.interruptions.listen((_) => pause());
    // Play on the lock screen or the headphones goes on from the part (plan 19.8).
    _resumes = _speech.resumes.listen((_) => resume());
    // The phone shows the reading on its lock screen and to the headphones' buttons while there is one (plan 19.8).
    _shown = stream
        .map<ShownReading?>(
          (state) => switch (state) {
            ListenOn(:final title, :final playing) => (title: title, playing: playing),
            ListenIdle() => null,
          },
        )
        .distinct()
        .listen((reading) => unawaited(_speech.show(reading)));
  }

  late final StreamSubscription<void> _interruptions;
  late final StreamSubscription<void> _resumes;
  late final StreamSubscription<ShownReading?> _shown;

  /// How long a pause lasts before the reading ends, its place kept.
  final Duration restAfter;

  /// The paces offered, in the order Speed steps through them; the first is the voice's own.
  static const rates = [1.0, 1.25, 1.5, 0.75];

  final ISpeech _speech;
  final IListenPlaceStore _store;

  double _rate = rates.first;

  /// The module being read, or paused; null while none is.
  ListenSession? _session;

  /// The phone's answer for each language: a yes is kept, a no asked again (review 5, finding 9).
  final _voices = <String, Future<bool>>{};

  /// The reading under way; a call that starts another or stops it moves the turn on, so the one before ends.
  int _turn = 0;

  /// Each module's place, by [listenPlaceKey].
  Map<String, ListenPlace> _places = {};

  /// Ends a pause that has lasted [restAfter].
  Timer? _rest;

  /// The places a reset of all progress erased, which its undo brings back (plan 20.7).
  Map<String, ListenPlace>? _erased;

  /// Reads the places kept; a module's Listen asked before it ends sees none.
  Future<void> load() async {
    final kept = await _store.load();
    if (isClosed) return;
    _places = {...kept, ..._places};
    // The module's Listen reads the places as the state changes: one emit for them to be seen.
    if (state case ListenIdle(:final rate)) emit(ListenIdle(rate: rate, loaded: true));
  }

  /// Erases where every module was left and the parts heard, with a reset of all progress (plan 20.7), so a module is
  /// not marked completed by parts heard before it; [again] keeps what the undo of the reset before brings back. A
  /// module being read goes on, its parts heard from now.
  void erase({required bool again}) {
    if (!again || _erased == null) _erased = _places;
    _places = {};
    unawaited(_store.save(_places));
  }

  /// Brings back the places the reset erased, with those kept since on top.
  void undoErase() {
    final erased = _erased;
    if (erased == null) return;
    _erased = null;
    _places = {...erased, ..._places};
    unawaited(_store.save(_places));
  }

  /// The part the module [module] of [track] goes on from when started, null for its head; null while it is read.
  int? keptAt(String module, Track track) {
    if (_session case final session? when session.module == module && session.track == track) return null;
    return _places[listenPlaceKey(module, track)]?.index;
  }

  /// The parts of the module being read; none while none is.
  List<SpokenPart> get parts => _session?.parts ?? const [];

  /// Whether the phone has a voice for [language]: a module in a language with none has no Listen. A no is not kept,
  /// since the reader may add a voice in the phone's settings and come back.
  Future<bool> canSpeak(String language) => _voices[language] ??= _speech.canSpeak(language).then((can) {
    if (!can) unawaited(_voices.remove(language));
    return can;
  });

  /// Reads [session] from where it was left, or its head, in place of any module being read, whose place is kept.
  void start(ListenSession session) {
    if (session.parts.isEmpty) return;
    _keep();
    _session = session;
    final key = listenPlaceKey(session.module, session.track);
    // Kept for a module of another length, the place no longer fits it.
    if (_places[key] case final place? when place.count != session.parts.length) _places.remove(key);
    unawaited(_play(_places[key]?.index ?? 0));
  }

  void pause() {
    if (state case final ListenOn on when on.playing) {
      _cut();
      _paused(on.index);
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
        _paused(index);
      case ListenIdle():
        emit(ListenIdle(rate: _rate));
    }
  }

  /// Ends the reading, its place kept.
  void stop() {
    if (state is! ListenOn || _session == null) return;
    _cut();
    _keep();
    _session = null;
    emit(ListenIdle(rate: _rate));
  }

  /// Keeps where the module being read is, if one is.
  void _keep() {
    final session = _session;
    if (state case ListenOn(:final index) when session != null) _place(session, (place) => place.at(index));
  }

  /// Changes the place of [session]'s module by [change], and keeps every place.
  void _place(ListenSession session, ListenPlace Function(ListenPlace place) change) {
    final key = listenPlaceKey(session.module, session.track);
    final place = change(_places[key] ?? ListenPlace(count: session.parts.length));
    _places = {..._places}..remove(key);
    if (!place.isEmpty) _places[key] = place;
    unawaited(_store.save(_places));
  }

  /// Paused on part [index], the reading ends after [restAfter] unless something is done.
  void _paused(int index) {
    emit(_on(index, playing: false));
    _rest?.cancel();
    _rest = Timer(restAfter, stop);
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
    if (index >= parts.length) return _ended();
    if (playing) {
      unawaited(_play(index));
    } else {
      _paused(index);
    }
  }

  void _cut() {
    _rest?.cancel();
    _turn++;
    unawaited(_speech.stop());
  }

  /// Past the last part: nothing to go on from; and with every part heard, the module was listened to whole, and its
  /// parts heard are let go with it.
  void _ended() {
    final session = _session;
    if (session == null) return;
    _cut();
    final key = listenPlaceKey(session.module, session.track);
    final whole = _places[key]?.heardAll ?? false;
    _place(session, (place) => whole ? const ListenPlace(count: 0) : place.at(null));
    _session = null;
    emit(ListenIdle(rate: _rate, heardAll: whole ? (module: session.module, track: session.track) : null));
  }

  /// Hands the phone every part from [from] on at once, so it reads on with the screen off, and follows each as it
  /// starts. A part counts heard once the next starts after it in the same speak, or the speak ends after it.
  Future<void> _play(int from) async {
    _rest?.cancel();
    final turn = ++_turn;
    final session = _session!;
    emit(_on(from, playing: true));
    await _speech.stop();
    if (turn != _turn || isClosed) return;
    int? started;
    await _speech.speak(
      [for (final part in session.parts.skip(from)) part.text],
      language: session.language,
      rate: _rate,
      title: session.title,
      noticeLanguage: session.noticeLanguage,
      onPart: (index) {
        if (turn != _turn || isClosed) return;
        final at = from + index;
        if (started case final before? when before == at - 1) _place(session, (place) => place.hearing(before));
        started = at;
        emit(_on(at, playing: true));
      },
    );
    if (turn != _turn || isClosed) return;
    // Ended with no part started: the phone's voice refused it or is gone. The place is kept, and the reader told,
    // rather than the player closing without a word and the next Listen starting from the head (review 2 finding 6,
    // review 5 finding 11).
    if (started == null) return _notStarted();
    // Ended before its last part: the phone's voice failed on the way (an engine error, an update). The place is kept
    // at the part it was on, and the reader told, as for a speak that did not start (review 6, finding 2).
    if (started case final at? when at < session.parts.length - 1) {
      _place(session, (place) => place.at(at));
      return _notStarted();
    }
    if (started case final last? when last == session.parts.length - 1) {
      _place(session, (place) => place.hearing(last));
    }
    _ended();
  }

  /// A speak that started no part, or stopped before its last: the reading stops where it was, its place kept.
  void _notStarted() {
    final session = _session;
    if (session == null) return;
    _cut();
    _session = null;
    emit(ListenIdle(rate: _rate, notStarted: (module: session.module, track: session.track)));
  }

  @override
  Future<void> close() {
    _cut();
    unawaited(_interruptions.cancel());
    unawaited(_resumes.cancel());
    unawaited(_shown.cancel());
    unawaited(_speech.show(null));
    return super.close();
  }
}

sealed class ListenState extends Equatable {
  const ListenState();
}

/// No module being read: Listen at a module's head, at [rate] when started. Just after a module was heard whole,
/// [heardAll] names it, once; just after the phone's voice started none of a module, [notStarted] names it, once;
/// [loaded] once the places kept were read.
final class ListenIdle extends ListenState {
  const ListenIdle({required this.rate, this.heardAll, this.notStarted, this.loaded = false});

  final double rate;
  final ({String module, Track track})? heardAll;
  final ({String module, Track track})? notStarted;
  final bool loaded;

  @override
  List<Object?> get props => [rate, heardAll, notStarted, loaded];
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
