import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the dev config', () {
    expect(const AppDependencies().appConfig.environment, Environment.dev);
  });

  test('logs analytics on the device even with a Sentry DSN', () {
    const dependencies = AppDependencies(
      appConfig: AppConfig(
        environment: Environment.prod,
        apiBaseUrl: null,
        certificatePins: [],
        idleTimeout: null,
        sentryDsnDefine: 'https://public@example.invalid/1',
      ),
    );

    expect(dependencies.createAnalyticsService(), isA<LogAnalyticsService>());
  });
}
