import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/presentation/app_icon_choices.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/material.dart';

/// The app icon page, from Settings' App icon row (the owner, 2026-11-14): the icons as pictures, the one in use
/// marked ([AppIconChoices]). A tap makes that icon the app's, on the home screen and in the opening; a note says when
/// the phone shows it.
class AppIconPage extends StatelessWidget {
  const AppIconPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final note = switch (theme.platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => s.app_icon_note_ios,
      _ => s.app_icon_note_android,
    };
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionRule(title: s.settings_app_icon),
            const SizedBox(height: AppSpacing.lg),
            const AppIconChoices(),
            const SizedBox(height: AppSpacing.xl),
            Text(note, style: theme.textTheme.bodyMedium?.copyWith(color: context.bazaarColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}
