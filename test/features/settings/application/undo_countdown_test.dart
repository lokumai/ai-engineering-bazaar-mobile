import 'package:ai_engineering_bazaar/features/settings/application/undo_countdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 3, 15, 10);

  test('the full window is left at the instant of the erase', () {
    expect(undoSecondsLeft(at, at), 10);
  });

  test('a part of a second left counts as a whole second', () {
    expect(undoSecondsLeft(at, at.add(const Duration(milliseconds: 1))), 10);
    expect(undoSecondsLeft(at, at.add(const Duration(milliseconds: 1000))), 9);
    expect(undoSecondsLeft(at, at.add(const Duration(milliseconds: 9999))), 1);
  });

  test('nothing is left once the window has passed', () {
    expect(undoSecondsLeft(at, at.add(const Duration(milliseconds: 10000))), 0);
    expect(undoSecondsLeft(at, at.add(const Duration(seconds: 20))), 0);
  });

  test('a clock behind the erase never shows more than the window', () {
    expect(undoSecondsLeft(at, at.subtract(const Duration(seconds: 5))), 10);
  });
}
