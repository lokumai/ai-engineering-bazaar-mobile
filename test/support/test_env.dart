import 'package:ai_engineering_bazaar/app/dev_console/dev_console_store.dart';
import 'package:ai_engineering_bazaar/app/dev_console/time_travel/time_travel_store.dart';

/// Static test-support harness. Replaces the old instance-based `TestUtils`.
///
/// One-time global config and the per-test reset are wired in
/// `test/flutter_test_config.dart`. Individual test files normally need
/// nothing; files that install their own channel mocks opt out with
/// `setUpAll(() => TestEnv.autoReset = false);`.
class TestEnv {
  TestEnv._();

  /// When false, the global setUp/tearDown in flutter_test_config skip
  /// [reset]. Set in a file's `setUpAll` for tests that install their own
  /// MethodChannel handler (per-file isolate, so it never leaks). Defaults
  /// to true at isolate start.
  static bool autoReset = true;

  /// Resets the per-test environment: clears the process-wide
  /// [DevConsoleStore.instance] and [TimeTravelStore.instance].
  /// Idempotent and cheap (in-memory).
  static Future<void> reset() async {
    DevConsoleStore.instance.clearAll();
    TimeTravelStore.instance.clear();
  }
}
