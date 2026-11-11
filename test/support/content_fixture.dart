/// The synthetic content bundle every widget and bloc test reads (spec 3.11), so no test writes down a fact about the
/// course. `tool/build_content_fixture.dart` generates it from `test/fixtures/content/src/`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_classes.dart';

const contentFixtureBundle = 'test/fixtures/content/bundle';

/// The `contentBaseUrl` every test runs with; an expected web URL in a test reads `https://content.test/...`.
const testContentBaseUrl = 'https://content.test/';

/// An asset bundle that serves `assets/content/<x>` from `test/fixtures/content/bundle/<x>`, so the code under test
/// reads the synthetic snapshot where the app reads the real one.
///
/// [overrides] maps an asset key to the text served instead. Any other key, and a fixture file that does not exist,
/// fails with a [FlutterError], as the platform bundle does. Files are read synchronously, so a `testWidgets` body
/// needs no `runAsync` to load them.
final class FixtureAssetBundle extends CachingAssetBundle {
  FixtureAssetBundle({this._overrides = const {}});

  static const _prefix = 'assets/content/';

  final Map<String, String> _overrides;

  @override
  Future<ByteData> load(String key) {
    final override = _overrides[key];
    if (override != null) return Future.value(_byteData(utf8.encode(override)));
    final file = key.startsWith(_prefix) ? File('$contentFixtureBundle/${key.substring(_prefix.length)}') : null;
    if (file == null || !file.existsSync()) return Future.error(FlutterError('Unable to load asset: "$key".'));
    return Future.value(_byteData(file.readAsBytesSync()));
  }

  static ByteData _byteData(List<int> bytes) => ByteData.sublistView(Uint8List.fromList(bytes));
}

/// A content repository that opens the fixture bundle (bundled, no notice) and whose refresh finds nothing newer.
MockContentRepository readyContentRepository() {
  final repository = MockContentRepository();
  final index = ContentParser.parseIndex(File('$contentFixtureBundle/index.json').readAsStringSync());
  when(() => repository.open())
      .thenAnswer((_) async => ContentOpening(index: index, origin: ContentOrigin.bundled, notice: null));
  when(() => repository.refresh()).thenAnswer((_) async => const ContentUpToDate());
  return repository;
}

/// A record repository whose launch read finds no record and whose every write and file operation succeeds.
MockRecordRepository readyRecordRepository() {
  final repository = MockRecordRepository();
  when(() => repository.load()).thenAnswer((_) async => const RecordLoadEmpty(quarantineKept: false));
  when(() => repository.write(any())).thenAnswer((_) async => WriteResult.saved);
  when(() => repository.readStored()).thenAnswer((_) async => const StoredBytes(record: null, quarantine: null));
  when(() => repository.deleteAll()).thenAnswer((_) async {});
  when(() => repository.restore(any()))
      .thenAnswer((_) async => const RestoreResult(write: WriteResult.saved, quarantineKept: false));
  when(() => repository.deleteQuarantine()).thenAnswer((_) async {});
  return repository;
}

/// A welcome store that says Welcome was seen, so the app opens on Home.
final class SeenWelcomeStore implements IWelcomeStore {
  const SeenWelcomeStore();

  @override
  Future<bool> seen() async => true;

  @override
  Future<void> markSeen() async {}
}

/// App dependencies for widget tests: the test config with [testContentBaseUrl], [readyContentRepository],
/// [readyRecordRepository] and a [SeenWelcomeStore], so no test opens the bundled snapshot, calls `path_provider`,
/// touches the record files or reaches the network, and the app opens on Home.
class FixtureAppDependencies extends AppDependencies {
  const FixtureAppDependencies({super.appConfig = const AppConfig.test(contentBaseUrl: testContentBaseUrl)});

  @override
  IContentRepository createContentRepository() => readyContentRepository();

  @override
  IRecordRepository createRecordRepository() => readyRecordRepository();

  @override
  IWelcomeStore createWelcomeStore() => const SeenWelcomeStore();

  @override
  ITrackStore createTrackStore() => const MemoryTrackStore();

  @override
  ILanguageStore createLanguageStore() => const MemoryLanguageStore();

  @override
  IQuizScoreStore createQuizScoreStore() => MemoryQuizScoreStore();

  @override
  IReadingPlaceStore createReadingPlaceStore() => MemoryReadingPlaceStore();
}
