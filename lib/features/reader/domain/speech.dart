/// The phone's own speech engine, which reads a module aloud (plan 15.1): offline, nothing leaves the phone.
abstract interface class ISpeech {
  /// Whether the phone has a voice for [language], the content's code (`en`, `tr`, `fa`).
  Future<bool> canSpeak(String language);

  /// Says [text] in [language] at [rate], 1 the voice's own pace; completes once it is said, stopped or failed.
  Future<void> speak(String text, {required String language, required double rate});

  /// Stops what is being said.
  Future<void> stop();
}

/// No voice at all: where the app has no speech engine, as in tests, a module has no Listen.
final class NoSpeech implements ISpeech {
  const NoSpeech();

  @override
  Future<bool> canSpeak(String language) async => false;

  @override
  Future<void> speak(String text, {required String language, required double rate}) async {}

  @override
  Future<void> stop() async {}
}
