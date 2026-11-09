import 'package:ai_engineering_bazaar/shared/content/domain/css_colour.dart';
import 'package:flutter_test/flutter_test.dart';

import 'content_test_data.dart';

void main() {
  test('white is opaque white', () {
    expect(parseCssColour('white', path: 'p'), 0xFFFFFFFF);
  });

  test('#rgb doubles each digit', () {
    expect(parseCssColour('#333', path: 'p'), 0xFF333333);
  });

  test('#rrggbb is read as is', () {
    expect(parseCssColour('#ffffff', path: 'p'), 0xFFFFFFFF);
  });

  test('hex digits are read in either case', () {
    expect(parseCssColour('#1A2b3C', path: 'p'), 0xFF1A2B3C);
  });

  for (final text in ['black', '#12345', '#ffffffff', 'rgb(0, 0, 0)', ' white', '']) {
    test('rejects "$text"', () {
      expect(() => parseCssColour(text, path: 'p'), throwsA(formatError('p', 'colour')));
    });
  }
}
