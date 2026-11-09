import 'dart:io';

import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/content_fixture.dart';

void main() {
  test('defaults to the dev config', () {
    expect(const AppDependencies().appConfig.environment, Environment.dev);
  });

  test('logs analytics on the device even with a Sentry DSN', () {
    const dependencies = AppDependencies(
      appConfig: AppConfig(
        environment: Environment.prod,
        contentBaseUrl: testContentBaseUrl,
        sentryDsnDefine: 'https://public@example.invalid/1',
      ),
    );

    expect(dependencies.createAnalyticsService(), isA<LogAnalyticsService>());
  });

  test('createContentRepository builds the file repository and resolves no directory yet', () {
    var calls = 0;
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      cacheDirectory: () async {
        calls++;
        return Directory.systemTemp;
      },
    );

    expect(dependencies.createContentRepository(), isA<FileContentRepository>());
    expect(calls, 0);
  });

  test('createRecordRepository builds the file repository and resolves no directory yet', () {
    var calls = 0;
    Future<Directory> counting() async {
      calls++;
      return Directory.systemTemp;
    }

    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: counting,
    );

    expect(dependencies.createRecordRepository(), isA<FileRecordRepository>());
    expect(calls, 0);
  });
}
