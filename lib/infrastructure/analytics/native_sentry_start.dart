import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The channel on which `MainActivity.kt` answers whether the host app
/// started the native Sentry SDK.
const String nativeSentryChannelName = 'dev.lokumai.bazaar/native_sentry';

final _log = AppLogger.getLogger('NativeSentryStart');

/// Whether the host app, not sentry_flutter, starts the native Sentry SDK on
/// the platform of [options]: on Android `MainApplication.kt` starts
/// sentry-android with the scrubbing hooks of `NativeSentryScrubber.kt`, so
/// what the native SDK records itself leaves the device masked too.
///
/// It reads `options.platform`, by which sentry_flutter picks its Java
/// binding, and not the Flutter target platform, which a test or a debug
/// session can override. iOS and macOS keep the start by sentry_flutter, with
/// the native SDK recording nothing of its own ([configureNativeSdkStart]).
bool hostStartsNativeSdk(SentryOptions options) =>
    hostStartsNativeSdkOn(isWeb: options.platform.isWeb, isAndroid: options.platform.isAndroid);

/// The rule of [hostStartsNativeSdk]. On web the options report the
/// operating system of the browser, which is Android in a phone browser, and
/// sentry_flutter starts the JavaScript SDK there.
@visibleForTesting
bool hostStartsNativeSdkOn({required bool isWeb, required bool isAndroid}) => isAndroid && !isWeb;

/// Turns [SentryFlutterOptions.autoInitializeNativeSdk] off where
/// [hostStartsNativeSdk], or where [hostStarts] says so, and leaves it on
/// everywhere else.
///
/// sentry_flutter then no longer passes the Dart options to the native SDK
/// on Android. Any native option set on the Dart side, such as
/// `enableAutoNativeBreadcrumbs`, `enableNativeCrashHandling`,
/// `maxBreadcrumbs`, `sendDefaultPii` or the replay options, must be set in
/// `NativeSentry.kt` of the Android host app (under
/// `android/app/src/main/kotlin`) as well, or it does nothing there.
///
/// Where sentry_flutter starts the native SDK itself (iOS and macOS, sentry-cocoa), no scrubber of the app sees what
/// that SDK records on its own, so it records nothing: no native crash handler, no native breadcrumbs, no watchdog
/// termination and no app hang events (plan 4.4). Every crash report there is a Dart one, masked by the Dart
/// scrubbers before it leaves the device.
void configureNativeSdkStart(SentryFlutterOptions options, {bool? hostStarts}) {
  final host = hostStarts ?? hostStartsNativeSdk(options);
  options.autoInitializeNativeSdk = !host;
  if (host || options.platform.isWeb) return;
  options.enableNativeCrashHandling = false;
  options.enableAutoNativeBreadcrumbs = false;
  options.enableWatchdogTerminationTracking = false;
  options.enableAppHangTracking = false;
}

/// Whether the Dart SDK may start. Where the host app starts the native SDK
/// ([hostStarts], by default [hostStartsNativeSdk] of the options
/// sentry_flutter builds), it asks the host whether it did.
///
/// On Android every Dart event leaves the device through the native SDK, so
/// a Dart SDK that starts while the host did not start the native one drops
/// every event while it looks configured. The host starts it only for a
/// `lib/main/main_prod.dart` build with a `SENTRY_DSN` (the gate in
/// `android/app/build.gradle.kts`), the Dart side for the prod environment
/// with one (`AppConfig.sentryDsn`), and the two gates disagree when a fork
/// changes one of them. A debug or profile build then throws a [StateError]
/// that names the mismatch; a release build logs it and returns false, so the
/// app runs without Sentry. A host app that does not answer on
/// [nativeSentryChannelName], such as a fork without the handler, or whose
/// handler fails, is treated the same way.
Future<bool> nativeSdkReady({
  bool? hostStarts,
  MethodChannel channel = const MethodChannel(nativeSentryChannelName),
  bool releaseMode = kReleaseMode,
}) async {
  if (!(hostStarts ?? hostStartsNativeSdk(SentryFlutterOptions()))) return true;
  String problem;
  try {
    final enabled = await channel.invokeMethod<bool>('isEnabled');
    if (enabled == true) return true;
    problem = 'the host app did not start the native Sentry SDK (it answered $enabled)';
  } on MissingPluginException {
    problem = 'the host app does not answer on $nativeSentryChannelName';
  } on PlatformException catch (error) {
    // Only the code: the message of a host error can hold anything.
    problem = 'the host app failed to answer on $nativeSentryChannelName (${error.code})';
  }
  final error = StateError(
    'Sentry has a DSN on the Dart side, but $problem, so every Dart event would be dropped. The host starts it only '
    'for a lib/main/main_prod.dart build with a SENTRY_DSN define: see android/app/build.gradle.kts.',
  );
  if (!releaseMode) throw error;
  _log.error('Sentry stays off: {}', [error.message]);
  return false;
}
