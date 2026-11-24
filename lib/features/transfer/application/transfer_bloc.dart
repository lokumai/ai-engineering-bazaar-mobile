import 'dart:async';

import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A progress transfer link opened in the app (plan 17.1): the progress it carries is read at once and shown, and added
/// to the record only when the reader asks, through the record's one queue ([TransferMerged]). Nothing on the phone is
/// removed or replaced.
final class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc({required String payload, required ITransferPacker packer, required this._recordBloc})
    : super(_read(payload, packer)) {
    on<TransferAddPressed>(_onAdd, transformer: EventTransformers.dropConcurrent());
  }

  final RecordBloc _recordBloc;

  static TransferState _read(String payload, ITransferPacker packer) {
    final progress = switch (packer.unpack(payload)) {
      final text? => decodeTransfer(text),
      null => null,
    };
    return switch (progress) {
      null => const TransferUnreadable(),
      final progress when progress.isEmpty => const TransferEmpty(),
      final progress => TransferReady(progress),
    };
  }

  /// Adds the progress when it is read and not added yet, or when it was not added, which can be tried again (review
  /// 9, finding 9).
  Future<void> _onAdd(TransferAddPressed event, Emitter<TransferState> emit) async {
    final progress = switch (state) {
      TransferReady(:final progress) => progress,
      TransferDone(:final progress, result: TransferMergeResult.notAdded) => progress,
      _ => null,
    };
    if (progress == null) return;
    emit(TransferAdding(progress));
    final reply = Completer<TransferMergeResult>();
    _recordBloc.add(TransferMerged(progress: progress, reply: reply));
    emit(TransferDone(progress, await reply.future));
  }
}

sealed class TransferEvent {
  const TransferEvent();
}

/// The reader asked to add the link's progress.
final class TransferAddPressed extends TransferEvent {
  const TransferAddPressed();
}

sealed class TransferState extends Equatable {
  const TransferState();

  @override
  List<Object?> get props => const [];
}

/// The link is not a transfer this app reads: nothing can be added.
final class TransferUnreadable extends TransferState {
  const TransferUnreadable();
}

/// The link carries no progress.
final class TransferEmpty extends TransferState {
  const TransferEmpty();
}

/// The link's [progress], read and not added yet.
final class TransferReady extends TransferState {
  const TransferReady(this.progress);

  final TransferProgress progress;

  @override
  List<Object?> get props => [progress];
}

/// [progress] being added.
final class TransferAdding extends TransferState {
  const TransferAdding(this.progress);

  final TransferProgress progress;

  @override
  List<Object?> get props => [progress];
}

/// What became of [progress].
final class TransferDone extends TransferState {
  const TransferDone(this.progress, this.result);

  final TransferProgress progress;
  final TransferMergeResult result;

  @override
  List<Object?> get props => [progress, result];
}
