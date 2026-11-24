import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/infrastructure/scanner/code_scanner_channel.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const _channel = MethodChannel(CodeScannerChannel.name);

final _messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

const _scanner = ChannelCodeScanner(CodeScannerChannel());

void main() {
  setUpAll(() => TestEnv.autoReset = false);
  tearDown(() => _messenger.setMockMethodCallHandler(_channel, null));

  test('asks whether the phone can scan, false without the channel', () async {
    _messenger.setMockMethodCallHandler(_channel, (call) async => call.method == 'available');
    expect(await _scanner.available(), isTrue);
    _messenger.setMockMethodCallHandler(_channel, (_) async => throw PlatformException(code: 'boom'));
    expect(await _scanner.available(), isFalse);
    _messenger.setMockMethodCallHandler(_channel, null);
    expect(await _scanner.available(), isFalse);
  });

  // Review 8, finding 17: iOS drew its own Cancel in the phone's language, under the app's title in the app's.
  test("scans with the title and the Cancel of the app's language, and gives the code read", () async {
    final calls = <MethodCall>[];
    _messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return 'https://example.test/transfer/#t=abc';
    });
    final outcome = await _scanner.scan('Scan it', cancel: 'Vazgeç');
    expect((outcome as ScanRead).text, 'https://example.test/transfer/#t=abc');
    expect(calls.single.method, 'scan');
    expect(calls.single.arguments, {'title': 'Scan it', 'cancel': 'Vazgeç'});
  });

  test('no code is a going back; a camera not allowed, not opened, or no channel is said apart', () async {
    _messenger.setMockMethodCallHandler(_channel, (_) async => null);
    expect(await _scanner.scan('t', cancel: 'c'), isA<ScanCancelled>());
    _messenger.setMockMethodCallHandler(_channel, (_) async => throw PlatformException(code: 'denied'));
    expect(await _scanner.scan('t', cancel: 'c'), isA<ScanDenied>());
    _messenger.setMockMethodCallHandler(_channel, (_) async => throw PlatformException(code: 'no-camera'));
    expect(await _scanner.scan('t', cancel: 'c'), isA<ScanFailed>());
    _messenger.setMockMethodCallHandler(_channel, null);
    expect(await _scanner.scan('t', cancel: 'c'), isA<ScanFailed>());
  });
}
