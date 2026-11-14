import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/utils/app_orientations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/app_bootstrap_config.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/content_base_url.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/sentry_start.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/app/analytics/crash_reporter.dart';
import 'package:ai_engineering_bazaar/app/dev_console/time_travel/time_travel_bloc_observer.dart';
import 'package:ai_engineering_bazaar/core/logging/app_bloc_observer.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/utils/app_constants.dart';

class AppBootstrap {
  /// Starts the app as [config] says. [sentry] decides whether Sentry starts and starts it, and [dependencies] builds
  /// the app's dependencies from the config; a test passes its own of both.
  ///
  /// Throws a [StateError] when the config has no usable `contentBaseUrl` (spec 3.7).
  static Future<void> run(
    AppBootstrapConfig config, {
    @visibleForTesting SentryStart sentry = const SentryStart(),
    @visibleForTesting AppDependencies Function(AppConfig config)? dependencies,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    registerFontLicences();

    await AppConstants.initPackageInfo();

    AppLogger.configure(isProduction: config.isProduction);
    final log = AppLogger.getLogger('AppBootstrap');

    // Decided before anything reads the config: when Sentry may not start (a release build whose Android host did not
    // start the native SDK), the config loses its DSN, so the app runs exactly as without one.
    final appConfig = await sentry.gate(AppConfig.fromEnvironment(config.environment));
    try {
      requireContentBaseUrl(appConfig.contentBaseUrl);
    } on StateError catch (error) {
      log.error('{}', [error]);
      rethrow;
    }
    final appDependencies = (dependencies ?? (c) => AppDependencies(appConfig: c))(appConfig);

    // Analytics & crash reporting.
    //
    // CrashReporter always installs framework / PlatformDispatcher hooks that
    // log every uncaught error. When Sentry is active it installs its own hooks
    // that capture the error and chain to ours, so Sentry reports the crash and
    // the error is not forwarded to the analytics service as well. With Sentry
    // off, the analytics service (LogAnalyticsService) also logs the head of
    // the stack trace, so forwarding stays on.
    final analytics = appDependencies.createAnalyticsService();
    final sentryActive = appConfig.sentryDsn != null;
    CrashReporter.install(analytics, forwardToAnalytics: !sentryActive);

    Bloc.observer = kDebugMode ? TimeTravelBlocObserver() : AppBlocObserver();

    await SystemChrome.setPreferredOrientations(appOrientations());

    // The chosen app icon, read before the first frame, so the opening starts in its colours rather than the
    // default's (a few flag files; a file not read counts as no choice).
    final appIcon = await appDependencies.createAppIconStore().chosen() ?? BazaarIcon.defaultIcon;

    log.info('Starting app with env: {}', [config.environment.name]);

    // The Sentry options are configureSentryOptions (lib/app/bootstrap/sentry_start.dart). On Android the host app
    // starts the native SDK, so a native option set there must also be set in NativeSentry.kt of the Android host app
    // (under android/app/src/main/kotlin).
    await sentry.run(
      appConfig.sentryDsn,
      release: '${AppConstants.appVersion}+${AppConstants.appBuildNumber}',
      appRunner: () => runApp(App(dependencies: appDependencies, appIcon: appIcon)),
    );
  }
}
