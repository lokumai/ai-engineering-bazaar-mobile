import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the caravan stands and whether it tours the road on its own.
sealed class CaravanState extends Equatable {
  const CaravanState(this.selected);

  /// The chosen stop, from 0 in the order the trends start.
  final int selected;

  @override
  List<Object?> get props => [selected];
}

/// The caravan stands at [selected] until the reader moves it.
final class CaravanResting extends CaravanState {
  const CaravanResting(super.selected);
}

/// The caravan walks the road on its own, one stop every [CaravanCubit.dwell]; it is at [selected] now.
final class CaravanTouring extends CaravanState {
  const CaravanTouring(super.selected);
}

/// The Caravan's journey: the stop the reader chose, kept in memory while the app runs, so the tab opens where the
/// caravan was left; and the tour, which walks to the next stop every [dwell] and rests at the last.
///
/// The road's length is passed with each call, since the road is drawn from the trends of the page's language. Any
/// move the reader makes ends a tour. A `Cubit` because each call is atomic and the event stream adds nothing.
final class CaravanCubit extends Cubit<CaravanState> {
  CaravanCubit({this.dwell = const Duration(milliseconds: 2600)}) : super(const CaravanResting(0));

  /// How long the tour stays at a stop: the walk there and time to read the title.
  final Duration dwell;

  Timer? _tour;

  /// Chooses the stop [index] of [count]; a tour ends.
  void select(int index, {required int count}) {
    _stopTour();
    if (count <= 0) return;
    emit(CaravanResting(index.clamp(0, count - 1)));
  }

  /// The next stop of [count], if any.
  void next({required int count}) => select(state.selected + 1, count: count);

  /// The stop before.
  void previous({required int count}) => select(state.selected - 1, count: count);

  /// Tours the road: the caravan walks at once to the stop after the chosen one (to the first when it stands at the
  /// last), then on every [dwell], and rests after the last.
  void tour({required int count}) {
    if (count <= 0) return;
    _stopTour();
    emit(CaravanTouring(state.selected >= count - 1 ? 0 : state.selected + 1));
    _tour = Timer.periodic(dwell, (_) {
      if (state.selected >= count - 1) {
        _stopTour();
        emit(CaravanResting(state.selected));
      } else {
        emit(CaravanTouring(state.selected + 1));
      }
    });
  }

  /// Ends a tour where the caravan is.
  void rest() {
    _stopTour();
    if (state is CaravanTouring) emit(CaravanResting(state.selected));
  }

  void _stopTour() {
    _tour?.cancel();
    _tour = null;
  }

  @override
  Future<void> close() {
    _stopTour();
    return super.close();
  }
}
