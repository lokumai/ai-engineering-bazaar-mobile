import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Caravan tab at `/caravan` (plan 3.1): the web's trends timeline, which the bundle does not carry yet, so the page
/// says it is under maintenance, with the way to the catalog, as the web's first Caravan page did (the owner,
/// 2026-11-11). The web's page still shows sample trends and its trends file holds none; the timeline reaches the app
/// with its document in the bundle (web D116, `api/v1/caravan/<lang>.json`) and the bar's pages (web change 5.7).
class CaravanPage extends StatelessWidget {
  const CaravanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final track = context.watch<TrackCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // The page's name at the head of its content, as on the Quiz tab and the catalog (plan 1AW).
        SectionRule(title: s.nav_caravan),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            s.caravan_maintenance,
            style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(s.caravan_maintenance_body, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceMuted)),
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(onPressed: () => context.go(BazaarPaths.catalog(track)), child: Text(s.nav_catalog)),
        ),
      ],
    );
  }
}
