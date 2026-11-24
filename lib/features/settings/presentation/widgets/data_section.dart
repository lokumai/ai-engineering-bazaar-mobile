import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_line.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/quarantine_notice.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/restore_confirm_dialog.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/presentation/record_write_notice.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The reader's data on the Settings page (plan 1AB; the web's `DataPanel.tsx` on `/profile`, Decision A8): the
/// quarantine notice, the write notice when a write failed, then the data line with Back up, Restore and Reset, and
/// the website line with Send to the website.
///
/// It reads the app's [DataBloc] (app_scope.dart: it outlives a tab switch, so a reset's Undo stays), and asks before a
/// pending restore replaces the record.
class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) => const _DataWithBloc();
}

class _DataWithBloc extends StatelessWidget {
  const _DataWithBloc();

  @override
  Widget build(BuildContext context) {
    final (quarantineKept, writeState, unread) = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final quarantineKept, :final writeState, :final launchReadFailed) => (
        quarantineKept,
        writeState,
        launchReadFailed,
      ),
      RecordLoading() => (false, null, false),
    };
    final writeFailed = switch (writeState) {
      WriteQuota() || WriteBlocked() || WriteTooLarge() => true,
      WriteSaved() || WritePending() || null => false,
    };
    return BlocListener<DataBloc, DataState>(
      listenWhen: (previous, current) => previous.pendingRestore == null && current.pendingRestore != null,
      listener: (context, state) => _confirmRestore(context, state.pendingRestore!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          if (quarantineKept) const QuarantineNotice(),
          if (writeFailed || unread)
            RecordWriteNotice(
              writeState: writeState!,
              launchReadFailed: unread,
              onReadAgain: () => context.read<RecordBloc>().add(const RecordReadAgain()),
              onBackUp: () => context.read<DataBloc>().add(const BackupRequested()),
            ),
          DataLine(),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, PendingRestore pending) async {
    final bloc = context.read<DataBloc>();
    final replace = await showRestoreConfirmDialog(context, pending.local);
    if (!bloc.isClosed) bloc.add(replace ? const RestoreConfirmed() : const RestoreDeclined());
  }
}
