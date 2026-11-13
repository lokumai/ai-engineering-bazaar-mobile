import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_name.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The key of [icon]'s choice on the app icon page.
Key appIconChoiceKey(BazaarIcon icon) => ValueKey('app-icon-${icon.name}');

/// The app icon page, from Settings' App icon row (the owner, 2026-11-14): the six icons as pictures, the one in use
/// marked. A tap makes that icon the app's, on the home screen and in the opening; a note says when the phone shows it.
class AppIconPage extends StatelessWidget {
  const AppIconPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final current = context.watch<AppIconCubit>().state.icon;
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
            LayoutBuilder(
              builder: (context, constraints) {
                // Three to a row, so the six stand in two rows (the owner, 2026-11-14).
                const columns = 3;
                final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.lg,
                  children: [
                    for (final icon in BazaarIcon.values)
                      SizedBox(
                        width: width,
                        child: _Choice(
                          key: appIconChoiceKey(icon),
                          icon: icon,
                          selected: icon == current,
                          onTap: () => context.read<AppIconCubit>().choose(icon),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(note, style: theme.textTheme.bodyMedium?.copyWith(color: context.bazaarColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

/// One icon: its picture, ringed when it is the one in use, and its name under it (the default's says so).
class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.icon, required this.selected, required this.onTap});

  final BazaarIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final name = appIconName(s, icon);
    final isDefault = icon == BazaarIcon.dark;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: isDefault ? '$name, ${s.app_icon_default}' : name,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            spacing: AppSpacing.sm,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  border: Border.all(color: selected ? colors.primary : Colors.transparent, width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: AspectRatio(aspectRatio: 1, child: Image.asset(icon.asset, fit: BoxFit.cover)),
                  ),
                ),
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceTitle,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
              if (isDefault)
                Text(
                  s.app_icon_default,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
