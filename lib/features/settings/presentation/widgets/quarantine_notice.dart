import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/quarantine_delete_dialog.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The notice that a stored record is set aside (spec 3.3.9; web `ProfilePanels.tsx:17-49`), shown while
/// `record-quarantine.json` exists: a readout and a note by the launch read's reason, then `Save a copy` and `Delete
/// it`, which the web does not offer. Nothing while no record is set aside.
///
/// Its text is on-surface and the fault colour marks only its edge (Decision A18). The actions are off while a flow of
/// [DataBloc] runs.
class QuarantineNotice extends StatelessWidget {
  const QuarantineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final QuarantineReason? reason;
    switch (context.watch<RecordBloc>().state) {
      case RecordReady(quarantineKept: true, :final quarantine):
        reason = quarantine;
      case RecordReady() || RecordLoading():
        return const SizedBox.shrink();
    }
    final s = S.of(context);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final state = context.watch<DataBloc>().state;
    final idle = state.busy == DataBusy.idle;
    final (readout, note) = switch (reason) {
      QuarantineReason.newer => (s.quarantine_newer_readout, s.quarantine_newer_note),
      QuarantineReason.malformed => (s.quarantine_malformed_readout, s.quarantine_malformed_note),
      null => (s.quarantine_kept_readout, s.quarantine_kept_note),
    };
    final copyLine = switch (state.quarantineCopy) {
      QuarantineCopy.saved => s.quarantine_copy_saved,
      QuarantineCopy.notWritten => s.quarantine_copy_not_written,
      null => null,
    };
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: s.quarantine_label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(width: 2, color: context.bazaarColors.fault)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(readout, style: theme.textTheme.labelSmall?.copyWith(color: onSurface)),
              Text(note, style: theme.textTheme.bodyMedium?.copyWith(color: onSurface)),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  TextButton(
                    onPressed: idle ? () => context.read<DataBloc>().add(const QuarantineExportRequested()) : null,
                    child: Text(s.quarantine_save_copy),
                  ),
                  TextButton(onPressed: idle ? () => _delete(context) : null, child: Text(s.quarantine_delete)),
                ],
              ),
              if (copyLine != null)
                Semantics(
                  liveRegion: true,
                  child: Text(copyLine, style: theme.textTheme.bodyMedium?.copyWith(color: onSurface)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<DataBloc>();
    if (await showQuarantineDeleteDialog(context)) bloc.add(const QuarantineDeleteConfirmed());
  }
}
