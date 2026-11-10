import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_texts.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/material.dart';

/// Asks before a backup file replaces a record that holds something (owner decision 10; the web replaces at once), with
/// the [local] count of module states; true for `Replace`, false when the dialog closes any other way.
Future<bool> showRestoreConfirmDialog(BuildContext context, Tally local) async {
  final replace = await showDialog<bool>(
    context: context,
    builder: (context) {
      final s = S.of(context);
      final theme = Theme.of(context);
      return AlertDialog(
        scrollable: true,
        title: Text(s.restore_confirm_title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Text(s.restore_confirm_holds),
            Text(tallyText(s, local.sheets), style: theme.textTheme.labelLarge),
            Text(s.restore_confirm_effect),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(s.restore_confirm_replace)),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.erase_keep)),
        ],
      );
    },
  );
  return replace ?? false;
}
