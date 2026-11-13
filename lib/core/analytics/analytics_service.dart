/// Where the app reports an error it does not stop on.
///
/// The default [LogAnalyticsService] writes it to [AppLogger]; the app sends no analytics. A provider that reports
/// errors implements this interface and replaces the registration in `AppDependencies`.
abstract class IAnalyticsService {
  /// Report a non-fatal error.
  void logError({required Object error, StackTrace? stackTrace, String? reason});
}
