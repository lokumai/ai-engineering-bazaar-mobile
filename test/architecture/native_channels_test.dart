import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/links/link_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/scanner/code_scanner_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/share/share_channel.dart';
import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

const _kotlin = 'android/app/src/main/kotlin/dev/lokumai/bazaar';
final _swift = _read('ios/Runner/AppDelegate.swift');

/// Review 6, finding 20: the links, share and scanner channels were tied to their native sides by hand only, while the
/// speech, icon, launch-ground and haptics channels have a test. A renamed channel or method on one side answers
/// nothing, and no unit test would notice.
void main() {
  test('the links channel: the Dart side asks for the waiting links, the native sides send each later one', () {
    final dart = _read('lib/infrastructure/links/link_channel.dart');
    final kotlin = _read('$_kotlin/Links.kt');
    expect(kotlin, contains('const val CHANNEL = "${LinkChannel.name}"'));
    expect(_swift, contains('FlutterMethodChannel(name: "${LinkChannel.name}"'));

    expect(dart, contains("invokeListMethod<String>('ready')"));
    expect(kotlin, contains('"ready" -> {'));
    expect(_swift, contains('call.method == "ready"'));

    expect(dart, contains("call.method != 'link'"));
    expect(kotlin, contains('channel.invokeMethod("link", link)'));
    expect(_swift, contains('channel.invokeMethod("link", arguments: link)'));
  });

  test('the share channel: one method, share, with the text', () {
    final dart = _read('lib/infrastructure/share/share_channel.dart');
    final kotlin = _read('$_kotlin/ShareSheet.kt');
    expect(kotlin, contains('const val CHANNEL = "${ShareChannel.name}"'));
    expect(_swift, contains('FlutterMethodChannel(name: "${ShareChannel.name}"'));

    expect(dart, contains("invokeMethod<void>('share', text)"));
    expect(kotlin, contains('call.method != "share" -> result.notImplemented()'));
    expect(_swift, contains('guard call.method == "share" else { return result(FlutterMethodNotImplemented) }'));
  });

  test('the scanner channel: available, and scan with the title', () {
    final dart = _read('lib/infrastructure/scanner/code_scanner_channel.dart');
    final kotlin = _read('$_kotlin/CodeScanner.kt');
    expect(kotlin, contains('const val CHANNEL = "${CodeScannerChannel.name}"'));
    expect(_swift, contains('FlutterMethodChannel(name: "${CodeScannerChannel.name}"'));

    expect(dart, contains("invokeMethod<bool>('available')"));
    expect(kotlin, contains('"available" -> result.success('));
    expect(_swift, contains('case "available":'));

    expect(dart, contains("invokeMethod<String>('scan', {'title': title, 'cancel': cancel})"));
    expect(kotlin, contains('"scan" -> scan(Once(result))'));
    expect(_swift, contains('case "scan":'));
    expect(_swift, contains('let texts = call.arguments as? [String: Any] ?? [:]'));
    expect(_swift, contains('title: texts["title"] as? String ?? ""'));
    expect(_swift, contains('cancel: texts["cancel"] as? String ?? ""'));
  });
}
