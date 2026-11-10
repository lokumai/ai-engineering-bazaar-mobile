import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How the bazaar works, from Settings (`/settings/guide`), in four short points: the levels, the modules, marking what
/// is finished, and the course on the device. It was Welcome's last step (plan 1X) until the story of the Bazaar took
/// that place (plan 3.5).
class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate mounts the router only once the content is ready.
      final state => throw StateError('The guide needs ready content, not $state'),
    };
    final points = [
      (Icons.layers_outlined, s.guide_levels_title, s.guide_levels(index.levels.length, index.levels.first.title)),
      (Icons.menu_book_outlined, s.guide_modules_title, s.guide_modules),
      (Icons.check_circle_outline, s.guide_complete_title, s.guide_complete),
      (Icons.cloud_off_outlined, s.guide_offline_title, s.guide_offline),
    ];
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Semantics(
              header: true,
              child: Text(
                s.guide_title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(color: colors.onSurfaceTitle),
              ),
            ),
            const SizedBox(height: 4),
            for (final (icon, title, body) in points)
              BazaarCard(
                child: MergeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
                      Icon(icon, color: colors.primary),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                            Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
