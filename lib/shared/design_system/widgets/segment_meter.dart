import 'package:flutter/widgets.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';

/// A row of [total] equal segments, the first [done] filled with [color] and the one at [current], when given, with
/// [currentColor] (the mockup's level meter and the quiz's step bar).
///
/// The meter is an image named by [semanticLabel], since its segments say nothing one by one.
class SegmentMeter extends StatelessWidget {
  const SegmentMeter({
    super.key,
    required this.done,
    required this.total,
    required this.color,
    required this.semanticLabel,
    this.current,
    this.currentColor,
    this.height = 6,
    this.gap = 4,
  });

  final int done;
  final int total;
  final Color color;
  final String semanticLabel;

  /// The 0-based segment drawn in [currentColor]; null when no segment is current.
  final int? current;
  final Color? currentColor;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final track = context.bazaarColors.surfaceSunken;
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Row(
          spacing: gap,
          // A segment has no child, so it takes the row's height only when stretched.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == current && currentColor != null ? currentColor : (i < done ? color : track),
                    borderRadius: const BorderRadius.all(BazaarRadii.hair),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
