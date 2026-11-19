import 'package:flutter/services.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// The phone's QR code scanner (plan 17.5) on `dev.lokumai.bazaar/scanner`, which `CodeScanner.kt` (Google's code
/// scanner) and `AppDelegate.swift` (the app's camera screen) answer: `available`, and `scan` with the screen's title,
/// which gives the code's text, or null when the reader went back. The app's own channel, as with the share sheet.
final class CodeScannerChannel {
  const CodeScannerChannel([this._channel = const MethodChannel(name)]);

  /// The channel's name on both native sides.
  static const name = 'dev.lokumai.bazaar/scanner';

  static final _log = AppLogger.getLogger('CodeScannerChannel');

  final MethodChannel _channel;

  Future<bool> available() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException catch (error) {
      _log.warn('scanner availability unknown: {}', [error.code]);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The code's text, or neither when the reader went back; an [error] code (`denied` for a camera not allowed) when
  /// the scan could not be done.
  Future<({String? text, String? error})> scan(String title) async {
    try {
      final text = await _channel.invokeMethod<String>('scan', title);
      return (text: text == null || text.isEmpty ? null : text, error: null);
    } on PlatformException catch (error) {
      _log.warn('scan not done: {}', [error.code]);
      return (text: null, error: error.code);
    } on MissingPluginException {
      return (text: null, error: 'missing');
    }
  }
}
