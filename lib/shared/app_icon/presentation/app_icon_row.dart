import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_name.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The App icon row of Settings and of Welcome's first step: the icon in use as a large picture, the row's name and
/// an arrow; [onTap] opens the six icons. The icon's name is not written under it (the owner, 2026-11-14); a screen
/// reader hears it.
class AppIconRow extends StatelessWidget {
  const AppIconRow({
    super.key,
    required this.onTap,
    this.picture = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
  });

  final VoidCallback onTap;

  /// The picture's side.
  final double picture;

  /// Around the row; [BazaarRow]'s by default.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final icon = context.watch<AppIconCubit>().state.icon;
    return BazaarRow(
      onTap: onTap,
      padding: padding,
      semanticLabel: '${s.settings_app_icon}, ${appIconName(s, icon)}',
      child: Row(
        spacing: AppSpacing.md,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(picture * 0.23)),
            child: Image.asset(icon.asset, width: picture, height: picture),
          ),
          Expanded(
            child: Text(
              s.settings_app_icon,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle),
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
        ],
      ),
    );
  }
}
