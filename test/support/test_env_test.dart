@Tags(['widget'])
library;

import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Two runs on purpose: the flag set by the first must be gone in the second, cleared by the global TestEnv.reset.
  group('TestEnv.reset', () {
    test('a test sets a feature flag', () {
      FeatureFlagService.instance.updateFlags({'leaked_flag': true});

      expect(FeatureFlagService.instance.isEnabled('leaked_flag'), isTrue);
    });

    test('the next test starts without feature flags', () {
      expect(FeatureFlagService.instance.allFlags, isEmpty);
      expect(FeatureFlagService.instance.lastFetched, isNull);
    });
  });
}
