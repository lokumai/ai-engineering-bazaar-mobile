import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockContentRepository extends Mock implements IContentRepository {}

class MockRecordRepository extends Mock implements IRecordRepository {}

// Fake classes for fallback values
class FakeUri extends Fake implements Uri {}

/// Register all fallback values needed for mocktail's any() matcher.
/// Call this in setUpAll() for tests that use any() with non-nullable types.
void registerAllFallbackValues() {
  registerFallbackValue(FakeUri());
  registerFallbackValue(const StoredBytes(record: null, quarantine: null));
}
