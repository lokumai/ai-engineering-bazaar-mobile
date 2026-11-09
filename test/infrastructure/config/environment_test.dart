import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('each named config sets its environment', () {
      expect(const AppConfig.dev().environment, Environment.dev);
      expect(const AppConfig.test().environment, Environment.test);
      expect(const AppConfig.prod().environment, Environment.prod);
      expect(AppConfig.fromEnvironment(Environment.prod).isProduction, isTrue);
    });

    test('reads the Sentry DSN in prod only, and withoutSentry drops it and keeps the environment', () {
      const dsn = 'https://public@example.invalid/1';
      expect(const AppConfig(environment: Environment.dev, sentryDsnDefine: dsn).sentryDsn, isNull);
      const prod = AppConfig(environment: Environment.prod, sentryDsnDefine: dsn);
      expect(prod.sentryDsn, dsn);
      expect(prod.withoutSentry().sentryDsn, isNull);
      expect(prod.withoutSentry().environment, Environment.prod);
    });
  });
}
