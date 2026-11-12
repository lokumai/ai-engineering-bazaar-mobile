import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/utils/animated_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/animated_bytes.dart';

void main() {
  group('isAnimatedImage, read from the bytes as the web reads them (web D136)', () {
    test('a WebP with the animation flag is animated', () => expect(isAnimatedImage(webpOf(flags: 0x02)), isTrue));

    test('a WebP with an ANIM chunk and no flag is animated', () {
      expect(isAnimatedImage(webpOf(chunks: ['ICCP', 'ANIM'])), isTrue);
    });

    test('a WebP with neither is still', () => expect(isAnimatedImage(webpOf(chunks: ['ICCP'])), isFalse));

    test('a GIF of two frames is animated, of one frame still', () {
      expect(isAnimatedImage(gifOf(2)), isTrue);
      expect(isAnimatedImage(gifOf(1)), isFalse);
    });

    test('a PNG, a cut file and no bytes are still', () {
      final png = File('test/fixtures/content/src/course-images/alpha/figure.png').readAsBytesSync();
      expect(isAnimatedImage(png), isFalse);
      expect(isAnimatedImage(Uint8List.sublistView(gifOf(2), 0, 20)), isFalse);
      expect(isAnimatedImage(Uint8List.sublistView(webpOf(flags: 0x02), 0, 18)), isFalse);
      expect(isAnimatedImage(Uint8List(0)), isFalse);
    });
  });
}
