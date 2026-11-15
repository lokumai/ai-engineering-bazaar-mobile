import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/theme/launch_ground_channel.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the launch screens on the page colour of the reader's look, the ground the app's first frame is on (the owner,
/// 2026-11-15: the first frames showed the app icon's ground instead). The app opens dark until the reader chooses, so
/// the screens the system shows on its own are dark, whatever the phone's theme and the icon; the light look's are the
/// ones the native sides switch to once the Dart side names it (`dev.lokumai.bazaar/launch_ground`).
void main() {
  String hex(Brightness brightness) => bazaarTheme(
    brightness: brightness,
    platform: TargetPlatform.android,
  ).scaffoldBackgroundColor.toARGB32().toRadixString(16).substring(2);
  final dark = hex(Brightness.dark);
  final light = hex(Brightness.light);
  String read(String path) => File(path).readAsStringSync();
  String style(String styles, String name) =>
      RegExp('<style name="$name"[^>]*>(.*?)</style>', dotAll: true).firstMatch(styles)![1]!;

  test('the Android colours are the two page colours', () {
    final colours = read('android/app/src/main/res/values/colors.xml');
    expect(colours, contains('<color name="bazaar_page">#${dark.toUpperCase()}</color>'));
    expect(colours, contains('<color name="ic_launcher_cream_background">#${light.toUpperCase()}</color>'));
  });

  test("Android's own launch screens are on the dark page colour, in every phone theme", () {
    for (final path in ['drawable', 'drawable-v21']) {
      expect(
        read('android/app/src/main/res/$path/launch_background.xml'),
        contains('@color/bazaar_page'),
        reason: path,
      );
    }
    expect(
      style(read('android/app/src/main/res/values/styles.xml'), 'LaunchTheme'),
      contains('@drawable/launch_background'),
    );
    expect(
      style(read('android/app/src/main/res/values-v31/styles.xml'), 'LaunchTheme'),
      contains('<item name="android:windowSplashScreenBackground">@color/bazaar_page</item>'),
    );
    // A night version would follow the phone's theme rather than the app's look.
    for (final night in ['values-night', 'values-night-v31']) {
      expect(File('android/app/src/main/res/$night/styles.xml').existsSync(), isFalse, reason: night);
    }
  });

  test("the light look's launch screen on Android is on cream, and LaunchGround.kt names both", () {
    final light = style(read('android/app/src/main/res/values-v31/styles.xml'), 'LaunchTheme.Light');
    expect(
      light,
      contains('<item name="android:windowSplashScreenBackground">@color/ic_launcher_cream_background</item>'),
    );
    expect(light, contains('<item name="android:windowBackground">@color/ic_launcher_cream_background</item>'));
    final kotlin = read('android/app/src/main/kotlin/dev/lokumai/bazaar/LaunchGround.kt');
    expect(kotlin, contains('const val CHANNEL = "${LaunchGroundChannel.name}"'));
    expect(kotlin, contains('mapOf("light" to R.color.ic_launcher_cream_background, "dark" to R.color.bazaar_page)'));
    expect(kotlin, contains('mapOf("light" to R.style.LaunchTheme_Light, "dark" to R.style.LaunchTheme)'));
    expect(
      read('android/app/src/main/kotlin/dev/lokumai/bazaar/MainActivity.kt'),
      contains('LaunchGround.ground(this)'),
    );
  });

  test("iOS's launch screen is on the dark page colour, and AppDelegate.swift paints each look's", () {
    expect(
      read('ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json'),
      contains(
        '"blue" : "0x${dark.substring(4).toUpperCase()}", '
        '"green" : "0x${dark.substring(2, 4).toUpperCase()}", "red" : "0x${dark.substring(0, 2).toUpperCase()}"',
      ),
    );
    final swift = read('ios/Runner/AppDelegate.swift');
    expect(swift, contains('"light": 0x$light,'));
    expect(swift, contains('"dark": 0x$dark,'));
    expect(swift, contains('FlutterMethodChannel(name: "${LaunchGroundChannel.name}"'));
  });

  // Flutter shows the launch screen once more until its first frame: the app's screen shows the ground of the look last
  // named instead, or the light look flashes dark on opening (the owner, 2026-11-15).
  test('the iOS app screen is BazaarViewController, which shows the kept ground until the first frame', () {
    expect(
      read('ios/Runner/Base.lproj/Main.storyboard'),
      contains('customClass="BazaarViewController" customModule="Runner"'),
    );
    final swift = read('ios/Runner/AppDelegate.swift');
    expect(swift, contains('class BazaarViewController: FlutterViewController {'));
    expect(swift, contains('splashScreenView = splash'));
    expect(swift, contains('LaunchPicture.keep(ground)'));
  });
}
