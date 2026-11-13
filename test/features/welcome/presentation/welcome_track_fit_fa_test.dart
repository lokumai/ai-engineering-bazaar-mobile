@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'welcome_track_fit_harness.dart';

// As welcome_track_fit_test.dart, in Persian: Vazirmatn stands in for the phone's Persian face, under the family the
// Android theme falls back to, and as the display face's fallback.
void main() {
  setUpAll(() async {
    const vazirmatn = ['assets/fonts/Vazirmatn-Regular.ttf', 'assets/fonts/Vazirmatn-Bold.ttf'];
    await loadFace('Roboto', vazirmatn);
    await loadFace('Vazirmatn', vazirmatn);
    await loadFace('Fraunces', ['assets/fonts/Fraunces.ttf']);
  });

  testWidgets('the track step fits a phone without scrolling in fa', (tester) async {
    expect(await trackStepOverflow(tester, 'fa'), 0);
  });
}
