import 'dart:ui';

/// The WCAG contrast ratio of [foreground] on [background], from [Color.computeLuminance]: (lighter + 0.05) over
/// (darker + 0.05). Both colours must be opaque; a translucent one has no ratio without the ground under it.
double contrastRatio(Color foreground, Color background) {
  for (final (name, color) in [('foreground', foreground), ('background', background)]) {
    if (color.a != 1.0) throw ArgumentError.value(color, name, 'must be opaque');
  }
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final (lighter, darker) = a >= b ? (a, b) : (b, a);
  return (lighter + 0.05) / (darker + 0.05);
}
