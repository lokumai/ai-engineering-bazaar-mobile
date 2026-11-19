import 'package:ai_engineering_bazaar/infrastructure/haptics/haptics_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const _channel = MethodChannel(HapticsChannel.name);

final _messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

void main() {
  setUpAll(() => TestEnv.autoReset = false);
  tearDown(() => _messenger.setMockMethodCallHandler(_channel, null));

  test('names the kind to the phone (plan 18.12)', () async {
    final calls = <MethodCall>[];
    _messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return null;
    });
    await const HapticsChannel().play('light');
    expect(calls.map((call) => (call.method, call.arguments)), [('play', 'light')]);
  });

  test('a refused kind, or no channel, plays nothing and throws nothing', () async {
    _messenger.setMockMethodCallHandler(_channel, (_) async => throw PlatformException(code: 'unknown-kind'));
    await expectLater(const HapticsChannel().play('loud'), completes);
    _messenger.setMockMethodCallHandler(_channel, null);
    await expectLater(const HapticsChannel().play('light'), completes);
  });
}
