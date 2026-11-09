@Tags(['widget'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/app_bootstrap.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/app_bootstrap_config.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/sentry_start.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../support/content_fixture.dart';

/// Records what AppBootstrap.run asks of the Sentry start, answers the gate with [gated], and starts nothing.
class _RecordingSentryStart implements SentryStart {
  _RecordingSentryStart(this.gated);

  final AppConfig gated;
  final gatedConfigs = <AppConfig>[];
  final runDsns = <String?>[];

  @override
  Future<bool> Function() get isNativeSdkReady => throw UnimplementedError();

  @override
  SentryInit get sentryInit => throw UnimplementedError();

  @override
  Future<AppConfig> gate(AppConfig config) async {
    gatedConfigs.add(config);
    return gated;
  }

  @override
  Future<void> run(String? dsn, {required String release, required AppRunner appRunner}) async => runDsns.add(dsn);
}

void main() {
  group('AppBootstrap.run', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'app',
        packageName: 'app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    // The gate decides before anything reads the config, so a release build whose host did not start the native SDK
    // runs as without a DSN, and the DSN SentryFlutter starts with is the one the gate kept.
    testWidgets('passes its config through the Sentry gate and starts Sentry with the DSN the gate kept', (
      tester,
    ) async {
      final sentry = _RecordingSentryStart(
        const AppConfig(
          environment: Environment.prod,
          contentBaseUrl: testContentBaseUrl,
          sentryDsnDefine: 'https://public@example.invalid/1',
        ),
      );
      final flutterErrorHandler = FlutterError.onError;
      final platformErrorHandler = PlatformDispatcher.instance.onError;
      final observer = Bloc.observer;
      final built = <AppConfig>[];

      await tester.runAsync(
        () => AppBootstrap.run(
          const AppBootstrapConfig(environment: Environment.prod),
          sentry: sentry,
          dependencies: (config) {
            built.add(config);
            return FixtureAppDependencies(appConfig: config);
          },
        ),
      );
      FlutterError.onError = flutterErrorHandler;
      PlatformDispatcher.instance.onError = platformErrorHandler;
      Bloc.observer = observer;

      expect(sentry.gatedConfigs.map((config) => config.environment), [Environment.prod]);
      expect(sentry.runDsns, ['https://public@example.invalid/1']);
      expect(built, [same(sentry.gated)]);
    });

    // Spec 3.7: main_local without --dart-define=CONTENT_BASE_URL fails at start, before anything is built.
    testWidgets('refuses a config without a content base URL', (tester) async {
      final sentry = _RecordingSentryStart(const AppConfig(environment: Environment.dev, contentBaseUrl: ''));
      final built = <AppConfig>[];
      Object? caught;

      await tester.runAsync(() async {
        try {
          await AppBootstrap.run(
            const AppBootstrapConfig(environment: Environment.dev),
            sentry: sentry,
            dependencies: (config) {
              built.add(config);
              return FixtureAppDependencies(appConfig: config);
            },
          );
        } on StateError catch (error) {
          caught = error;
        }
      });

      expect(caught, isA<StateError>().having((e) => e.message, 'message', contains('CONTENT_BASE_URL')));
      expect(built, isEmpty);
      expect(sentry.runDsns, isEmpty);
    });
  });
}
