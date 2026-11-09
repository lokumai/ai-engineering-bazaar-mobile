import 'package:flutter/widgets.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';

/// The hue of the level at [position] (0-based, in the index's level order): the web binds a level to the category
/// colour of its 1-based place in the curriculum (`CategoryLabel.order`, `src/lib/route-labels.ts`). Five category
/// colours exist; a sixth level starts the cycle again.
///
/// A hue marks edges, keys, dials and meters only, never text (spec 3.8: no chromatic token is safe for text).
Color levelHue(BuildContext context, int position) {
  final colors = context.bazaarColors;
  return switch (position % 5) {
    0 => BazaarFixedColors.category1,
    1 => colors.category2,
    2 => colors.category3,
    3 => BazaarFixedColors.category4,
    _ => colors.category5,
  };
}
