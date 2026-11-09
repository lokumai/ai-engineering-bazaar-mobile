import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

const _bullet = '•';

/// What the module teaches (web `Objectives.tsx:27-58`, `design/bazaar.css:1354-1360`): a bold line, then the
/// objectives as a bulleted list, on a leaf-shaped card.
class ObjectivesCard extends StatelessWidget {
  const ObjectivesCard({super.key, required this.objectives});

  final List<String> objectives;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final style = TextStyle(fontSize: BazaarType.body.size, height: BazaarType.body.height, color: colors.onSurface);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: BazaarShapes.leaf,
      ),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(S.of(context).reader_objectives, style: style.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          for (final objective in objectives)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: ExcludeSemantics(child: Text(_bullet, style: style)),
                  ),
                  Expanded(child: Text(objective, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
