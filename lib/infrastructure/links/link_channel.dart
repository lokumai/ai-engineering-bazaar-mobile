import 'dart:async';

import 'package:flutter/services.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// The links the phone hands the app (plan 17.2) on `dev.lokumai.bazaar/links`, which `Links.kt` (Android's view
/// intents) and `AppDelegate.swift` (iOS's scene, as a Flutter scene delegate) answer: the app's own channel, as
/// Flutter's deep linking stays off and no link reaches the router by itself.
///
/// A link the app was opened with waits on the native side until [takeWaiting] asks for it; the ones that come later
/// arrive on [links]. A link is never logged: a transfer carries the reader's progress.
final class LinkChannel {
  LinkChannel([this._channel = const MethodChannel(name)]) {
    _channel.setMethodCallHandler(_heard);
  }

  /// The channel's name on both native sides.
  static const name = 'dev.lokumai.bazaar/links';

  static final _log = AppLogger.getLogger('LinkChannel');

  final MethodChannel _channel;
  final _links = StreamController<Uri>.broadcast();

  /// The links handed to the app while it runs.
  Stream<Uri> get links => _links.stream;

  /// The links that came before this asked, once; an empty list when the channel does not answer.
  Future<List<Uri>> takeWaiting() async {
    try {
      final waiting = await _channel.invokeListMethod<String>('ready') ?? const [];
      return [for (final link in waiting) ?Uri.tryParse(link)];
    } on PlatformException catch (error) {
      _log.warn('links not read: {}', [error.code]);
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<void> _heard(MethodCall call) async {
    if (call.method != 'link' || call.arguments is! String) return;
    if (Uri.tryParse(call.arguments as String) case final link?) _links.add(link);
  }
}
