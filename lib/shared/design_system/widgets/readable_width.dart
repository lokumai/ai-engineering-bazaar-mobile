import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Holds [child] to [maxWidth] in the middle of a wide screen, a tablet's, so lines and cards keep a phone's measure;
/// on a phone it changes nothing. The child gets the width and the height exactly, as it would without it.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = ReadableWidth.text});

  /// The widest a page's content is drawn: lines of about 80 characters in the reading face.
  static const double text = 720;

  /// The widest a module's page is drawn, with its sections beside its text (plan 12.10).
  static const double withSections = text + sections + gap;

  /// The width of a module's sections beside its text, and the gap between them.
  static const double sections = 260;
  static const double gap = 32;

  /// The widest [child] is drawn.
  final double maxWidth;

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth <= maxWidth || !constraints.hasBoundedHeight) return child;
      return Center(
        child: SizedBox(width: math.min(maxWidth, constraints.maxWidth), height: constraints.maxHeight, child: child),
      );
    },
  );
}
