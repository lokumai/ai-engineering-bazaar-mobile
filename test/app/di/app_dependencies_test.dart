import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/app_icon/app_icon_channel.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/infrastructure/backup/platform_backup_gateway.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
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
    expect(File('${root.path}/flags/welcome-2-seen').existsSync(), isTrue);
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

  test('createLanguageStore keeps the choice as one flag under the support directory (plan 1Q)', () async {
    final root = Directory.systemTemp.createTempSync('language_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createLanguageStore();
    expect(store, isA<FlagLanguageStore>());
    expect(await store.chosen(), isNull);

    await store.choose('fa');
    expect(await dependencies.createLanguageStore().chosen(), 'fa', reason: 'kept for the next start');

    await store.choose('tr');
    expect(await store.chosen(), 'tr');
    expect(File('${root.path}/flags/language-fa').existsSync(), isFalse, reason: 'one language at a time');
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');
  });

  test('createThemeStore keeps the choice as one flag under the support directory', () async {
    final root = Directory.systemTemp.createTempSync('theme_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createThemeStore();
    expect(store, isA<FlagThemeStore>());
    expect(await store.chosen(), isNull);

    await store.choose(ThemeMode.dark);
    expect(await dependencies.createThemeStore().chosen(), ThemeMode.dark, reason: 'kept for the next start');

    await store.choose(ThemeMode.light);
    expect(await store.chosen(), ThemeMode.light);
    expect(File('${root.path}/flags/theme-dark').existsSync(), isFalse, reason: 'one choice at a time');

    await store.choose(ThemeMode.system);
    expect(await store.chosen(), isNull, reason: 'the phone is no flag at all');
    expect(File('${root.path}/flags/theme-light').existsSync(), isFalse);
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');
  });

  test('createAppIconStore keeps one chosen app icon as a file flag, apart from the record', () async {
    final root = Directory.systemTemp.createTempSync('app_icon_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createAppIconStore();
    expect(store, isA<FlagAppIconStore>());
    expect(await store.chosen(), isNull);

    await store.choose(BazaarIcon.noir);
    expect(await dependencies.createAppIconStore().chosen(), BazaarIcon.noir, reason: 'kept for the next start');

    await store.choose(BazaarIcon.nightSea);
    expect(await store.chosen(), BazaarIcon.nightSea);
    expect(File('${root.path}/flags/app-icon-noir').existsSync(), isFalse, reason: 'one choice at a time');
    expect(File('${root.path}/flags/app-icon-nightSea').existsSync(), isTrue);
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');
  });

  test('createAppIconSwitch names the icon on the native channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(AppIconChannel.name),
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(AppIconChannel.name),
        null,
      ),
    );

    await const AppDependencies().createAppIconSwitch().choose(BazaarIcon.nightGold);

    expect(calls.map((call) => (call.method, call.arguments)), [('choose', 'nightGold')]);
  });

  test('a failed icon change is logged, never thrown', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(AppIconChannel.name),
      (call) async => throw PlatformException(code: 'not-changed'),
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(AppIconChannel.name),
        null,
      ),
    );

    await expectLater(const AppDependencies().createAppIconSwitch().choose(BazaarIcon.ink), completes);
    // No channel at all, as on a desktop or in a test: nothing happens.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(AppIconChannel.name),
      null,
    );
    await expectLater(const AppDependencies().createAppIconSwitch().choose(BazaarIcon.ink), completes);
  });

  test('createQuizScoreStore keeps the scores in one file under the support directory (plan 1W)', () async {
    final root = Directory.systemTemp.createTempSync('quiz_score_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createQuizScoreStore();
    expect(store, isA<FileQuizScoreStore>());
    expect(await store.load(), isEmpty);

    const scores = {'alpha/first': QuizScore(last: 2, best: 3, total: 3)};
    await store.save(scores);
    expect(await dependencies.createQuizScoreStore().load(), scores, reason: 'kept for the next start');
    expect(File('${root.path}/quiz/scores.json').existsSync(), isTrue);
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');

    await store.save(const {});
    expect(File('${root.path}/quiz/scores.json').existsSync(), isFalse, reason: 'no scores, no file');
  });

  test('createPocketModelStore keeps the pocket model in one file under the support directory (plan 9.2)', () async {
    final root = Directory.systemTemp.createTempSync('pocket_model_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createPocketModelStore();
    expect(store, isA<FilePocketModelStore>());
    expect(await store.load(), isNull);

    final model = PocketModel(tokens: 64, lastFed: DateTime.utc(2026, 11, 14, 3));
    await store.save(model);
    expect(await dependencies.createPocketModelStore().load(), model, reason: 'kept for the next start');
    expect(File('${root.path}/toy/pocket_model.json').existsSync(), isTrue);
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');

    File('${root.path}/toy/pocket_model.json').writeAsStringSync('not json');
    expect(await store.load(), isNull, reason: 'a file it cannot read starts a fresh model');
  });

  test('createReadingPlaceStore keeps the places in one file under the support directory (plan 1BA)', () async {
    final root = Directory.systemTemp.createTempSync('reading_place_store_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dependencies = AppDependencies(
      appConfig: const AppConfig.test(contentBaseUrl: testContentBaseUrl),
      supportDirectory: () async => root,
    );

    final store = dependencies.createReadingPlaceStore();
    expect(store, isA<FileReadingPlaceStore>());
    expect(await store.load(), isEmpty);

    final places = {'engineers:alpha/first': ReadingPlace(offset: 300, share: 0.2, at: DateTime.utc(2026, 11, 11))};
    await store.save(places);
    expect(await dependencies.createReadingPlaceStore().load(), places, reason: 'kept for the next start');
    expect(File('${root.path}/reading/places.json').existsSync(), isTrue);
    expect(Directory('${root.path}/record').existsSync(), isFalse, reason: 'never in the record');

    await store.save(const {});
    expect(File('${root.path}/reading/places.json').existsSync(), isFalse, reason: 'no places, no file');
  });

  test('the backup goes through the platform gateway', () {
    const dependencies = AppDependencies(appConfig: AppConfig.test(contentBaseUrl: testContentBaseUrl));

    expect(dependencies.createBackupGateway(), isA<PlatformBackupGateway>());
  });
}
