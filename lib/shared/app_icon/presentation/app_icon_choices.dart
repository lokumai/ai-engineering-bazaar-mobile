import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_name.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The key of [icon]'s choice among [AppIconChoices].
Key appIconChoiceKey(BazaarIcon icon) => ValueKey('app-icon-${icon.name}');

/// The six icons as pictures, three to a row, the one in use ringed; a tap makes that icon the app's. Settings' app
/// icon page and Welcome's first step both show it. The pictures carry no names under them (the owner, 2026-11-14);
/// a screen reader still hears each name.
class AppIconChoices extends StatelessWidget {
  const AppIconChoices({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppIconCubit>().state.icon;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three to a row, so the six stand in two rows (the owner, 2026-11-14).
        const columns = 3;
        final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
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
    );
  }
}

/// One icon: its picture, ringed when it is the one in use.
class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.icon, required this.selected, required this.onTap});

  final BazaarIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = appIconName(s, icon);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: icon == BazaarIcon.dark ? '$name, ${s.app_icon_default}' : name,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            border: Border.all(color: selected ? context.bazaarColors.primary : Colors.transparent, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: AspectRatio(aspectRatio: 1, child: Image.asset(icon.asset, fit: BoxFit.cover)),
            ),
          ),
        ),
      ),
    );
  }
}
