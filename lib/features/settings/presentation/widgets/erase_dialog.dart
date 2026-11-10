import 'package:ai_engineering_bazaar/features/progress/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/data_texts.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks before the reset erases the record (web `EraseDialog.tsx:141-197`, spec 3.3.11); true once the reader typed
/// the erase word and chose `Erase all data`, false when the dialog closes any other way.
///
/// The dialog reads [DataBloc] and [RecordBloc] from [context], so it opens only below both. Its Back up runs the data
/// line's backup and leaves the dialog open. The typed text lives in the dialog and is gone once it closes.
Future<bool> showEraseDialog(BuildContext context) async {
  final data = context.read<DataBloc>();
  final record = context.read<RecordBloc>();
  final erase = await showDialog<bool>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<DataBloc>.value(value: data),
        BlocProvider<RecordBloc>.value(value: record),
      ],
      child: const _EraseDialog(),
    ),
  );
  return erase ?? false;
}

class _EraseDialog extends StatefulWidget {
  const _EraseDialog();

  @override
  State<_EraseDialog> createState() => _EraseDialogState();
}

class _EraseDialogState extends State<_EraseDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final fault = context.bazaarColors.fault;
    final onSurface = theme.colorScheme.onSurface;
    final data = context.watch<DataBloc>().state;
    final sheets = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final record) => tally(record).sheets,
      RecordLoading() => null,
    };
    final armed = confirmsErase(_typed.text);
    return AlertDialog(
      scrollable: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Text(s.erase_mark, style: theme.textTheme.labelSmall?.copyWith(color: onSurface)),
          Text(s.erase_title),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          if (sheets != null) Text(tallyText(s, sheets), style: theme.textTheme.labelLarge),
          Text(s.erase_scope),
          Text(s.erase_backup_statement),
          TextField(
            controller: _typed,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: s.erase_field_label),
            onChanged: (_) => setState(() {}),
          ),
          if (data.backup case final backup?) Semantics(liveRegion: true, child: Text(backupLineText(s, backup))),
        ],
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: onSurface,
            side: BorderSide(color: fault),
          ),
          onPressed: armed ? () => Navigator.of(context).pop(true) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              Icon(Icons.delete_forever_outlined, color: fault, size: 18),
              Flexible(child: Text(s.erase_confirm)),
            ],
          ),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.erase_keep)),
        TextButton(
          onPressed: data.busy == DataBusy.idle ? () => context.read<DataBloc>().add(const BackupRequested()) : null,
          child: Text(s.data_back_up),
        ),
      ],
    );
  }
}
