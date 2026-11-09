import 'dart:typed_data';

import 'package:ai_engineering_bazaar/features/progress/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContentRepository extends Mock implements IContentRepository {}

class MockRecordRepository extends Mock implements IRecordRepository {}

class MockBackupGateway extends Mock implements IBackupGateway {}

class MockDataBloc extends MockBloc<DataEvent, DataState> implements DataBloc {}

class MockModuleReaderBloc extends MockBloc<ReaderEvent, ReaderState> implements ModuleReaderBloc {}

// Fake classes for fallback values
class FakeUri extends Fake implements Uri {}

/// Register all fallback values needed for mocktail's any() matcher.
/// Call this in setUpAll() for tests that use any() with non-nullable types.
void registerAllFallbackValues() {
  registerFallbackValue(FakeUri());
  registerFallbackValue(const StoredBytes(record: null, quarantine: null));
  registerFallbackValue(const ReaderCompletionToggled());
  registerFallbackValue(const CompletionToggled(key: 'alpha/first', revision: null, track: Track.engineers));
  registerFallbackValue(const RecordStarted());
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(const BackupRequested());
  registerFallbackValue(const ContentStarted());
}
