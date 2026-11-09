import 'package:flutter/material.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';

/// The corner shape of a [BazaarCard]: the web's `--shape-arch` and `--shape-leaf`, or the plain `--radius-lg`.
enum BazaarCardShape { plain, arch, leaf }

/// A raised card on the page ground with a hairline edge (the mockup's white cards on `#fdfbf7`), in one of the
/// [BazaarCardShape]s, with an optional [accent] edge along the top.
///
/// With [onTap], the whole card is one button: [semanticLabel] then names it, or its texts do when null.
class BazaarCard extends StatelessWidget {
  const BazaarCard({
    super.key,
    required this.child,
    this.shape = BazaarCardShape.plain,
    this.accent,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.semanticLabel,
  });

  final Widget child;
  final BazaarCardShape shape;

  /// A 3 px edge along the top, such as the level hue; none when null.
  final Color? accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  /// The [BorderRadius] of [shape].
  static BorderRadius radiusOf(BazaarCardShape shape) => switch (shape) {
    BazaarCardShape.plain => const BorderRadius.all(BazaarRadii.lg),
    BazaarCardShape.arch => BazaarShapes.arch,
    BazaarCardShape.leaf => BazaarShapes.leaf,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final radius = radiusOf(shape);
    Widget content = Padding(padding: padding, child: child);
    if (accent case final accent?) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: accent, width: 3)),
        ),
        child: content,
      );
    }
    final card = Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (onTap == null) return card;
    if (semanticLabel case final label?) {
      return Semantics(container: true, button: true, label: label, onTap: onTap, excludeSemantics: true, child: card);
    }
    return MergeSemantics(child: Semantics(button: true, child: card));
  }
}
