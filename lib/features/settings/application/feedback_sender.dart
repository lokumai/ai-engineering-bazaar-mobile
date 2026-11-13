/// Sends a problem the reader describes under Report a problem (the owner, 2026-11-13). `AppDependencies` implements
/// it over Sentry's user feedback; Settings shows the page only in a build that sends crash reports.
abstract interface class IFeedbackSender {
  /// Sends [message]; throws when it was not sent.
  Future<void> send(String message);
}
