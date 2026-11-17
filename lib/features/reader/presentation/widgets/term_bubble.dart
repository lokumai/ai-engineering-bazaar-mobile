import 'package:flutter/material.dart';

import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';

/// A term's definition in a bubble over the module's text (plan 13.9): the term and its definition, nothing more. It
/// stands above the place tapped, or under it near the top, and in the middle of the screen when a screen reader opened
/// it.
class TermBubble extends StatelessWidget {
  const TermBubble({super.key, required this.term, required this.at});

  final GlossaryTerm term;

  /// Where the term was tapped, in the page's own box; null for a screen reader's tap.
  final Offset? at;

  /// The bubble's widest.
  static const double _widest = 320;

  /// How far the bubble stands from the place tapped.
  static const double _gap = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final bubble = Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        key: const ValueKey('term-bubble'),
        color: colors.surfaceRaised,
        elevation: 6,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.lineStrong),
          borderRadius: const BorderRadius.all(BazaarRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(term.name, style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle)),
              InlineText(
                inlines: term.definition,
                style: TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface),
                onLink: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 2 * AppSpacing.lg).clamp(0.0, _widest);
        final local = at;
        if (local == null) {
          return Center(
            child: SizedBox(width: width, child: bubble),
          );
        }
        final left = (local.dx - width / 2).clamp(AppSpacing.lg, constraints.maxWidth - AppSpacing.lg - width);
        // Under the place tapped in the top third, above it lower down, so it never covers the term.
        final below = local.dy < constraints.maxHeight / 3;
        return Stack(
          children: [
            Positioned(
              left: left,
              width: width,
              top: below ? local.dy + _gap : null,
              bottom: below ? null : constraints.maxHeight - local.dy + _gap,
              child: bubble,
            ),
          ],
        );
      },
    );
  }
}
