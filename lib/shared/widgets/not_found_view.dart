import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/utils/external_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Says the address is not a module, with a way back to the catalog and a way to the site (the web's 404 page,
/// `src/app/not-found.tsx`). The not-found page, the level page and the reader show it.
class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(l10n.not_found_title, style: textTheme.headlineSmall)),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.not_found_message, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              // The web's 404 links the catalog index, which is the For Engineers catalog root.
              FilledButton(onPressed: () => context.go(BazaarPaths.catalogEngineers), child: Text(l10n.nav_catalog)),
              OutlinedButton(
                onPressed: () => openExternalLink(context, context.read<WebLinks>().site),
                child: Text(l10n.open_on_the_web),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
