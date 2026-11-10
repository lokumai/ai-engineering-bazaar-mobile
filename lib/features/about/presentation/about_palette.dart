import 'package:flutter/painting.dart';

/// The story's own colours and faces, transcribed from the web's About page (`src/components/about/palette.ts`, the
/// grounds of "Dusk to dawn", B2, and the inks on them; web D115). They are the page's art, as the opening's colours
/// are Welcome's, so they stay the same in the app's light and dark themes: the story is told at dusk whatever the
/// reader chose, and arrives at dawn for the motto.
abstract final class AboutPalette {
  /// The opening's ground, under the gate and the title.
  static const groundOpening = Color(0xff15152f);

  /// One ground per section, in order; a sixth section takes the first again, as on the web.
  static const grounds = [
    Color(0xff2a1417),
    Color(0xff231629),
    Color(0xff111536),
    Color(0xff0d2422),
    Color(0xff271d0e),
  ];

  /// The motto's ground: dawn, on sand.
  static const groundDawn = Color(0xffece1cb);

  /// The opening's glaze, for the first word of the title.
  static const hueOpening = Color(0xffe0b86e);

  /// Each section's glaze, lifted for its dark ground, in the same order.
  static const hues = [Color(0xffdf8c72), Color(0xffbb93c6), Color(0xffa3aae6), Color(0xff72c4bc), Color(0xffe0b86e)];

  /// The motto's glaze, for its second line and the dot that ends the hand's line.
  static const hueDawn = Color(0xff8a6328);

  // Inks on the dark ground.
  static const ink = Color(0xffe7e3d8);
  static const title = Color(0xfff4efe5);
  static const muted = Color(0xffa8acb8);
  static const line = Color(0x4de7e3d8);
  static const gold = Color(0xffc8a078);

  // Inks at dawn, on the motto's sand.
  static const dawnInk = Color(0xff20242e);
  static const dawnTitle = Color(0xff1b1b47);
  static const dawnMuted = Color(0xff5d584c);
  static const dawnLine = Color(0x4d1b1b47);
  static const dawnGold = Color(0xff9a7238);

  /// The edge of the lamp's reach, darkening the ground's corners.
  static const vignette = Color(0x8c04040c);

  static Color ground(int section) => grounds[section % grounds.length];
  static Color hue(int section) => hues[section % hues.length];

  /// The display face of the web's headings (Fraunces, `next/font`), bundled at the web's settings: SOFT 50, WONK 0.
  static const display = 'Fraunces';

  /// Fraunces at [size], [weight] on its variable axis and optical size [optical], as the web sets each heading.
  static TextStyle fraunces({
    required double size,
    required double weight,
    required Color color,
    double optical = 72,
    bool italic = false,
    double height = 1.2,
    double tracking = 0,
  }) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation.weight(weight), FontVariation.opticalSize(optical)],
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: height,
    letterSpacing: tracking * size,
  );
}
