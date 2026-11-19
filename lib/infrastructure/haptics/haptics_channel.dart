import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:flutter/services.dart';

/// The native side of Android's touch feedback (plan 18.12): `play` with one of `selection`, `light`, `medium` and
/// `heavy` on `dev.lokumai.bazaar/haptics`, which `Haptics.kt` answers. A call that fails plays nothing.
final class HapticsChannel {
  const HapticsChannel([this._channel = const MethodChannel(name)]);

  /// The channel's name on the native side.
  static const name = 'dev.lokumai.bazaar/haptics';

  /// The kinds the native side plays.
  static const kinds = {'selection', 'light', 'medium', 'heavy'};

  static final _log = AppLogger.getLogger('HapticsChannel');

  final MethodChannel _channel;

  /// Asks the phone to play [kind].
  Future<void> play(String kind) async {
    try {
      await _channel.invokeMethod<void>('play', kind);
    } on PlatformException catch (error) {
      _log.debug('haptic {} not played: {}', [kind, error.code]);
    } on MissingPluginException {
      _log.debug('no haptics channel on this platform');
    }
  }
}
