import 'package:flutter/painting.dart';

import 'bazaar_tokens.g.dart';

/// The two variants of a bundled diagram: drawn for a light page or for a dark one.
enum DiagramVariant { light, dark }

/// The ink of the frame around a diagram of [DiagramVariant], drawn over the variant's `diagramThemes` ground (A26).
///
/// The web rebinds the slab tokens on the frame (`bazaar.css:1612-1639`): the light frame takes the Paper ink, the dark
/// frame keeps the Night slab. `tokens.json` does not carry the rebinding, so the pairs come from there and a Dart
/// contrast test holds them to 4.5:1 on the grounds.
final class DiagramFrameInk {
  const DiagramFrameInk._({required this.ink, required this.muted, required this.edge, required this.tool});

  /// Caption and tool text.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// The frame's edge and rules.
  final Color edge;

  /// The tool strip's ground.
  final Color tool;

  static const DiagramFrameInk _light = DiagramFrameInk._(
    ink: BazaarFixedColors.onBarChip,
    muted: BazaarFixedColors.slabArrow,
    edge: BazaarFixedColors.bandB,
    tool: BazaarFixedColors.onBar,
  );

  static const DiagramFrameInk _dark = DiagramFrameInk._(
    ink: BazaarFixedColors.slabOnSurface,
    muted: BazaarFixedColors.slabOnSurfaceMuted,
    edge: BazaarFixedColors.slabLine,
    tool: BazaarFixedColors.slabSurfaceRaised,
  );

  /// The frame ink for [variant].
  static DiagramFrameInk of(DiagramVariant variant) => switch (variant) {
    DiagramVariant.light => _light,
    DiagramVariant.dark => _dark,
  };
}
