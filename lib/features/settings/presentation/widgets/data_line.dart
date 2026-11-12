import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_texts.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/erase_dialog.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The data line of the Settings page (web `DataPanel.tsx:201-268`, Decision A8): the sentence, the buttons Back up,
/// Restore and Reset on one line and, while the reset can be undone, Undo, then the status lines in a live region.
///
/// Reset is drawn in on-surface (Decision A18) and asks through [showEraseDialog] first. Every action is off while a
/// flow of [DataBloc] runs.
class DataLine extends StatelessWidget {
  const DataLine({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final state = context.watch<DataBloc>().state;
    final bloc = context.read<DataBloc>();
    final idle = state.busy == DataBusy.idle;
    final lines = [
      if (state.backup case final backup?) backupLineText(s, backup),
      if (state.restore case final restore?) _restoreText(s, restore),
      if (state.reset case final reset?) _resetText(s, reset),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.data_line_text, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        // The three on one line, their names short so they fit a phone in every language (the owner, 2026-11-12);
        // at a large text size they wrap. Reset comes last, drawn apart in on-surface.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: idle ? () => bloc.add(const BackupRequested()) : null,
              child: Text(s.data_back_up),
            ),
            OutlinedButton(
              onPressed: idle ? () => bloc.add(const RestoreRequested()) : null,
              child: Text(s.data_restore),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
              onPressed: idle ? () => _reset(context) : null,
              child: Text(s.data_reset),
            ),
            if (state.reset is ResetCounting)
              OutlinedButton(onPressed: idle ? () => bloc.add(const UndoRequested()) : null, child: Text(s.data_undo)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (lines.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [for (final line in lines) Text(line, style: theme.textTheme.bodyMedium)],
            ),
          ),
      ],
    );
  }

  Future<void> _reset(BuildContext context) async {
    final bloc = context.read<DataBloc>();
    if (await showEraseDialog(context)) bloc.add(const ResetConfirmed());
  }

  static String _restoreText(S s, RestoreOutcome outcome) => switch (outcome) {
    RestoreOutcome.restored => s.data_restored,
    RestoreOutcome.empty => s.data_restore_empty,
    RestoreOutcome.newer => s.data_restore_newer,
    RestoreOutcome.malformed => s.data_restore_malformed,
    RestoreOutcome.unreadable => s.data_restore_unreadable,
  };

  static String _resetText(S s, ResetLine line) => switch (line) {
    ResetCounting(:final secondsLeft) => s.data_reset_counting(secondsLeft),
    ResetClosed() => s.data_reset_closed,
    ResetNotFinished() => s.data_reset_not_finished,
  };
}
