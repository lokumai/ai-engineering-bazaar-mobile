import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Where the caravan is, in months from the road's start: the one number the stage, the strip and the page share (the
/// web's `Journey`, `scene/journey.ts`).
///
/// [t] is the month at the centre of the stage. The stage eases [t] toward [target] each frame and says how fast it
/// moved ([velocity], months a second), so the puppets walk while it moves and turn round when it goes back. A drag
/// moves [t] itself; a stop chosen moves only [target], and the caravan walks there.
final class CaravanJourney extends ChangeNotifier {
  CaravanJourney({double at = 0}) : _t = at, _target = at;

  double _t;
  double _target;
  double _velocity = 0;

  double get t => _t;
  double get target => _target;
  double get velocity => _velocity;

  /// Whether the caravan still has a way to walk.
  bool get moving => (_target - _t).abs() > 0.0015;

  /// Sends the caravan to [month]; with [instant] it is there at once.
  void walkTo(double month, {bool instant = false}) {
    _target = month;
    if (instant) {
      _t = month;
      _velocity = 0;
    }
    notifyListeners();
  }

  /// Puts the caravan at [month] at once without telling the listeners, for a stage laid out anew; [announce] tells
  /// them after the frame.
  void place(double month) {
    _t = month;
    _target = month;
    _velocity = 0;
  }

  /// Tells the listeners where the caravan is.
  void announce() => notifyListeners();

  /// Puts the caravan at [month] at once, as a finger drags the road; the walk's pace is the drag's.
  void dragTo(double month, {required double dt}) {
    _velocity = dt > 0 ? (month - _t) / dt : 0;
    _t = month;
    _target = month;
    notifyListeners();
  }

  /// One frame of [dt] seconds: [t] eases toward [target] (the web's `1 - exp(-dt * 5.5)`), or is there at once when
  /// [reduced].
  void step(double dt, {bool reduced = false}) {
    final before = _t;
    if (reduced) {
      _t = _target;
    } else {
      _t += (_target - _t) * (1 - math.exp(-dt * 5.5));
      if ((_target - _t).abs() < 0.0015) _t = _target;
    }
    _velocity = dt > 0 ? (_t - before) / dt : 0;
    notifyListeners();
  }

  /// Settles the pace after a drag, so a caravan that stopped under the finger stands.
  void rest() {
    if (_velocity == 0) return;
    _velocity = 0;
    notifyListeners();
  }
}
