import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/haptics/haptics_channel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Android's touch feedback is the app's own channel (plan 18.12): Haptics.kt answers the channel the Dart side names,
/// plays every kind it sends, as a crisp primitive or not at all (the owner, 2026-11-19), and closes with the engine.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Haptics.kt answers the Dart channel with every kind, and MainActivity opens and closes it', () {
    final haptics = read('android/app/src/main/kotlin/dev/lokumai/bazaar/Haptics.kt');
    expect(haptics, contains('const val CHANNEL = "${HapticsChannel.name}"'));
    for (final kind in HapticsChannel.kinds) {
      expect(haptics, contains('"$kind" -> VibrationEffect.Composition.PRIMITIVE_'), reason: kind);
    }
    expect(haptics, isNot(contains('createOneShot')), reason: 'never a buzz');
    expect(haptics, isNot(contains('createPredefined')), reason: 'never a buzz');
    expect(haptics, contains('VibrationAttributes.USAGE_TOUCH'), reason: "the reader's touch feedback setting");
    final activity = read('android/app/src/main/kotlin/dev/lokumai/bazaar/MainActivity.kt');
    expect(activity, contains('Haptics(this, flutterEngine.dartExecutor.binaryMessenger)'));
    expect(activity, contains('haptics?.close()'));
    expect(read('android/app/src/main/AndroidManifest.xml'), contains('android.permission.VIBRATE'));
  });

  test('every kind the Dart side plays is one the channel names', () {
    expect(HapticsChannel.kinds, {'selection', 'light', 'medium', 'heavy'});
  });
}
