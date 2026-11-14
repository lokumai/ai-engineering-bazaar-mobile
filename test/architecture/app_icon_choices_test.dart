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
  // On iOS the default is the primary icon, AppIcon; every other icon is an alternate.
  final alternates = BazaarIcon.values.where((icon) => icon != BazaarIcon.defaultIcon);
  String androidResource(BazaarIcon icon) =>
      icon == BazaarIcon.defaultIcon ? 'ic_launcher' : 'ic_launcher_${snake(icon.name)}';
  String iosName(BazaarIcon icon) => 'AppIcon${pascal(icon.name)}';

  test(
    'the Android manifest has one launcher entry per icon in their order, only the default enabled, each its own icon',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      final aliases = RegExp(r'<activity-alias\s+([^>]*)>').allMatches(manifest).map((m) => m[1]!).toList();

      expect(aliases, hasLength(BazaarIcon.values.length));
      for (final (i, icon) in BazaarIcon.values.indexed) {
        final alias = aliases[i];
        final resource = androidResource(icon);
        expect(alias, contains('android:name=".Launcher${pascal(icon.name)}"'), reason: icon.name);
        expect(alias, contains('android:icon="@mipmap/$resource"'), reason: icon.name);
        expect(alias, contains('android:enabled="${icon == BazaarIcon.defaultIcon}"'), reason: icon.name);
        expect(File('android/app/src/main/res/mipmap-anydpi-v26/$resource.xml').existsSync(), isTrue, reason: resource);
      }
      // The system shows the default's icon for the app itself, in its settings and lists.
      expect(
        RegExp(r'<application\s[^>]*android:icon="@mipmap/(\w+)"').firstMatch(manifest)![1],
        androidResource(BazaarIcon.defaultIcon),
      );
      // Only the entries launch the app, so exactly one icon is in the launcher.
      expect(RegExp('android.intent.category.LAUNCHER').allMatches(manifest), hasLength(BazaarIcon.values.length));
    },
  );

  // The ground of an icon on Android: the dark page colour or the cream one.
  String androidGround(BazaarIcon icon) => switch (icon.backdrop) {
    AppIconGround.dark => 'ic_launcher_background',
    AppIconGround.cream => 'ic_launcher_cream_background',
  };

  test('every icon has its adaptive layers on its ground on Android', () {
    final colours = File('android/app/src/main/res/values/colors.xml').readAsStringSync();
    for (final ground in AppIconGround.values) {
      final hex = ground.colour.toARGB32().toRadixString(16).substring(2).toUpperCase();
      final name = ground == AppIconGround.dark ? 'ic_launcher_background' : 'ic_launcher_cream_background';
      expect(colours, contains('<color name="$name">#$hex</color>'), reason: ground.name);
    }
    for (final icon in BazaarIcon.values) {
      final stem = androidResource(icon);
      final adaptive = File('android/app/src/main/res/mipmap-anydpi-v26/$stem.xml').readAsStringSync();
      expect(adaptive, contains('<background android:drawable="@color/${androidGround(icon)}" />'), reason: stem);
      expect(adaptive, contains('<foreground android:drawable="@mipmap/${stem}_foreground" />'), reason: stem);
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(
          File('android/app/src/main/res/mipmap-$density/${stem}_foreground.png').existsSync(),
          isTrue,
          reason: '$density $stem',
        );
      }
    }
  });

  test('every icon has its launch screen on its ground on Android, which AppIconSwitch.kt names', () {
    final styles = File('android/app/src/main/res/values-v31/styles.xml').readAsStringSync();
    expect(
      RegExp('<style name="LaunchTheme.Cream">(.*?)</style>', dotAll: true).firstMatch(styles)![1],
      contains('<item name="android:windowSplashScreenBackground">@color/ic_launcher_cream_background</item>'),
    );
    final kotlin = File('android/app/src/main/kotlin/dev/lokumai/bazaar/AppIconSwitch.kt').readAsStringSync();
    for (final icon in BazaarIcon.values) {
      final (theme, colour) = switch (icon.backdrop) {
        AppIconGround.dark => ('LaunchTheme', 'bazaar_page'),
        AppIconGround.cream => ('LaunchTheme_Cream', 'ic_launcher_cream_background'),
      };
      expect(kotlin, contains('"${icon.name}" to R.style.$theme,'), reason: icon.name);
      expect(kotlin, contains('"${icon.name}" to R.color.$colour,'), reason: icon.name);
    }
  });

  test('AppIconSwitch.kt names the icons as the Dart side does, the default first', () {
    final kotlin = File('android/app/src/main/kotlin/dev/lokumai/bazaar/AppIconSwitch.kt').readAsStringSync();
    final pairs = RegExp(r'"(\w+)" to "(Launcher\w+)"').allMatches(kotlin).map((m) => (m[1], m[2])).toList();

    expect(pairs, [for (final icon in BazaarIcon.values) (icon.name, 'Launcher${pascal(icon.name)}')]);
  });

  test('iOS has the default as its primary icon and an alternate per other icon, in every build, as AppDelegate.swift names them', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final names = [for (final icon in alternates) iosName(icon)];
    final included = RegExp(r'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "([^"]+)";').allMatches(project);

    expect(included, hasLength(3), reason: 'Debug, Release and Profile');
    for (final match in included) {
      expect(match[1]!.split(' '), names);
    }
    final primary = 'ios/Runner/Assets.xcassets/AppIcon${pascal(BazaarIcon.defaultIcon.name)}.appiconset';
    expect(Directory(primary).existsSync(), isFalse, reason: 'the default is the primary icon, not an alternate');
    for (final name in ['AppIcon', ...names]) {
      final set = 'ios/Runner/Assets.xcassets/$name.appiconset';
      expect(File('$set/$name.png').existsSync(), isTrue, reason: name);
      // Its own picture in dark mode too: without one iOS darkens a light icon itself, and Cream then looked like
      // the default on an iPhone in dark mode (the owner, 2026-11-14).
      expect(
        File('$set/${name}DarkMode.png').readAsBytesSync(),
        File('$set/$name.png').readAsBytesSync(),
        reason: name,
      );
      expect(
        RegExp(r'"appearance": "luminosity",\s*"value": "dark"\s*\}\s*\],\s*"filename": "' + name + r'DarkMode\.png"')
            .hasMatch(File('$set/Contents.json').readAsStringSync()),
        isTrue,
        reason: name,
      );
    }
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final pairs = RegExp(r'"(\w+)": (nil|"(\w+)")').allMatches(swift).map((m) => (m[1], m[3])).toList();
    expect(pairs, [
      for (final icon in BazaarIcon.values) (icon.name, icon == BazaarIcon.defaultIcon ? null : iosName(icon)),
    ]);
  });

  test('AppDelegate.swift paints the launch picture in the ground of each icon, as the Dart side has it', () {
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final grounds = RegExp(r'"(\w+)": 0x([0-9a-f]{6}),').allMatches(swift).map((m) => (m[1], m[2])).toList();

    expect(grounds, [
      for (final icon in BazaarIcon.values) (icon.name, icon.ground.toARGB32().toRadixString(16).substring(2)),
    ]);
  });

  // Flutter shows the launch screen, dark for every icon, until its first frame: the app's screen shows the ground of
  // the icon last named instead, or a non-dark icon flashes dark on opening (the owner, 2026-11-15).
  test('the iOS app screen is BazaarViewController, which shows the kept ground until the first frame', () {
    final storyboard = File('ios/Runner/Base.lproj/Main.storyboard').readAsStringSync();
    expect(storyboard, contains('customClass="BazaarViewController" customModule="Runner"'));
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift, contains('class BazaarViewController: FlutterViewController {'));
    expect(swift, contains('splashScreenView = splash'));
    expect(swift, contains('LaunchPicture.keep(ground)'));
  });

  test('every icon has its picture for the choice, bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final icon in BazaarIcon.values) {
      expect(File(icon.asset).existsSync(), isTrue, reason: icon.asset);
      expect(pubspec, contains('- ${icon.asset}\n'), reason: icon.asset);
    }
  });
}
