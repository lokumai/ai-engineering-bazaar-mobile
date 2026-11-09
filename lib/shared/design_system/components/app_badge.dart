import 'package:flutter/material.dart';

import '../bazaar_theme.dart';
import '../bazaar_tokens.g.dart';
import '../tokens/app_spacing.dart';

/// Badge variants.
enum AppBadgeVariant { filled, secondary, destructive, outline, success, warning }

/// A small status/count indicator label.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({super.key, required this.label, this.variant = AppBadgeVariant.filled, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, edge) = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: edge == null ? null : Border.all(color: edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          if (icon != null) Icon(icon, size: 12, color: fg),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// The ground, text and border of the variant. Chromatic tokens never carry badge text (A18): a status shows in the
  /// border, and the text stays on-surface or on its tested pair.
  (Color bg, Color fg, Color? edge) _colors(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = context.bazaarColors;
    return switch (variant) {
      AppBadgeVariant.filled => (cs.primary, cs.onPrimary, null),
      AppBadgeVariant.secondary || AppBadgeVariant.outline => (c.surfaceRaised, c.onSurface, c.line),
      AppBadgeVariant.destructive => (c.surfaceRaised, c.onSurface, c.fault),
      AppBadgeVariant.success => (c.surfaceRaised, c.onSurface, BazaarFixedColors.success),
      AppBadgeVariant.warning => (BazaarFixedColors.caution, BazaarFixedColors.onCaution, null),
    };
  }
}
