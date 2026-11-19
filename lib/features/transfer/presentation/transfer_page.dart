import 'package:ai_engineering_bazaar/features/transfer/application/transfer_bloc.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/readable_width.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A progress transfer link opened in the app (plan 17.1), full screen over the shell: what the link carries, by
/// track, and one button that adds it to this phone's progress. Nothing is added until the reader presses it.
class TransferPage extends StatelessWidget {
  const TransferPage({super.key, required this.payload});

  /// The link's `t`, as it came.
  final String payload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransferBloc>(
      create: (context) => TransferBloc(
        payload: payload,
        packer: context.read<ITransferPacker>(),
        recordBloc: context.read<RecordBloc>(),
      ),
      child: const _TransferView(),
    );
  }
}

class _TransferView extends StatelessWidget {
  const _TransferView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final state = context.watch<TransferBloc>().state;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted);
    final progress = switch (state) {
      TransferReady(:final progress) || TransferAdding(:final progress) || TransferDone(:final progress) => progress,
      TransferUnreadable() || TransferEmpty() => null,
    };
    final line = switch (state) {
      TransferUnreadable() => s.transfer_unreadable,
      TransferEmpty() => s.transfer_empty,
      TransferDone(result: TransferMergeResult.added) => s.transfer_added,
      TransferDone(result: TransferMergeResult.nothingNew) => s.transfer_nothing_new,
      TransferDone(result: TransferMergeResult.notAdded) => s.transfer_not_added,
      TransferReady() || TransferAdding() => null,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ReadableWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  s.transfer_title,
                  style: theme.textTheme.headlineMedium?.copyWith(color: colors.onSurfaceTitle),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (progress != null) ...[
                for (final (track, name) in [(Track.engineers, s.track_engineers), (Track.everyone, s.track_everyone)])
                  MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        spacing: AppSpacing.md,
                        children: [
                          Icon(Icons.check_circle_outline, color: colors.primary),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                                Text(s.transfer_completed(progress.completed(track)), style: muted),
                                if (progress.ticked(track) > 0)
                                  Text(s.transfer_ticked(progress.ticked(track)), style: muted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(s.transfer_keeps, style: muted),
                const SizedBox(height: AppSpacing.lg),
                if (state is! TransferDone)
                  FilledButton(
                    key: const ValueKey('transfer-add'),
                    onPressed: state is TransferReady
                        ? () => context.read<TransferBloc>().add(const TransferAddPressed())
                        : null,
                    child: Text(s.transfer_add),
                  ),
              ],
              if (line != null)
                Semantics(
                  liveRegion: true,
                  child: Text(line, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceTitle)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
