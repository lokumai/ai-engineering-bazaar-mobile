import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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

  /// Resets the per-test environment: clears all storage and the
  /// process-wide [FeatureFlagService.instance]. No language is stored, so
  /// an `App` starts in the language passed to it, as on a first launch.
  /// Idempotent and cheap (in-memory).
  static Future<void> reset() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await AppLocalStorage().clear();
    FeatureFlagService.instance.clear();
  }
}
