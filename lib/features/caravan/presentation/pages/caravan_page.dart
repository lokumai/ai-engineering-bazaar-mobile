import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_scene.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_radius.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Caravan tab at `/caravan` (plan 3.1): the web's trends timeline, which the bundle does not carry yet, so the page
/// says the Caravan is coming soon (the owner, 2026-11-13), over a caravan walking in at dusk, with the way to the
/// catalog. The timeline reaches the app with its document in the bundle (web D116, `api/v1/caravan/<lang>.json`) and
/// the bar's pages (web change 5.7).
class CaravanPage extends StatelessWidget {
  const CaravanPage({super.key});

  /// The height of the scene.
  static const double sceneHeight = 188;

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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: const Column(
            children: [
              SizedBox(height: sceneHeight, width: double.infinity, child: CaravanScene()),
              LatticeBand(thin: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BazaarFixedColors.caution,
              borderRadius: BorderRadius.circular(AppSpacing.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Text(
                s.caravan_soon,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: BazaarFixedColors.onCaution,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            s.caravan_soon_title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          s.caravan_soon_body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: FilledButton(onPressed: () => context.go(BazaarPaths.catalog(track)), child: Text(s.nav_catalog)),
        ),
      ],
    );
  }
}
