import 'package:flutter/services.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// The phone's share sheet (plan 17.3) on `dev.lokumai.bazaar/share`, which `ShareSheet.kt` (Android's chooser) and
/// `AppDelegate.swift` (iOS's activity sheet) answer: the app's own channel, as with the speech and the app icon. The
/// text is offered to the phone's apps; nothing leaves the phone until the reader picks one.
final class ShareChannel {
  const ShareChannel([this._channel = const MethodChannel(name)]);

  /// The channel's name on both native sides.
  static const name = 'dev.lokumai.bazaar/share';

  static final _log = AppLogger.getLogger('ShareChannel');

  final MethodChannel _channel;

  /// Shows the sheet with [text]; false when it could not be shown.
  Future<bool> share(String text) async {
    try {
      await _channel.invokeMethod<void>('share', text);
      return true;
    } on PlatformException catch (error) {
      _log.warn('share sheet not shown: {}', [error.code]);
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
