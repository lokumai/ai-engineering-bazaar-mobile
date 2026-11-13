import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/settings/application/feedback_sender.dart';
import 'package:ai_engineering_bazaar/shared/utils/event_transformers.dart';

sealed class FeedbackEvent {
  const FeedbackEvent();
}

/// The reader sent [message] from Report a problem.
final class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted(this.message);

  final String message;
}

sealed class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => const [];
}

/// The reader is writing; nothing was sent yet.
final class FeedbackEditing extends FeedbackState {
  const FeedbackEditing();
}

/// The report is on its way.
final class FeedbackSending extends FeedbackState {
  const FeedbackSending();
}

/// The report was sent.
final class FeedbackSent extends FeedbackState {
  const FeedbackSent();
}

/// The report was not sent; the reader's text stays in the field to send again.
final class FeedbackFailed extends FeedbackState {
  const FeedbackFailed();
}

/// Sends what the reader wrote under Report a problem through [IFeedbackSender], one report at a time: a second tap
/// while one is on its way does nothing. An empty or blank text sends nothing.
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc({required this._sender}) : super(const FeedbackEditing()) {
    on<FeedbackSubmitted>(_onSubmitted, transformer: EventTransformers.dropConcurrent());
  }

  static final _log = AppLogger.getLogger('FeedbackBloc');

  final IFeedbackSender _sender;

  Future<void> _onSubmitted(FeedbackSubmitted event, Emitter<FeedbackState> emit) async {
    final message = event.message.trim();
    if (message.isEmpty) return;
    emit(const FeedbackSending());
    try {
      await _sender.send(message);
      emit(const FeedbackSent());
    } catch (error) {
      // Only the type: the error of a failed send can hold the reader's text.
      _log.warn('The report was not sent: {}', [error.runtimeType]);
      emit(const FeedbackFailed());
    }
  }
}
