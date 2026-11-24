/// The phone's own speech engine, which reads a module aloud (plan 15): offline, nothing leaves the phone.
abstract interface class ISpeech {
  /// Whether the phone has a voice for [language], the content's code (`en`, `tr`, `fa`).
  Future<bool> canSpeak(String language);

  /// Says [texts] one after another in [language] at [rate], 1 the voice's own pace, in the best voice the phone has
  /// for it, telling [onPart] the place in [texts] of each as it starts. The phone holds them all, so they go on with
  /// the screen off (the owner, 2026-11-18); [title], the module's, names the reading where the phone shows it (Android's
  /// notice, plan 18.1). Completes once the last is said, or they are stopped, or fail. [noticeLanguage], the app's own
  /// language, is the one the phone's notice of the reading speaks; null leaves it to the phone (review 5 finding 8).
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
    String? noticeLanguage,
  });

  /// Each time the phone stopped the reading itself: another app took the sound, as a call does, or the reader pressed
  /// Pause where the phone shows the reading, on the lock screen, the notice or the headphones (plan 18.3, 19.8). The
  /// player pauses where it was.
  Stream<void> get interruptions;

  /// Each time the reader pressed Play where the phone shows the reading: the lock screen or the headphones (plan
  /// 19.8). The player goes on from its part.
  Stream<void> get resumes;

  /// What the phone shows of the reading on its lock screen and to the headphones' buttons: the module's [ShownReading]
  /// title and whether it plays, or nothing once the reading ends (plan 19.8).
  Future<void> show(ShownReading? reading);

  /// Stops what is being said, and what waits to be.
  Future<void> stop();
}

/// No voice at all: where the app has no speech engine, as in tests, a module has no Listen.
final class NoSpeech implements ISpeech {
  const NoSpeech();

  @override
  Future<bool> canSpeak(String language) async => false;

  @override
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
    String? noticeLanguage,
  }) async {}

  @override
  Stream<void> get interruptions => const Stream.empty();

  @override
  Stream<void> get resumes => const Stream.empty();

  @override
  Future<void> show(ShownReading? reading) async {}

  @override
  Future<void> stop() async {}
}

/// The reading as the phone shows it (plan 19.8): the module's [title], and whether it [playing] or is paused.
typedef ShownReading = ({String title, bool playing});
