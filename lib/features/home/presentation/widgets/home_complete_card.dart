import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home's head once every written module of the track is completed: a line saying so and the way to the catalog, which
/// shows the completion (plan 1AB). While a module is still to read, the band over the navigation offers it instead
/// (plan 10.4), and Home has no card at its head.
class HomeCompleteCard extends StatelessWidget {
  const HomeCompleteCard({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return BazaarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(s.home_all_complete, style: theme.textTheme.bodyLarge),
          OutlinedButton(onPressed: () => context.go(BazaarPaths.catalog(track)), child: Text(s.home_see_catalog)),
        ],
      ),
    );
  }
}
