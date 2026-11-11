import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:flutter/material.dart';

/// The offline note, a quiet line at the foot of Home: the whole course ships in the app and reads offline, and every start asks the
/// site for a newer version (R10, R11). The mockup's "8 modules downloaded" is replaced by this true line (plan
/// Phase 1, decisions taken).
class HomeOfflineNote extends StatelessWidget {
  const HomeOfflineNote({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return BazaarRow(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const ExcludeSemantics(child: Icon(Icons.download_done, color: BazaarFixedColors.success)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(s.home_offline_title, style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle)),
                Text(s.home_offline_body, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
