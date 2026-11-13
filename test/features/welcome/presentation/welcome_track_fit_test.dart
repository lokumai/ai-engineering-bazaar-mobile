@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'welcome_track_fit_harness.dart';

// The owner, 2026-11-14: on a phone the whole first step of Welcome shows at once, with no scrolling. Measured in
// Roboto and Fraunces, loaded for this file alone, since a loaded face stays for the whole isolate.
void main() {
  setUpAll(() async {
    await loadFace('Roboto', robotoFiles());
    await loadFace('Fraunces', ['assets/fonts/Fraunces.ttf']);
  });

  for (final locale in ['en', 'tr']) {
    testWidgets('the track step fits a phone without scrolling in $locale', (tester) async {
      expect(await trackStepOverflow(tester, locale), 0);
    });
  }
}
