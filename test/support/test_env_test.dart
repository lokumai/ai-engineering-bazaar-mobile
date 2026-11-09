@Tags(['widget'])
library;

import 'package:flutter_bloc_advance/app/dev_console/dev_console_store.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Two runs on purpose: the transitions left by the first must be gone in the second, cleared by the global
  // TestEnv.reset.
  group('TestEnv.reset', () {
    test('a test leaves a transition in both dev console stores', () {
      DevConsoleStore.instance.addBlocTransition(
        BlocTransitionEntry(
          blocName: 'LeakedBloc',
          event: 'E',
          currentState: 'A',
          nextState: 'B',
          timestamp: DateTime.utc(2026),
        ),
      );
      TimeTravelStore.instance.recordTransition(blocName: 'LeakedBloc', event: 'E', currentState: 0, nextState: 1);

      expect(DevConsoleStore.instance.blocEntries, hasLength(1));
    });

    test('the next test starts with both dev console stores empty', () {
      expect(DevConsoleStore.instance.blocEntries, isEmpty);
      expect(TimeTravelStore.instance.blocNames, isEmpty);
    });
  });
}
