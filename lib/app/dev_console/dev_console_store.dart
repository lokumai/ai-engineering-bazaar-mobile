import 'dart:collection';

import 'package:flutter/foundation.dart';

/// In-memory ring buffer that stores dev console entries.
///
/// All data is stored only in debug mode and never persisted.
/// Uses [ChangeNotifier] so UI tabs can rebuild on new entries.
class DevConsoleStore extends ChangeNotifier {
  DevConsoleStore._();

  static final DevConsoleStore instance = DevConsoleStore._();

  // ---------------------------------------------------------------------------
  // BLoC state transitions
  // ---------------------------------------------------------------------------

  static const int _maxBlocEntries = 500;
  final _blocEntries = Queue<BlocTransitionEntry>();

  UnmodifiableListView<BlocTransitionEntry> get blocEntries => UnmodifiableListView(_blocEntries.toList().reversed);

  void addBlocTransition(BlocTransitionEntry entry) {
    _blocEntries.addLast(entry);
    while (_blocEntries.length > _maxBlocEntries) {
      _blocEntries.removeFirst();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  void clearAll() {
    _blocEntries.clear();
    notifyListeners();
  }

  void clearBloc() {
    _blocEntries.clear();
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class BlocTransitionEntry {
  BlocTransitionEntry({
    required this.blocName,
    required this.event,
    required this.currentState,
    required this.nextState,
    required this.timestamp,
  });

  final String blocName;
  final String event;
  final String currentState;
  final String nextState;
  final DateTime timestamp;
}
