/// This file is used to set the environment
enum Environment { dev, prod, test }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.contentBaseUrl,
    this.sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN'),
  });

  /// `main_local`: the base comes from `--dart-define=CONTENT_BASE_URL=...`, which the bootstrap requires.
  const AppConfig.dev()
    : environment = Environment.dev,
      contentBaseUrl = const String.fromEnvironment('CONTENT_BASE_URL'),
      sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN');

  const AppConfig.test({required this.contentBaseUrl})
    : environment = Environment.test,
      sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN');

  const AppConfig.prod()
    : environment = Environment.prod,
      contentBaseUrl = 'https://ai-bazaar.lokum.dev/',
      sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN');

  factory AppConfig.fromEnvironment(Environment environment) => switch (environment) {
    Environment.dev => const AppConfig.dev(),
    Environment.prod => const AppConfig.prod(),
    Environment.test => throw ArgumentError('AppConfig.test needs an explicit contentBaseUrl'),
  };

  final Environment environment;

  /// The site the content is read from: an https address ending in a slash, to which site paths are appended
  /// (spec 3.4.7, 3.7).
  final String contentBaseUrl;

  /// The `--dart-define=SENTRY_DSN=...` value, empty when it is absent.
  /// [sentryDsn] reads it in the prod environment only.
  final String sentryDsnDefine;

  bool get isProduction => environment == Environment.prod;
  bool get isDevelopment => environment == Environment.dev;
  bool get isTest => environment == Environment.test;

  /// Production-only DSN passed via `--dart-define=SENTRY_DSN=...`.
  /// Returns null in non-prod, or when the define is absent / empty.
  /// **Never** commit a DSN to source (public template).
  String? get sentryDsn {
    if (!isProduction) return null;
    return sentryDsnDefine.isEmpty ? null : sentryDsnDefine;
  }

  /// This config without a Sentry DSN, for a run that must behave exactly
  /// as one without the define: no Sentry SDK and the log-only analytics.
  AppConfig withoutSentry() => AppConfig(environment: environment, contentBaseUrl: contentBaseUrl, sentryDsnDefine: '');
}
