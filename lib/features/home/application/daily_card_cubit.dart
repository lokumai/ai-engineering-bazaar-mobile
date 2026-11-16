import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The day's card while its module's document is read (plan 11.1).
sealed class DailyCardState extends Equatable {
  const DailyCardState();

  @override
  List<Object?> get props => [];
}

/// The document is being read.
final class DailyCardLoading extends DailyCardState {
  const DailyCardLoading();
}

/// The card to show.
final class DailyCardShown extends DailyCardState {
  const DailyCardShown(this.card);

  final DailyCard card;

  @override
  List<Object?> get props => [card];
}

/// No card today: no module to take it from, or its document could not be read.
final class DailyCardNone extends DailyCardState {
  const DailyCardNone();
}

/// Reads the module of a [DailyChoice] from the course on this device and takes the day's card from it.
final class DailyCardCubit extends Cubit<DailyCardState> {
  DailyCardCubit({required this._repository}) : super(const DailyCardLoading());

  final IContentRepository _repository;

  static final _log = AppLogger.getLogger('DailyCardCubit');

  /// Shows the card of [choice]; none for a null choice.
  Future<void> load(DailyChoice? choice) async {
    if (choice == null) {
      emit(const DailyCardNone());
      return;
    }
    try {
      final doc = await _repository.readModuleDoc(choice.docPath);
      final card = dailyCardOf(doc, turn: choice.turn);
      if (!isClosed) emit(card == null ? const DailyCardNone() : DailyCardShown(card));
    } on Object catch (error) {
      // A document that cannot be read leaves Home without a card rather than with an error.
      _log.warn('no daily card from {}: {}', [choice.docPath, error]);
      if (!isClosed) emit(const DailyCardNone());
    }
  }
}
