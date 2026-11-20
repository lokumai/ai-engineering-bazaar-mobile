import 'package:ai_engineering_bazaar/shared/utils/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Constants values", () {
    test('appVersion should be 1.0.0', () {
      expect(AppConstants.appVersion, '1.0.0');
    });
  });

  test('a package info read that fails keeps the defaults, so the app still starts', () async {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'unavailable'),
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );

    await expectLater(AppConstants.initPackageInfo(), completes);
    expect(AppConstants.appVersion, '1.0.0');
    expect(AppConstants.appBuildNumber, '1');
  });
}
