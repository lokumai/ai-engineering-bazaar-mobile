import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Asks before the set-aside record is deleted (spec 3.3.9); true for `Delete`, false when the dialog closes any other
/// way.
Future<bool> showQuarantineDeleteDialog(BuildContext context) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (context) {
      final s = S.of(context);
      return AlertDialog(
        scrollable: true,
        title: Text(s.quarantine_delete_title),
        content: Text(s.quarantine_delete_body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(s.quarantine_delete_confirm)),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.quarantine_keep)),
        ],
      );
    },
  );
  return delete ?? false;
}
