import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/infrastructure/backup/platform_backup_gateway.dart';
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

  test('createWelcomeStore keeps the flag under the support directory, resolved on first use', () async {
    final root = Directory.systemTemp.createTempSync('welcome_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    var calls = 0;
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async {
        calls++;
        return root;
      },
    );

    final store = dependencies.createWelcomeStore();
    expect(store, isA<FlagWelcomeStore>());
    expect(calls, 0);
    expect(await store.seen(), isFalse);
    await store.markSeen();
    expect(await store.seen(), isTrue);
    expect(File('${root.path}/flags/welcome-seen').existsSync(), isTrue);
  });

  test('createTrackStore keeps the choice as flags under the support directory (plan 1L)', () async {
    final root = Directory.systemTemp.createTempSync('track_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createTrackStore();
    expect(store, isA<FlagTrackStore>());
    expect(await store.chosen(), isNull);

    await store.choose(Track.everyone);
    expect(await store.chosen(), Track.everyone);
    expect(await dependencies.createTrackStore().chosen(), Track.everyone, reason: 'kept for the next start');

    await store.choose(Track.engineers);
    expect(await store.chosen(), Track.engineers);
    expect(File('${root.path}/flags/track-chosen').existsSync(), isTrue);
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');
  });

  test('the backup goes through the platform gateway', () {
    const dependencies = AppDependencies(appConfig: AppConfig.test(contentBaseUrl: testContentBaseUrl));

    expect(dependencies.createBackupGateway(), isA<PlatformBackupGateway>());
  });
}
