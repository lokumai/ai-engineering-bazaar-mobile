import 'package:ai_engineering_bazaar/core/logging/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Faulty extends Cubit<int> {
  _Faulty() : super(0);

  void fail() => addError(StateError('a fault of the app'), StackTrace.current);
}

void main() {
  // Opus review 11, arch finding 1: addError reached only a log line, so the faults the blocs catch on purpose never
  // reached Sentry.
  test('an error a bloc reports goes to the report as well as the log', () async {
    final reported = <Object>[];
    final previous = Bloc.observer;
    Bloc.observer = AppBlocObserver(report: (error, _) => reported.add(error));
    addTearDown(() => Bloc.observer = previous);

    final cubit = _Faulty()..fail();
    expect(reported.single, isA<StateError>());
    await cubit.close();
  });

  test('with no report, an error is only logged', () async {
    final previous = Bloc.observer;
    Bloc.observer = AppBlocObserver();
    addTearDown(() => Bloc.observer = previous);

    final cubit = _Faulty()..fail();
    await cubit.close();
  });
}
