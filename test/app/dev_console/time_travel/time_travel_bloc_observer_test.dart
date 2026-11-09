import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_bloc_observer.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';
import 'package:flutter_bloc_advance/app/dev_console/dev_console_store.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Increment {}

final class _CounterBloc extends Bloc<_Increment, int> {
  _CounterBloc() : super(0) {
    on<_Increment>((event, emit) => emit(state + 1));
  }
}

void main() {
  late BlocObserver previousObserver;

  setUp(() {
    previousObserver = Bloc.observer;
    Bloc.observer = TimeTravelBlocObserver();
    DevConsoleStore.instance.clearAll();
    TimeTravelStore.instance.clear();
  });

  tearDown(() {
    Bloc.observer = previousObserver;
    DevConsoleStore.instance.clearAll();
    TimeTravelStore.instance.clear();
  });

  test('records a bloc transition in the BLoC and Time Travel stores', () async {
    final bloc = _CounterBloc()..add(_Increment());
    await bloc.stream.first;
    await bloc.close();

    final entry = DevConsoleStore.instance.blocEntries.single;
    expect(entry.blocName, '_CounterBloc');
    expect(entry.event, "Instance of '_Increment'");
    expect(entry.currentState, '0');
    expect(entry.nextState, '1');
    expect(TimeTravelStore.instance.snapshotsFor('_CounterBloc'), hasLength(1));
  });
}
