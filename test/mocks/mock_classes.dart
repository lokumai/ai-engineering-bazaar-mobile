import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Infrastructure mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}

// Fake classes for fallback values
class FakeUri extends Fake implements Uri {}

/// Register all fallback values needed for mocktail's any() matcher.
/// Call this in setUpAll() for tests that use any() with non-nullable types.
void registerAllFallbackValues() {
  registerFallbackValue(FakeUri());
}
