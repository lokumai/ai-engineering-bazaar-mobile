import 'package:ai_engineering_bazaar/infrastructure/links/link_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const _channel = MethodChannel(LinkChannel.name);

final _messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

Future<void> _native(String method, Object? arguments) => _messenger.handlePlatformMessage(
  _channel.name,
  const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
  (_) {},
);

void main() {
  setUpAll(() => TestEnv.autoReset = false);
  tearDown(() => _messenger.setMockMethodCallHandler(_channel, null));

  group('LinkChannel (plan 17.2)', () {
    test('takes the links that waited, once, by asking ready', () async {
      final calls = <String>[];
      _messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call.method);
        return ['https://example.test/courses/alpha/first/', 'aibazaar://transfer#t=abc'];
      });
      final links = await LinkChannel().takeWaiting();
      expect(calls, ['ready']);
      expect(links.map((link) => '$link'), ['https://example.test/courses/alpha/first/', 'aibazaar://transfer#t=abc']);
    });

    test('hands on each link the native side sends while the app runs, and nothing else', () async {
      final channel = LinkChannel();
      final heard = <Uri>[];
      final subscription = channel.links.listen(heard.add);
      await _native('link', 'https://example.test/sheets/');
      await _native('other', 'https://example.test/sheets/');
      await _native('link', 42);
      await pumpEventQueue();
      expect(heard, [Uri.parse('https://example.test/sheets/')]);
      await subscription.cancel();
    });

    test('a channel that fails, or none, has no waiting links', () async {
      _messenger.setMockMethodCallHandler(_channel, (_) async => throw PlatformException(code: 'gone'));
      expect(await LinkChannel().takeWaiting(), isEmpty);
      _messenger.setMockMethodCallHandler(_channel, null);
      expect(await LinkChannel().takeWaiting(), isEmpty);
    });
  });
}
