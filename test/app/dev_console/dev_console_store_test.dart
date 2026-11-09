import 'package:flutter_bloc_advance/app/dev_console/dev_console_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Since DevConsoleStore is a singleton, we need to clear it between tests.
  late DevConsoleStore store;

  setUp(() {
    store = DevConsoleStore.instance;
    store.clearAll();
  });

  tearDown(() {
    store.clearAll();
  });

  BlocTransitionEntry createBlocEntry({
    String blocName = 'TestBloc',
    String event = 'TestEvent',
    String currentState = 'InitialState',
    String nextState = 'LoadedState',
    DateTime? timestamp,
  }) {
    return BlocTransitionEntry(
      blocName: blocName,
      event: event,
      currentState: currentState,
      nextState: nextState,
      timestamp: timestamp ?? DateTime(2026, 1, 1),
    );
  }

  group('DevConsoleStore', () {
    test('instance returns the same singleton', () {
      final store1 = DevConsoleStore.instance;
      final store2 = DevConsoleStore.instance;
      expect(identical(store1, store2), isTrue);
    });

    test('initial state has empty bloc entries', () {
      expect(store.blocEntries, isEmpty);
    });
  });

  group('BLoC transition entries', () {
    test('addBlocTransition adds an entry', () {
      store.addBlocTransition(createBlocEntry());

      expect(store.blocEntries, hasLength(1));
      expect(store.blocEntries.first.blocName, 'TestBloc');
    });

    test('addBlocTransition adds multiple entries', () {
      store.addBlocTransition(createBlocEntry(blocName: 'BlocA'));
      store.addBlocTransition(createBlocEntry(blocName: 'BlocB'));

      expect(store.blocEntries, hasLength(2));
    });

    test('blocEntries returns entries in reversed order (newest first)', () {
      store.addBlocTransition(createBlocEntry(event: 'Event1'));
      store.addBlocTransition(createBlocEntry(event: 'Event2'));
      store.addBlocTransition(createBlocEntry(event: 'Event3'));

      expect(store.blocEntries[0].event, 'Event3');
      expect(store.blocEntries[1].event, 'Event2');
      expect(store.blocEntries[2].event, 'Event1');
    });

    test('ring buffer enforces max 500 bloc entries', () {
      for (int i = 0; i < 510; i++) {
        store.addBlocTransition(createBlocEntry(event: 'Event_$i'));
      }

      expect(store.blocEntries, hasLength(500));
      expect(store.blocEntries.first.event, 'Event_509');
      expect(store.blocEntries.last.event, 'Event_10');
    });

    test('clearBloc removes all bloc entries', () {
      store.addBlocTransition(createBlocEntry());
      store.addBlocTransition(createBlocEntry());

      store.clearBloc();

      expect(store.blocEntries, isEmpty);
    });
  });

  group('clearAll', () {
    test('clears the bloc entries', () {
      store.addBlocTransition(createBlocEntry());

      store.clearAll();

      expect(store.blocEntries, isEmpty);
    });
  });

  group('Listener notifications', () {
    test('addBlocTransition notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.addBlocTransition(createBlocEntry());

      expect(callCount, 1);
    });

    test('clearAll notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.clearAll();

      expect(callCount, 1);
    });

    test('clearBloc notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.clearBloc();

      expect(callCount, 1);
    });
  });

  group('BlocTransitionEntry', () {
    test('stores all provided fields', () {
      final timestamp = DateTime(2026, 3, 14, 10, 30);
      final entry = BlocTransitionEntry(
        blocName: 'LoginBloc',
        event: 'LoginFormSubmitted',
        currentState: 'LoginInitial',
        nextState: 'LoginLoading',
        timestamp: timestamp,
      );

      expect(entry.blocName, 'LoginBloc');
      expect(entry.event, 'LoginFormSubmitted');
      expect(entry.currentState, 'LoginInitial');
      expect(entry.nextState, 'LoginLoading');
      expect(entry.timestamp, timestamp);
    });
  });
}
