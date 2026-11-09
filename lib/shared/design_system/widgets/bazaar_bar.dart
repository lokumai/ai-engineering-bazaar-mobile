import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The cobalt bar over every page (spec 3.8: a custom widget, never on the page ground): a back button when [onBack]
/// is given, the Lokum logo and the app title. The shell places it over the router's pages, and Welcome's steps over
/// theirs, so every screen after the opening gate wears it (plan 1Z).
class BazaarBar extends StatelessWidget {
  const BazaarBar({super.key, this.onBack});

  /// Goes back to the page below; null shows no back button.
  final VoidCallback? onBack;

  /// The bar's least height: thinner than the mockup's 58 (plan 1R).
  static const double _height = 48;

  /// The logo's side at text scale 1; it grows with the title.
  static const double _logo = 26;

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(color: BazaarFixedColors.onBar);
    final logo = MediaQuery.textScalerOf(context).scale(_logo);
    // The status bar is drawn over the bar, navy in both themes, so its icons are light (plan 1J).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: BazaarFixedColors.bar,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            // A minimum, never a fixed height, so a large text scale grows the bar (spec 3.10).
            constraints: const BoxConstraints(minHeight: _height),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: canPop ? AppSpacing.xs : AppSpacing.lg,
                end: AppSpacing.lg,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  if (onBack case final onBack?) BackButton(color: BazaarFixedColors.onBar, onPressed: onBack),
                  // Decoration: the title beside it names the app.
                  ExcludeSemantics(
                    child: Image.asset(_logoAsset, width: logo, height: logo, filterQuality: FilterQuality.medium),
                  ),
                  Expanded(child: Text(S.of(context).app_title, style: style)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Lokum logo (`assets/brand/SOURCE.md`).
const _logoAsset = 'assets/brand/lokum_logo.webp';
