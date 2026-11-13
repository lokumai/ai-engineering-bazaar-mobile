import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Holds [child] to [maxWidth] in the middle of a wide screen, a tablet's, so lines and cards keep a phone's measure;
/// on a phone it changes nothing. The child gets the width and the height exactly, as it would without it.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  /// The widest a page's content is drawn: lines of about 80 characters in the reading face.
  static const double maxWidth = 720;

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
