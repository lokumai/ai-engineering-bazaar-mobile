import 'dart:math' as math;

import 'package:ai_engineering_bazaar/shared/record/domain/record_constants.dart';

/// The whole seconds left to undo the erase made at [erasedAt], seen at [now] (web `erase.ts:114-119`).
///
/// 0 once the window has passed, else the remaining time rounded up to a whole second and never above the window.
int undoSecondsLeft(DateTime erasedAt, DateTime now) {
  final window = RecordConstants.undoWindow;
  final remaining = window.inMilliseconds - now.difference(erasedAt).inMilliseconds;
  if (remaining <= 0) return 0;
  return math.min(window.inSeconds, (remaining / 1000).ceil());
}
