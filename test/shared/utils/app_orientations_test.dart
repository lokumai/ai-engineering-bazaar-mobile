import 'package:ai_engineering_bazaar/shared/utils/app_orientations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a phone keeps portrait, held either way', () {
    expect(appOrientations(const Size(393, 852)), [DeviceOrientation.portraitUp]);
    expect(appOrientations(const Size(852, 393)), [DeviceOrientation.portraitUp]);
  });

  test('a tablet turns every way, from an iPad mini up', () {
    expect(appOrientations(const Size(744, 1133)), isEmpty);
    expect(appOrientations(const Size(1366, 1024)), isEmpty);
  });
}
