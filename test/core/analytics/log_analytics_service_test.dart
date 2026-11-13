import 'package:ai_engineering_bazaar/core/analytics/analytics_service.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogAnalyticsService service;

  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

  setUp(() {
    service = LogAnalyticsService();
  });

  group('LogAnalyticsService', () {
    test('implements IAnalyticsService', () {
      expect(service, isA<IAnalyticsService>());
    });

    group('logError', () {
      test('does not throw with error only', () {
        expect(() => service.logError(error: Exception('test error')), returnsNormally);
      });

      test('does not throw with error and reason', () {
        expect(() => service.logError(error: Exception('test error'), reason: 'network failure'), returnsNormally);
      });

      test('does not throw with error and stackTrace', () {
        final stackTrace = StackTrace.current;
        expect(() => service.logError(error: Exception('test error'), stackTrace: stackTrace), returnsNormally);
      });

      test('does not throw with all parameters', () {
        final stackTrace = StackTrace.current;
        expect(
          () => service.logError(error: Exception('test error'), stackTrace: stackTrace, reason: 'network failure'),
          returnsNormally,
        );
      });

      test('does not throw with string error', () {
        expect(() => service.logError(error: 'simple string error'), returnsNormally);
      });

      test('does not throw with null stackTrace and null reason', () {
        expect(() => service.logError(error: 'error', stackTrace: null, reason: null), returnsNormally);
      });
    });
  });
}
