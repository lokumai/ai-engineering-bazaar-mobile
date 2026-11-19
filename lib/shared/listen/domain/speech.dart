/// The phone's own speech engine, which reads a module aloud (plan 15): offline, nothing leaves the phone.
abstract interface class ISpeech {
  /// Whether the phone has a voice for [language], the content's code (`en`, `tr`, `fa`).
  Future<bool> canSpeak(String language);

  /// Says [texts] one after another in [language] at [rate], 1 the voice's own pace, in the best voice the phone has
  /// for it, telling [onPart] the place in [texts] of each as it starts. The phone holds them all, so they go on with
  /// the screen off (the owner, 2026-11-18). Completes once the last is said, or they are stopped, or fail.
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
  });

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
  }) async {}

  @override
  Future<void> stop() async {}
}
