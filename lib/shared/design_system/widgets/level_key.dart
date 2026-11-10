import 'package:flutter/widgets.dart';

import '../bazaar_tokens.g.dart';

/// The small square that keys a level to its hue, beside the level's name. Decoration only: the name carries the
/// meaning, so the square is hidden from assistive technology.
class LevelKey extends StatelessWidget {
  const LevelKey({super.key, required this.color, this.size = 9});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(BazaarRadii.hair)),
      ),
    );
  }
}
