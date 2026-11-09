import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/app/bootstrap/sentry_start.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/analytics/crash_reporter.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_bloc_observer.dart';
import 'package:flutter_bloc_advance/core/logging/app_bloc_observer.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

class AppBootstrap {
  /// Starts the app as [config] says. [sentry] decides whether Sentry starts and starts it; a test passes its own.
  static Future<void> run(
    AppBootstrapConfig config, {
    @visibleForTesting SentryStart sentry = const SentryStart(),
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppConstants.initPackageInfo();

    AppLogger.configure(isProduction: config.isProduction);
    final log = AppLogger.getLogger('AppBootstrap');

    // Decided before anything reads the config: when Sentry may not start (a release build whose Android host did not
    // start the native SDK), the config loses its DSN, so the app runs exactly as without one.
    final appConfig = await sentry.gate(AppConfig.fromEnvironment(config.environment));
    final dependencies = AppDependencies(appConfig: appConfig);

    // Analytics & crash reporting.
    //
    // CrashReporter always installs framework / PlatformDispatcher hooks for
    // local logging. When Sentry is active it installs its OWN hooks that both
    // capture the error and chain to ours, so we must NOT also forward uncaught
    // errors to the Sentry-backed analytics here — doing so reports every crash
    // twice. With Sentry off, forwarding to the local logging analytics is the
    // only sink, so it stays enabled.
    final analytics = dependencies.createAnalyticsService();
    final sentryActive = appConfig.sentryDsn != null;
    CrashReporter.install(analytics, forwardToAnalytics: !sentryActive);

    Bloc.observer = kDebugMode ? TimeTravelBlocObserver() : AppBlocObserver();

    await SystemChrome.setPreferredOrientations(config.preferredOrientations);

    log.info('Starting app with env: {}', [config.environment.name]);

    // The Sentry options are configureSentryOptions (lib/app/bootstrap/sentry_start.dart). On Android the host app
    // starts the native SDK, so a native option set there must also be set in NativeSentry.kt of the Android host app
    // (under android/app/src/main/kotlin).
    await sentry.run(
      appConfig.sentryDsn,
      release: '${AppConstants.appVersion}+${AppConstants.appBuildNumber}',
      appRunner: () => runApp(App(dependencies: dependencies)),
    );
  }
}
