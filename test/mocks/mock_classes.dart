import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockContentRepository extends Mock implements IContentRepository {}

// Fake classes for fallback values
class FakeUri extends Fake implements Uri {}

/// Register all fallback values needed for mocktail's any() matcher.
/// Call this in setUpAll() for tests that use any() with non-nullable types.
void registerAllFallbackValues() {
  registerFallbackValue(FakeUri());
}
