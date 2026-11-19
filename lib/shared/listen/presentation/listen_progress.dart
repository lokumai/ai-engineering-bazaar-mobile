import 'package:flutter/material.dart';

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';

/// How far along a module read aloud is, as a thin line along the top of its player or bar, over the page's hairline.
/// Decoration: the player says it in words.
class ListenProgress extends StatelessWidget {
  const ListenProgress({super.key, required this.state});

  final ListenOn state;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final share = state.count == 0 ? 0.0 : (state.index + 1) / state.count;
    return ExcludeSemantics(
      child: SizedBox(
        height: 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Divider(height: 0.5, thickness: 0.5, color: colors.line),
            ),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: share.clamp(0, 1),
              child: ColoredBox(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
