import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_texts.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks before a backup file replaces a record that holds something (owner decision 10; the web replaces at once), with
/// the [local] count of module states; true for `Replace`, false when the dialog closes any other way.
///
/// The dialog reads [DataBloc] from [context], so it opens only below it. Its Back up, as the erase dialog's, saves
/// what the phone holds first and leaves the dialog open: Replace has no undo (review 9, finding 10). Its backup line
/// shows only for a Back up pressed in this dialog, since one made earlier may hold less (review 10, finding 9).
Future<bool> showRestoreConfirmDialog(BuildContext context, Tally local) async {
  final data = context.read<DataBloc>();
  final replace = await showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider<DataBloc>.value(
      value: data,
      child: _RestoreConfirmDialog(local: local),
    ),
  );
  return replace ?? false;
}

class _RestoreConfirmDialog extends StatefulWidget {
  const _RestoreConfirmDialog({required this.local});

  final Tally local;

  @override
  State<_RestoreConfirmDialog> createState() => _RestoreConfirmDialogState();
}

class _RestoreConfirmDialogState extends State<_RestoreConfirmDialog> {
  var _backedUpHere = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final data = context.watch<DataBloc>().state;
    return AlertDialog(
      scrollable: true,
      title: Text(s.restore_confirm_title),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          Text(s.restore_confirm_holds),
          Text(tallyText(s, widget.local.sheets), style: theme.textTheme.labelLarge),
          Text(s.restore_confirm_effect),
          if (data.backup case final backup? when _backedUpHere && data.busy == DataBusy.idle)
            Semantics(liveRegion: true, child: Text(backupLineText(s, backup))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(s.restore_confirm_replace)),
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.erase_keep)),
        TextButton(
          key: const ValueKey('restore-confirm-back-up'),
          onPressed: data.busy == DataBusy.idle
              ? () {
                  final bloc = context.read<DataBloc>();
                  if (bloc.isClosed) return;
                  setState(() => _backedUpHere = true);
                  bloc.add(const BackupRequested());
                }
              : null,
          child: Text(s.data_back_up),
        ),
      ],
    );
  }
}
