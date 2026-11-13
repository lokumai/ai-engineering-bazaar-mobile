import 'package:ai_engineering_bazaar/app/bootstrap/sentry_start.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/infrastructure/analytics/sentry_scrub.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
// ignore: implementation_imports
import 'package:sentry/src/platform/platform.dart';
// ignore: implementation_imports
import 'package:sentry/src/telemetry/span/transaction/sentry_tracer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../support/content_fixture.dart';

const _dsn = 'https://public@example.invalid/1';

const _prodWithDsn = AppConfig(
  environment: Environment.prod,
  contentBaseUrl: testContentBaseUrl,
  sentryDsnDefine: _dsn,
);

/// The platform sentry_flutter reports on an Android device, where it picks its Java binding.
class _AndroidPlatform extends Platform {
  const _AndroidPlatform();

  @override
  OperatingSystem get operatingSystem => OperatingSystem.android;
}

/// The platform sentry_flutter reports on an iOS device, where it passes the Dart options to sentry-cocoa.
class _IosPlatform extends Platform {
  const _IosPlatform();

  @override
  OperatingSystem get operatingSystem => OperatingSystem.ios;
}

/// Records each SentryFlutter.init call instead of starting the SDK.
class _InitCalls {
  final options = <SentryFlutterOptions>[];
  final runners = <AppRunner?>[];

  Future<void> call(FlutterOptionsConfiguration configure, {AppRunner? appRunner}) async {
    final flutterOptions = SentryFlutterOptions(platform: const _AndroidPlatform());
    await configure(flutterOptions);
    options.add(flutterOptions);
    runners.add(appRunner);
  }
}

void main() {
  group('SentryStart.gate', () {
    test('keeps the config when the host app started the native SDK, and logs analytics on the device', () async {
      final start = SentryStart(isNativeSdkReady: () async => true);

      final config = await start.gate(_prodWithDsn);

      expect(config.sentryDsn, _dsn);
      expect(const AppDependencies(appConfig: _prodWithDsn).createAnalyticsService(), isA<LogAnalyticsService>());
    });

    // A release build whose host did not start the native SDK runs as without a DSN: no Dart SDK, and the log
    // analytics service, so no analytics event goes into a hub that never started.
    test('drops the DSN when the native SDK check keeps Sentry off', () async {
      final start = SentryStart(isNativeSdkReady: () async => false);

      final config = await start.gate(_prodWithDsn);

      expect(config.sentryDsn, isNull);
      expect(config.environment, Environment.prod);
      expect(AppDependencies(appConfig: config).createAnalyticsService(), isA<LogAnalyticsService>());
    });

    test('does not ask the host when there is no DSN', () async {
      var asked = false;
      final start = SentryStart(
        isNativeSdkReady: () async {
          asked = true;
          return true;
        },
      );

      final config = await start.gate(const AppConfig.prod());

      expect(config.sentryDsn, isNull);
      expect(asked, isFalse);
    });
  });

  group('SentryStart.run', () {
    test('skips SentryFlutter.init and runs the app when the native SDK check keeps Sentry off', () async {
      final init = _InitCalls();
      final start = SentryStart(isNativeSdkReady: () async => false, sentryInit: init.call);
      var ran = 0;

      final config = await start.gate(_prodWithDsn);
      await start.run(config.sentryDsn, release: '1.0.0+1', appRunner: () => ran++);

      expect(init.options, isEmpty);
      expect(ran, 1);
    });

    test('starts SentryFlutter with the app as its runner when there is a DSN', () async {
      final init = _InitCalls();
      final start = SentryStart(isNativeSdkReady: () async => true, sentryInit: init.call);
      var ran = 0;

      await start.run(_dsn, release: '1.0.0+1', appRunner: () => ran++);

      expect(init.options, hasLength(1));
      await init.runners.single!();
      expect(ran, 1);
    });
  });

  group('configureSentryOptions', () {
    test('on Android leaves the native SDK to the host app and installs both scrubbers', () {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());

      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');

      expect(options.autoInitializeNativeSdk, isFalse);
      expect(options.beforeSend, isNotNull);
      expect(options.beforeBreadcrumb, isNotNull);
      expect(options.enablePrintBreadcrumbs, isFalse);
      expect(options.dsn, _dsn);
      expect(options.release, '1.0.0+1');
      expect(options.tracesSampleRate, 1);
      expect(options.traceLifecycle, SentryTraceLifecycle.static);
    });

    // Release health (the owner, 2026-11-13): a session holds no text, only its status, duration and release.
    for (final platform in const <Platform>[_AndroidPlatform(), _IosPlatform()]) {
      test('turns automatic session tracking on on ${platform.operatingSystem.name}', () {
        final options = SentryFlutterOptions(platform: platform);

        configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');

        expect(options.enableAutoSessionTracking, isTrue);
      });
    }

    test('sends the app start transaction and drops every other one', () async {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());
      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');
      final hub = Hub(options);
      SentryTransaction transaction(String operation) =>
          SentryTransaction(SentryTracer(SentryTransactionContext('name', operation), hub));

      final start = await options.beforeSendTransaction!(transaction(appStartOperation), Hint());
      final load = await options.beforeSendTransaction!(transaction('ui.load'), Hint());

      expect(start, isNotNull);
      expect(load, isNull);
    });

    test("masks an email in a user's feedback", () async {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());
      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');

      final feedback = await options.beforeSendFeedback!(
        SentryEvent(message: SentryMessage('write to jane.doe@example.com')),
        Hint(),
      );

      expect(feedback!.message!.formatted, 'write to [REDACTED_EMAIL]');
    });

    // Plan 4.4: on iOS sentry_flutter starts sentry-cocoa, whose own events and breadcrumbs never pass the Dart
    // scrubbers, so it records the least: app hangs and sessions only (the owner, 2026-11-13).
    test('on iOS turns off the events and breadcrumbs sentry-cocoa would record itself, but app hangs', () {
      final options = SentryFlutterOptions(platform: const _IosPlatform());

      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');

      expect(options.autoInitializeNativeSdk, isTrue);
      expect(options.enableNativeCrashHandling, isFalse);
      expect(options.enableAutoNativeBreadcrumbs, isFalse);
      expect(options.enableWatchdogTerminationTracking, isFalse);
      expect(options.captureNativeFailedRequests, isFalse);
      expect(options.enableAppHangTracking, isTrue);
    });

    // On Android the host app starts sentry-android with its own scrubber (NativeSentry.kt), which keeps native crash
    // handling; the Dart options do not reach it.
    test('on Android leaves the native options as they are', () {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());

      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');

      expect(options.enableNativeCrashHandling, isTrue);
      expect(options.enableAutoNativeBreadcrumbs, isTrue);
    });

    test('installs a beforeSend that masks an email and a beforeBreadcrumb that masks one', () async {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());

      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');
      final event = await options.beforeSend!(SentryEvent(message: SentryMessage('jane.doe@example.com')), Hint());
      final crumb = options.beforeBreadcrumb!(Breadcrumb(message: 'jane.doe@example.com'), Hint());

      expect(event!.message!.formatted, '[REDACTED_EMAIL]');
      expect(crumb!.message, '[REDACTED_EMAIL]');
    });
  });
}
