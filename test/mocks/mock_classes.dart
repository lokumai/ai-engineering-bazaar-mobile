import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

// Infrastructure mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockISecureStorage extends Mock implements ISecureStorage {}

// Fake classes for fallback values
class FakeUri extends Fake implements Uri {}

/// Register all fallback values needed for mocktail's any() matcher.
/// Call this in setUpAll() for tests that use any() with non-nullable types.
void registerAllFallbackValues() {
  registerFallbackValue(FakeUri());
}
