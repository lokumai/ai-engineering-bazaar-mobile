import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:flutter/services.dart';

/// The native side of the app icon choice: `choose` with the icon's name on `dev.lokumai.bazaar/app_icon`, which
/// `MainActivity.kt` and `AppDelegate.swift` answer. A call that fails is logged; the icon then stays as it was.
final class AppIconChannel {
  const AppIconChannel([this._channel = const MethodChannel(name)]);

  /// The channel's name on both native sides.
  static const name = 'dev.lokumai.bazaar/app_icon';

  static final _log = AppLogger.getLogger('AppIconChannel');

  final MethodChannel _channel;

  /// Asks the phone to show the icon named [icon].
  Future<void> choose(String icon) async {
    try {
      await _channel.invokeMethod<void>('choose', icon);
    } on PlatformException catch (error) {
      _log.warn('app icon {} not set: {}', [icon, error.code]);
    } on MissingPluginException {
      _log.debug('no app icon channel on this platform');
    }
  }
}
