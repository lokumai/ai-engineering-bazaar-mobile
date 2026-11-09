import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:ai_engineering_bazaar/core/analytics/analytics_service.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/backup/platform_backup_gateway.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/flags/file_flag_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';

/// Builds the infrastructure the app runs on; a test subclass overrides the factories with doubles.
class AppDependencies {
  const AppDependencies({
    this.appConfig = const AppConfig.dev(),
    @visibleForTesting this.cacheDirectory = getApplicationCacheDirectory,
    @visibleForTesting this.supportDirectory = getApplicationSupportDirectory,
  });

  final AppConfig appConfig;

  /// Where the downloaded content is stored; resolved by the repository's `open()`, not here.
  final Future<Directory> Function() cacheDirectory;

  /// Where the record is stored (spec 3.3.9); resolved by the record repository on first use, not here.
  final Future<Directory> Function() supportDirectory;

  /// Crash reporting logs through this on the device; Sentry's own hooks report crashes when a DSN is set.
  IAnalyticsService createAnalyticsService() => LogAnalyticsService();

  /// The content repository over the bundled snapshot, the cache directory and the site at
  /// [AppConfig.contentBaseUrl]; built synchronously, it touches no file until `open()`.
  IContentRepository createContentRepository() => FileContentRepository(
    bundled: BundledContent(bundle: rootBundle),
    cacheDirectory: cacheDirectory,
    http: ContentHttp(client: http.Client(), contentBaseUrl: appConfig.contentBaseUrl),
  );

  /// The record repository over files under [supportDirectory]`/record/`; it touches no file until first use.
  IRecordRepository createRecordRepository() => FileRecordRepository(baseDirectory: supportDirectory);

  /// The backup gateway over the platform's save dialog and file picker; it opens nothing until called.
  IBackupGateway createBackupGateway() => PlatformBackupGateway();

  /// Whether Welcome was seen, as a file flag under [supportDirectory]`/flags/`, apart from the record.
  IWelcomeStore createWelcomeStore() => FlagWelcomeStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The chosen track, as file flags under [supportDirectory]`/flags/`, apart from the record (plan 1L).
  ITrackStore createTrackStore() => FlagTrackStore(FileFlagStore(baseDirectory: supportDirectory));
}

/// The welcome feature's port over the app's file flags: the flag `welcome-2-seen`. Welcome 2 asks for the track
/// (plan 1L), so a reader who saw the first Welcome (`welcome-seen`) sees it once more.
final class FlagWelcomeStore implements IWelcomeStore {
  const FlagWelcomeStore(this._flags);

  final FileFlagStore _flags;

  static const _flag = 'welcome-2-seen';

  @override
  Future<bool> seen() => _flags.isSet(_flag);

  @override
  Future<void> markSeen() => _flags.set(_flag);
}

/// The track cubit's port over the app's file flags: `track-chosen` once a track was chosen, and `track-everyone` while
/// that choice is For Everyone.
final class FlagTrackStore implements ITrackStore {
  const FlagTrackStore(this._flags);

  final FileFlagStore _flags;

  static const _chosen = 'track-chosen';
  static const _everyone = 'track-everyone';

  @override
  Future<Track?> chosen() async {
    if (!await _flags.isSet(_chosen)) return null;
    return await _flags.isSet(_everyone) ? Track.everyone : Track.engineers;
  }

  @override
  Future<void> choose(Track track) async {
    if (track == Track.everyone) {
      await _flags.set(_everyone);
    } else {
      await _flags.clear(_everyone);
    }
    await _flags.set(_chosen);
  }
}
