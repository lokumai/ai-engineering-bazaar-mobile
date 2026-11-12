import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// The line that says what startup did to the content (spec 3.4.3 step 3), on the progress page and Settings; nothing
/// when there is no [notice].
class ContentNoticeBanner extends StatelessWidget {
  const ContentNoticeBanner({super.key, required this.notice});

  final ContentNotice? notice;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = switch (notice) {
      ContentNotice.cacheDiscarded => s.content_notice_cache_discarded,
      null => null,
    };
    if (text == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(width: 2, color: context.bazaarColors.lineStrong)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
        child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
      ),
    );
  }
}
