// Draws every app icon (lib/shared/app_icon/bazaar_icon.dart) from the pocket model's robot (plan 9.10), and writes
// the pictures each side needs:
//
// - assets/app_icon/<name>.png, the picture of the choice;
// - ios/Runner/Assets.xcassets/AppIcon<Name>.appiconset/, the default's in AppIcon.appiconset, with its dark-mode
//   copy, so iOS does not darken a cream icon itself;
// - android/app/src/main/res/mipmap-<density>/ic_launcher_<name>_foreground.png, the default's as
//   ic_launcher_foreground.png, with the default's legacy ic_launcher.png and the monochrome layer of themed icons.
//
// Run it after a change to the robot's drawing or to the icons:
//   fvm flutter test tool/render_app_icons.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/features/pocket_model/presentation/app_icon_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/robot_portrait.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The share of the side the head's box takes on a whole icon, which the phone rounds itself.
const _whole = 0.84;

/// The share on Android's adaptive foreground, whose mask may be a circle 66 of its 108 units across.
const _adaptive = 0.55;

const _densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

String _pascal(String name) => name[0].toUpperCase() + name.substring(1);
String _snake(String name) => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

Future<List<int>> _png(int side, void Function(Canvas canvas, Size size) paint) async {
  final recorder = ui.PictureRecorder();
  final size = Size.square(side.toDouble());
  paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(side, side);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

/// The same picture as an RGB PNG with no alpha channel: App Store Connect refuses an app icon that has one, even
/// when every pixel is opaque (ITMS-90717). dart:ui writes only RGBA, so the PNG is put together here.
Future<List<int>> _opaquePng(int side, void Function(Canvas canvas, Size size) paint) async {
  final recorder = ui.PictureRecorder();
  final size = Size.square(side.toDouble());
  paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(side, side);
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();
  final rows = BytesBuilder();
  for (var y = 0; y < side; y++) {
    rows.addByte(0); // no filter
    for (var x = 0; x < side; x++) {
      final i = (y * side + x) * 4;
      rows.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  List<int> chunk(String type, List<int> data) {
    final body = [...ascii.encode(type), ...data];
    return [..._uint32(data.length), ...body, ..._uint32(_crc32(body))];
  }

  return [
    ...[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    // width, height, bit depth 8, colour type 2 (RGB), compression, filter and interlace 0
    ...chunk('IHDR', [..._uint32(side), ..._uint32(side), 8, 2, 0, 0, 0]),
    ...chunk('IDAT', ZLibCodec(level: 9).encode(rows.takeBytes())),
    ...chunk('IEND', const []),
  ];
}

List<int> _uint32(int value) => [value >> 24 & 0xFF, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF];

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Future<void> _write(String path, Future<List<int>> bytes) async {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(await bytes);
}

Future<List<int>> _icon(BazaarIcon icon, int side, {bool ground = true, double fill = _whole}) => _png(
  side,
  (canvas, size) => RobotIconPainter(
    outfit: appIconOutfit(icon.robot),
    ground: ground ? icon.ground : null,
    fill: fill,
  ).paint(canvas, size),
);

void main() {
  test('render the app icons', () async {
    final iosSets = 'ios/Runner/Assets.xcassets';
    for (final icon in BazaarIcon.values) {
      final isDefault = icon == BazaarIcon.defaultIcon;
      await _write(icon.asset, _icon(icon, 256));

      final ios = isDefault ? 'AppIcon' : 'AppIcon${_pascal(icon.name)}';
      final picture = await _opaquePng(
        1024,
        (canvas, size) =>
            RobotIconPainter(outfit: appIconOutfit(icon.robot), ground: icon.ground, fill: _whole).paint(canvas, size),
      );
      await _write('$iosSets/$ios.appiconset/$ios.png', Future.value(picture));
      await _write('$iosSets/$ios.appiconset/${ios}DarkMode.png', Future.value(picture));
      File('$iosSets/$ios.appiconset/Contents.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({
          'images': [
            {'filename': '$ios.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'},
            {
              'appearances': [
                {'appearance': 'luminosity', 'value': 'dark'},
              ],
              'filename': '${ios}DarkMode.png',
              'idiom': 'universal',
              'platform': 'ios',
              'size': '1024x1024',
            },
          ],
          'info': {'author': 'xcode', 'version': 1},
        })}\n',
      );

      final stem = isDefault ? 'ic_launcher' : 'ic_launcher_${_snake(icon.name)}';
      for (final MapEntry(key: density, value: scale) in _densities.entries) {
        final res = 'android/app/src/main/res/mipmap-$density';
        await _write('$res/${stem}_foreground.png', _icon(icon, (108 * scale).round(), ground: false, fill: _adaptive));
        if (isDefault) {
          await _write('$res/ic_launcher.png', _icon(icon, (48 * scale).round()));
          // The themed icon's layer: the robot's light lines, its rim, eyes and hat, where its dark screen is clear.
          await _write(
            '$res/ic_launcher_monochrome.png',
            _png((108 * scale).round(), (canvas, size) {
              canvas.saveLayer(
                Offset.zero & size,
                Paint()
                  ..colorFilter = const ColorFilter.matrix([
                    0, 0, 0, 0, 255, //
                    0, 0, 0, 0, 255, //
                    0, 0, 0, 0, 255, //
                    1.4, 2.6, 0.5, 0, -110, //
                  ]),
              );
              RobotIconPainter(outfit: appIconOutfit(icon.robot), fill: _adaptive).paint(canvas, size);
              canvas.restore();
            }),
          );
        }
      }
    }
  });
}
