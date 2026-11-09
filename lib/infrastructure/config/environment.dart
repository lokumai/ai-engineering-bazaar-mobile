/// This file is used to set the environment
enum Environment { dev, prod, test }

final class AppConfig {
  const AppConfig({required this.environment, this.sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN')});

  const AppConfig.dev() : environment = Environment.dev, sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN');

  const AppConfig.test() : environment = Environment.test, sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN');

  const AppConfig.prod() : environment = Environment.prod, sentryDsnDefine = const String.fromEnvironment('SENTRY_DSN');

  factory AppConfig.fromEnvironment(Environment environment) => switch (environment) {
    Environment.dev => const AppConfig.dev(),
    Environment.prod => const AppConfig.prod(),
    Environment.test => const AppConfig.test(),
  };

  final Environment environment;

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
  AppConfig withoutSentry() => AppConfig(environment: environment, sentryDsnDefine: '');
}
