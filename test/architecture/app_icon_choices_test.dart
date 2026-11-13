import 'dart:io';

import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the app icons the reader can choose (lib/shared/app_icon/bazaar_icon.dart) in step with the two native sides:
/// a launcher entry with its own icon in the Android manifest, the same names in `AppIconSwitch.kt`, an alternate icon
/// in the iOS asset catalog that the build includes, the same names in `AppDelegate.swift`, and a picture for the
/// choice. Nothing in a build fails when one of these drifts; the icon then silently stays as it was.
void main() {
  String pascal(String name) => name[0].toUpperCase() + name.substring(1);
  String snake(String name) => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
  final others = BazaarIcon.values.where((icon) => icon != BazaarIcon.dark);

  test('the Android manifest has one launcher entry per icon, only Dark enabled, each with its own icon', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final aliases = RegExp(r'<activity-alias\s+([^>]*)>').allMatches(manifest).map((m) => m[1]!).toList();

    expect(aliases, hasLength(BazaarIcon.values.length));
    for (final (i, icon) in BazaarIcon.values.indexed) {
      final alias = aliases[i];
      final resource = icon == BazaarIcon.dark ? 'ic_launcher' : 'ic_launcher_${snake(icon.name)}';
      expect(alias, contains('android:name=".Launcher${pascal(icon.name)}"'), reason: icon.name);
      expect(alias, contains('android:icon="@mipmap/$resource"'), reason: icon.name);
      expect(alias, contains('android:enabled="${icon == BazaarIcon.dark}"'), reason: icon.name);
      expect(File('android/app/src/main/res/mipmap-anydpi-v26/$resource.xml').existsSync(), isTrue, reason: resource);
    }
    // Only the entries launch the app, so exactly one icon is in the launcher.
    expect(RegExp('android.intent.category.LAUNCHER').allMatches(manifest), hasLength(BazaarIcon.values.length));
  });

  test('every other icon has its adaptive layers and ground on Android', () {
    final colours = File('android/app/src/main/res/values/colors.xml').readAsStringSync();
    for (final icon in others) {
      final stem = 'ic_launcher_${snake(icon.name)}';
      final hex = icon.ground.toARGB32().toRadixString(16).substring(2).toUpperCase();
      expect(colours, contains('<color name="${stem}_background">#$hex</color>'), reason: icon.name);
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(
          File('android/app/src/main/res/mipmap-$density/${stem}_foreground.png').existsSync(),
          isTrue,
          reason: '$density $stem',
        );
      }
    }
  });

  test('every other icon has its launch screen on its ground on Android, which AppIconSwitch.kt names', () {
    final styles = File('android/app/src/main/res/values-v31/styles.xml').readAsStringSync();
    final kotlin = File('android/app/src/main/kotlin/dev/lokumai/bazaar/AppIconSwitch.kt').readAsStringSync();
    for (final icon in others) {
      final ground = '@color/ic_launcher_${snake(icon.name)}_background';
      final style = RegExp(
        '<style name="LaunchTheme.${pascal(icon.name)}">(.*?)</style>',
        dotAll: true,
      ).firstMatch(styles);
      expect(style, isNotNull, reason: icon.name);
      expect(style![1], contains('<item name="android:windowSplashScreenBackground">$ground</item>'));
      expect(style[1], contains('<item name="android:windowBackground">$ground</item>'));
      expect(kotlin, contains('"${icon.name}" to R.style.LaunchTheme_${pascal(icon.name)},'), reason: icon.name);
      expect(
        kotlin,
        contains('"${icon.name}" to R.color.ic_launcher_${snake(icon.name)}_background,'),
        reason: icon.name,
      );
    }
  });

  test('AppIconSwitch.kt names the icons as the Dart side does, Dark first', () {
    final kotlin = File('android/app/src/main/kotlin/dev/lokumai/bazaar/AppIconSwitch.kt').readAsStringSync();
    final pairs = RegExp(r'"(\w+)" to "(Launcher\w+)"').allMatches(kotlin).map((m) => (m[1], m[2])).toList();

    expect(pairs, [for (final icon in BazaarIcon.values) (icon.name, 'Launcher${pascal(icon.name)}')]);
  });

  test('iOS has an alternate icon per other icon, included in every build, named as AppDelegate.swift names it', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final names = [for (final icon in others) 'AppIcon${pascal(icon.name)}'];
    final included = RegExp(r'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "([^"]+)";').allMatches(project);

    expect(included, hasLength(3), reason: 'Debug, Release and Profile');
    for (final match in included) {
      expect(match[1]!.split(' '), names);
    }
    for (final name in names) {
      expect(File('ios/Runner/Assets.xcassets/$name.appiconset/$name.png').existsSync(), isTrue, reason: name);
    }
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final pairs = RegExp(r'"(\w+)": (nil|"(\w+)")').allMatches(swift).map((m) => (m[1], m[3])).toList();
    expect(pairs, [
      for (final icon in BazaarIcon.values) (icon.name, icon == BazaarIcon.dark ? null : 'AppIcon${pascal(icon.name)}'),
    ]);
  });

  test('every icon has its picture for the choice, bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final icon in BazaarIcon.values) {
      expect(File(icon.asset).existsSync(), isTrue, reason: icon.asset);
      expect(pubspec, contains('- ${icon.asset}\n'), reason: icon.asset);
    }
  });
}
