import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Welcome's last screen, on the first launch only (plan 1X): how the bazaar works, in four short points (the levels,
/// the modules, marking what is finished, and the course on the device), then the way into the catalog, [onDone].
class WelcomeIntroView extends StatelessWidget {
  const WelcomeIntroView({super.key, required this.onDone});

  final VoidCallback onDone;

  static const doneKey = Key('welcome-intro-done');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate shows Welcome only once the content is ready.
      final state => throw StateError('Welcome needs ready content, not $state'),
    };
    final points = [
      (
        Icons.layers_outlined,
        s.welcome_intro_levels_title,
        s.welcome_intro_levels(index.levels.length, index.levels.first.title),
      ),
      (Icons.menu_book_outlined, s.welcome_intro_modules_title, s.welcome_intro_modules),
      (Icons.check_circle_outline, s.welcome_intro_complete_title, s.welcome_intro_complete),
      (Icons.cloud_off_outlined, s.welcome_intro_offline_title, s.welcome_intro_offline),
    ];
    // The bar of every page, so the steps look like the app they lead into (plan 1Z).
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BazaarBar(),
            const LatticeBand(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        s.welcome_intro_title,
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
                                    Text(
                                      title,
                                      style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                                    ),
                                    Text(
                                      body,
                                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      key: doneKey,
                      onPressed: onDone,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      icon: const Icon(Icons.arrow_forward),
                      iconAlignment: IconAlignment.end,
                      label: Text(s.welcome_intro_start),
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
