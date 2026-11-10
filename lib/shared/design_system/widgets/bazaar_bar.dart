import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The top of every page, on the page's ground (owner's review, 2026-11-10: the navy bar is gone): a back button when
/// [onBack] is given and [title], with [accent] before the title on a level's page or a module's, under the
/// [BazaarStatusStrip] unless [statusStrip] is false. A page with neither a back button nor a title has no row, only
/// the strip. The shell places it over the router's pages and the thin lattice band under it, and Welcome's steps
/// over theirs (plan 1Z).
class BazaarBar extends StatelessWidget {
  const BazaarBar({super.key, this.onBack, this.title, this.accent, this.statusStrip = true});

  /// Goes back to the page below; null shows no back button.
  final VoidCallback? onBack;

  /// The name of the page under the bar; null leaves the bar without a title, as on Home and Welcome's steps.
  final String? title;

  /// The hue of the level the page belongs to; null on a page of no level.
  final Color? accent;

  /// Whether the bar draws the status strip over itself; the shell draws its own, which stays while the bar folds away.
  final bool statusStrip;

  /// The side of the [accent] square at text scale 1; it grows with the title.
  static const double _key = 12;

  /// The row's least height: thinner than the mockup's 58 (plan 1R, and 40 after the owner's review).
  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final accent = title == null ? null : this.accent;
    final key = MediaQuery.textScalerOf(context).scale(_key);
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle);
    final Widget row;
    if (onBack == null && title == null) {
      row = const SizedBox(width: double.infinity);
    } else {
      row = ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          // A minimum, never a fixed height, so a large text scale grows the row (spec 3.10).
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: onBack != null ? 0 : AppSpacing.lg, end: AppSpacing.lg),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                if (onBack case final onBack?)
                  // The button keeps its 48 dp target in semantics, but lays out at the row's height, so a page with a
                  // back button has the same top as one without.
                  SizedBox(
                    width: kMinInteractiveDimension,
                    height: height,
                    child: OverflowBox(
                      maxHeight: kMinInteractiveDimension,
                      child: BackButton(color: colors.onSurface, onPressed: onBack),
                    ),
                  ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: accent == null ? MainAxisAlignment.start : MainAxisAlignment.end,
                    spacing: AppSpacing.sm,
                    children: [
                      if (accent != null)
                        // Decoration: the title beside it names the page, and the page names its level.
                        ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.all(Radius.circular(key / 4)),
                            ),
                            child: SizedBox.square(dimension: key),
                          ),
                        ),
                      if (title case final title?)
                        Flexible(
                          child: Text(title, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!statusStrip) return row;
    return Column(mainAxisSize: MainAxisSize.min, children: [const BazaarStatusStrip(), row]);
  }
}

/// The strip behind the system status bar, on the page's ground with icons that read on it.
class BazaarStatusStrip extends StatelessWidget {
  const BazaarStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: ColoredBox(
        color: context.bazaarColors.surface,
        child: SizedBox(width: double.infinity, height: MediaQuery.paddingOf(context).top),
      ),
    );
  }
}
