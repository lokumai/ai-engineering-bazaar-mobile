import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:flutter/services.dart';

/// The native side of the launch ground: `keep` with `light` or `dark` on `dev.lokumai.bazaar/launch_ground`, which
/// `MainActivity.kt` and `AppDelegate.swift` answer by opening the next launch on that look's page colour. A call that
/// fails is logged; the next launch then opens on the ground it had.
final class LaunchGroundChannel {
  const LaunchGroundChannel([this._channel = const MethodChannel(name)]);

  /// The channel's name on both native sides.
  static const name = 'dev.lokumai.bazaar/launch_ground';

  static final _log = AppLogger.getLogger('LaunchGroundChannel');

  final MethodChannel _channel;

  /// Asks the phone to open the next launch on the page colour of the dark look ([dark]) or the light one.
  Future<void> keep({required bool dark}) async {
    final look = dark ? 'dark' : 'light';
    try {
      await _channel.invokeMethod<void>('keep', look);
    } on PlatformException catch (error) {
      _log.warn('launch ground {} not kept: {}', [look, error.code]);
    } on MissingPluginException {
      _log.debug('no launch ground channel on this platform');
    }
  }
}
