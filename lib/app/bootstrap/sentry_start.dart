import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/infrastructure/analytics/native_sentry_start.dart';
import 'package:ai_engineering_bazaar/infrastructure/analytics/sentry_scrub.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The shape of [SentryFlutter.init] that [SentryStart] calls.
typedef SentryInit = Future<void> Function(FlutterOptionsConfiguration optionsConfiguration, {AppRunner? appRunner});

/// How `AppBootstrap.run` starts Sentry: whether it may start at all
/// ([gate]), and the start itself ([run]). A test passes one whose platform
/// parts, the host check and [SentryFlutter.init], are its own.
class SentryStart {
  const SentryStart({this.isNativeSdkReady = nativeSdkReady, this.sentryInit = SentryFlutter.init});

  /// Answers whether the Dart SDK may start: where the host app starts the
  /// native SDK, whether it did ([nativeSdkReady]).
  final Future<bool> Function() isNativeSdkReady;

  /// Starts the Dart SDK.
  final SentryInit sentryInit;

  /// Returns [config], or [config] without its DSN when it has one but
  /// [isNativeSdkReady] keeps Sentry off (a release build whose host app did
  /// not start the native SDK). The app then runs exactly as without a DSN:
  /// no Dart SDK, and the log-only analytics instead of a Sentry hub that
  /// never started. Debug and profile builds throw there instead.
  Future<AppConfig> gate(AppConfig config) async {
    if (config.sentryDsn == null) return config;
    return await isNativeSdkReady() ? config : config.withoutSentry();
  }

  /// Runs [appRunner] inside [SentryFlutter.init] with the options of
  /// [configureSentryOptions] when [dsn] is set, and on its own when it is
  /// null.
  Future<void> run(String? dsn, {required String release, required AppRunner appRunner}) async {
    if (dsn == null) {
      await appRunner();
      return;
    }
    _log.info('Initializing Sentry (release: {})', [release]);
    await sentryInit(
      (options) => configureSentryOptions(options, dsn: dsn, release: release),
      appRunner: appRunner,
    );
  }
}

final _log = AppLogger.getLogger('SentryStart');

/// The options `AppBootstrap.run` starts the Dart SDK with: the DSN, the
/// scrubbing hooks of [installSentryScrubbers], the native start of
/// [configureNativeSdkStart], tracing on with the transaction lifecycle, of which
/// [sentryBeforeSendTransaction] sends the app start only, automatic session tracking on for release health (a
/// session carries the release, the environment, its status and duration and a random id of the installation, and
/// Sentry keeps no IP address), and the release. What leaves the device: crash reports, hangs, the app start, the
/// sessions and a user's own feedback (the owner, 2026-11-13).
///
/// On Android the host app starts the native SDK, so a native option set
/// here must also be set in `NativeSentry.kt` of the Android host app (under
/// `android/app/src/main/kotlin`), or it does nothing there.
void configureSentryOptions(SentryFlutterOptions options, {required String dsn, required String release}) {
  options.dsn = dsn;
  installSentryScrubbers(options);
  configureNativeSdkStart(options);
  // The transaction lifecycle, whose transactions pass beforeSendTransaction; streamed spans would not.
  options.traceLifecycle = SentryTraceLifecycle.static;
  options.tracesSampleRate = 1;
  // Also set in NativeSentry.kt, since on Android this option does not reach the native SDK.
  options.enableAutoSessionTracking = true;
  options.release = release;
}
