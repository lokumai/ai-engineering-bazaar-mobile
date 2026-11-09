import 'package:ai_engineering_bazaar/features/progress/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/data_line.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/progress_view.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/quarantine_notice.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/restore_confirm_dialog.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/presentation/record_write_notice.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The progress page at `/profile` (web `src/app/profile/page.tsx:84-104`, Decision A8): [ProgressView] over the ready
/// content, with the content notice and the quarantine notice above the tabs, and the write notice and the data line
/// under the cards. The other content states draw nothing; they never mount, since the app gate mounts the router only
/// once the content is ready.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index, :final notice) => BlocProvider<DataBloc>(
        create: (context) => DataBloc(
          recordBloc: context.read<RecordBloc>(),
          gateway: context.read<IBackupGateway>(),
          repository: context.read<IRecordRepository>(),
        ),
        child: _ProgressWithData(index: index, notice: notice),
      ),
      ContentLoading() || ContentBroken() => const SizedBox.shrink(),
    };
  }
}

/// The page below its [DataBloc]: asks before a pending restore replaces the record.
class _ProgressWithData extends StatelessWidget {
  const _ProgressWithData({required this.index, required this.notice});

  final BundleIndex index;
  final ContentNotice? notice;

  @override
  Widget build(BuildContext context) {
    final (quarantineKept, writeState) = switch (context.watch<RecordBloc>().state) {
      RecordReady(:final quarantineKept, :final writeState) => (quarantineKept, writeState),
      RecordLoading() => (false, null),
    };
    final writeFailed = switch (writeState) {
      WriteQuota() || WriteBlocked() || WriteTooLarge() => true,
      WriteSaved() || WritePending() || null => false,
    };
    final above = [
      if (notice != null) ContentNoticeBanner(notice: notice),
      if (quarantineKept) const QuarantineNotice(),
    ];
    return BlocListener<DataBloc, DataState>(
      listenWhen: (previous, current) => previous.pendingRestore == null && current.pendingRestore != null,
      listener: (context, state) => _confirmRestore(context, state.pendingRestore!),
      child: ProgressView(
        index: index,
        aboveTabs: above.isEmpty
            ? null
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.lg, children: above),
        belowCards: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            if (writeFailed)
              RecordWriteNotice(
                writeState: writeState!,
                onBackUp: () => context.read<DataBloc>().add(const BackupRequested()),
              ),
            const DataLine(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, PendingRestore pending) async {
    final bloc = context.read<DataBloc>();
    final replace = await showRestoreConfirmDialog(context, pending.local);
    bloc.add(replace ? const RestoreConfirmed() : const RestoreDeclined());
  }
}
