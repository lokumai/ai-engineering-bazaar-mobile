import 'package:ai_engineering_bazaar/infrastructure/share/share_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const _channel = MethodChannel(ShareChannel.name);

final _messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

void main() {
  setUpAll(() => TestEnv.autoReset = false);
  tearDown(() => _messenger.setMockMethodCallHandler(_channel, null));

  test('hands the text to the share sheet and answers true', () async {
    final calls = <MethodCall>[];
    _messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return null;
    });
    expect(await const ShareChannel().share('https://example.test/courses/alpha/first/'), isTrue);
    expect(calls.single.method, 'share');
    expect(calls.single.arguments, 'https://example.test/courses/alpha/first/');
  });

  test('answers false when the sheet cannot be shown, or there is no channel', () async {
    _messenger.setMockMethodCallHandler(_channel, (_) async => throw PlatformException(code: 'no-sheet'));
    expect(await const ShareChannel().share('x'), isFalse);
    _messenger.setMockMethodCallHandler(_channel, null);
    expect(await const ShareChannel().share('x'), isFalse);
  });
}
