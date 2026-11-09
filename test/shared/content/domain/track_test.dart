import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromId finds the two known tracks', () {
    expect(Track.fromId('engineers'), Track.engineers);
    expect(Track.fromId('everyone'), Track.everyone);
  });

  test('fromId returns null for a track this app does not know', () {
    expect(Track.fromId('future'), isNull);
  });

  test('other swaps the two tracks', () {
    expect(Track.engineers.other, Track.everyone);
    expect(Track.everyone.other, Track.engineers);
  });

  test('id is the bundle id', () {
    expect(Track.engineers.id, 'engineers');
    expect(Track.everyone.id, 'everyone');
  });
}
