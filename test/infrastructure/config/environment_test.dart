import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/content_fixture.dart';

void main() {
  group('AppConfig', () {
    test('each named config sets its environment', () {
      expect(const AppConfig.dev().environment, Environment.dev);
      expect(const AppConfig.test(contentBaseUrl: testContentBaseUrl).environment, Environment.test);
      expect(const AppConfig.prod().environment, Environment.prod);
      expect(AppConfig.fromEnvironment(Environment.prod).isProduction, isTrue);
    });

    test('reads the Sentry DSN in prod only, and withoutSentry drops it and keeps the environment and the base', () {
      const dsn = 'https://public@example.invalid/1';
      expect(
        const AppConfig(
          environment: Environment.dev,
          contentBaseUrl: testContentBaseUrl,
          sentryDsnDefine: dsn,
        ).sentryDsn,
        isNull,
      );
      const prod = AppConfig(environment: Environment.prod, contentBaseUrl: testContentBaseUrl, sentryDsnDefine: dsn);
      expect(prod.sentryDsn, dsn);
      expect(prod.withoutSentry().sentryDsn, isNull);
      expect(prod.withoutSentry().environment, Environment.prod);
      expect(prod.withoutSentry().contentBaseUrl, testContentBaseUrl);
    });

    test(
      'prod reads content from the site',
      () => expect(const AppConfig.prod().contentBaseUrl, 'https://ai-bazaar.lokum.dev/'),
    );

    test(
      'test config takes an explicit base',
      () => expect(const AppConfig.test(contentBaseUrl: testContentBaseUrl).contentBaseUrl, testContentBaseUrl),
    );

    test('dev reads the define, empty under flutter test', () => expect(const AppConfig.dev().contentBaseUrl, ''));

    // AppConfig.test needs an explicit base, which fromEnvironment cannot give.
    test(
      'fromEnvironment(test) has no base to give',
      () => expect(() => AppConfig.fromEnvironment(Environment.test), throwsArgumentError),
    );
  });
}
