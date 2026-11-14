import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:ai_engineering_bazaar/core/analytics/analytics_service.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/settings/application/feedback_sender.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/analytics/sentry_feedback.dart';
import 'package:ai_engineering_bazaar/infrastructure/app_icon/app_icon_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/backup/platform_backup_gateway.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/flags/file_flag_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/text/file_text_store.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
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

  /// The chosen language, as file flags under [supportDirectory]`/flags/`, apart from the record (plan 1Q).
  ILanguageStore createLanguageStore() => FlagLanguageStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The chosen look (light or dark), as file flags under [supportDirectory]`/flags/`, apart from the record.
  IThemeStore createThemeStore() => FlagThemeStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The chosen app icon, as file flags under [supportDirectory]`/flags/`, apart from the record.
  IAppIconStore createAppIconStore() => FlagAppIconStore(FileFlagStore(baseDirectory: supportDirectory));

  /// Whether the pocket model's round button is hidden, as a file flag under [supportDirectory]`/flags/` (plan 9.9).
  IPocketButtonStore createPocketButtonStore() => FlagPocketButtonStore(FileFlagStore(baseDirectory: supportDirectory));

  /// Puts the chosen app icon on the home screen, over the native channel.
  IAppIconSwitch createAppIconSwitch() => const ChannelAppIconSwitch(AppIconChannel());

  /// The quiz scores, as one file under [supportDirectory]`/quiz/scores.json`, apart from the record (plan 1W).
  IQuizScoreStore createQuizScoreStore() =>
      FileQuizScoreStore(FileTextStore(baseDirectory: supportDirectory, path: 'quiz/scores.json'));

  /// Where each module was left, as one file under [supportDirectory]`/reading/places.json`, apart from the record
  /// (plan 1BA).
  IReadingPlaceStore createReadingPlaceStore() =>
      FileReadingPlaceStore(FileTextStore(baseDirectory: supportDirectory, path: 'reading/places.json'));

  /// Home's pocket model, as one file under [supportDirectory]`/toy/pocket_model.json`, apart from the record
  /// (plan 9.2).
  IPocketModelStore createPocketModelStore() =>
      FilePocketModelStore(FileTextStore(baseDirectory: supportDirectory, path: 'toy/pocket_model.json'));

  /// The robot's outfit, as one file under [supportDirectory]`/toy/outfit.json`, apart from the record (plan 9.9).
  IRobotOutfitStore createRobotOutfitStore() =>
      FileRobotOutfitStore(FileTextStore(baseDirectory: supportDirectory, path: 'toy/outfit.json'));

  /// Report a problem's sender, over Sentry's user feedback; Settings shows the page only when Sentry is on.
  IFeedbackSender createFeedbackSender() => const SentryFeedbackSender();
}

/// Report a problem's port over Sentry's user feedback ([sendSentryFeedback]).
final class SentryFeedbackSender implements IFeedbackSender {
  const SentryFeedbackSender();

  @override
  Future<void> send(String message) => sendSentryFeedback(message);
}

/// The reading places' port over one text file of the app's own.
final class FileReadingPlaceStore implements IReadingPlaceStore {
  const FileReadingPlaceStore(this._file);

  final FileTextStore _file;

  @override
  Future<Map<String, ReadingPlace>> load() async {
    final text = await _file.read();
    return text == null ? const {} : decodeReadingPlaces(text);
  }

  @override
  Future<void> save(Map<String, ReadingPlace> places) =>
      places.isEmpty ? _file.delete() : _file.write(encodeReadingPlaces(places));
}

/// The pocket model's port over one text file of the app's own.
final class FilePocketModelStore implements IPocketModelStore {
  const FilePocketModelStore(this._file);

  final FileTextStore _file;

  @override
  Future<PocketModel?> load() async {
    final text = await _file.read();
    return text == null ? null : decodePocketModel(text);
  }

  @override
  Future<void> save(PocketModel model) => _file.write(encodePocketModel(model));
}

/// The quiz scores' port over one text file of the app's own.
final class FileQuizScoreStore implements IQuizScoreStore {
  const FileQuizScoreStore(this._file);

  final FileTextStore _file;

  @override
  Future<Map<String, QuizScore>> load() async {
    final text = await _file.read();
    return text == null ? const {} : decodeQuizScores(text);
  }

  @override
  Future<void> save(Map<String, QuizScore> scores) =>
      scores.isEmpty ? _file.delete() : _file.write(encodeQuizScores(scores));
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

/// The language cubit's port over the app's file flags: `language-<code>` for the chosen language, at most one set.
/// No flag set means no language was chosen yet.
final class FlagLanguageStore implements ILanguageStore {
  const FlagLanguageStore(this._flags);

  final FileFlagStore _flags;

  static String _flag(String language) => 'language-$language';

  @override
  Future<String?> chosen() async {
    for (final language in LanguageCubit.supported) {
      if (await _flags.isSet(_flag(language))) return language;
    }
    return null;
  }

  @override
  Future<void> choose(String language) async {
    for (final other in LanguageCubit.supported) {
      if (other != language) await _flags.clear(_flag(other));
    }
    await _flags.set(_flag(language));
  }
}

/// The pocket button's port over the app's file flags: `pocket-button-hidden` set when the reader hid it.
final class FlagPocketButtonStore implements IPocketButtonStore {
  const FlagPocketButtonStore(this._flags);

  final FileFlagStore _flags;

  static const _flag = 'pocket-button-hidden';

  @override
  Future<bool> hidden() => _flags.isSet(_flag);

  @override
  Future<void> hide({required bool hidden}) => hidden ? _flags.set(_flag) : _flags.clear(_flag);
}

/// The robot's outfit in one text file.
final class FileRobotOutfitStore implements IRobotOutfitStore {
  const FileRobotOutfitStore(this._file);

  final FileTextStore _file;

  @override
  Future<RobotOutfit?> load() async {
    final text = await _file.read();
    return text == null ? null : decodeRobotOutfit(text);
  }

  @override
  Future<void> save(RobotOutfit outfit) => _file.write(encodeRobotOutfit(outfit));
}

/// The theme cubit's port over the app's file flags: `theme-light` or `theme-dark`, at most one set. No flag set means
/// no choice was made, or the phone was chosen.
final class FlagThemeStore implements IThemeStore {
  const FlagThemeStore(this._flags);

  final FileFlagStore _flags;

  static const _explicit = {ThemeMode.light: 'theme-light', ThemeMode.dark: 'theme-dark'};

  @override
  Future<ThemeMode?> chosen() async {
    for (final entry in _explicit.entries) {
      if (await _flags.isSet(entry.value)) return entry.key;
    }
    return null;
  }

  @override
  Future<void> choose(ThemeMode mode) async {
    for (final entry in _explicit.entries) {
      if (entry.key != mode) await _flags.clear(entry.value);
    }
    final flag = _explicit[mode];
    if (flag != null) await _flags.set(flag);
  }
}

/// The app icon cubit's store over the app's file flags: `app-icon-<name>` for the chosen icon, at most one set. No
/// flag set means no icon was chosen yet.
final class FlagAppIconStore implements IAppIconStore {
  const FlagAppIconStore(this._flags);

  final FileFlagStore _flags;

  static String _flag(BazaarIcon icon) => 'app-icon-${icon.name}';

  @override
  Future<BazaarIcon?> chosen() async {
    for (final icon in BazaarIcon.values) {
      if (await _flags.isSet(_flag(icon))) return icon;
    }
    return null;
  }

  @override
  Future<void> choose(BazaarIcon icon) async {
    for (final other in BazaarIcon.values) {
      if (other != icon) await _flags.clear(_flag(other));
    }
    await _flags.set(_flag(icon));
  }
}

/// The app icon cubit's switch over the native channel, which names each icon by its [BazaarIcon.name].
final class ChannelAppIconSwitch implements IAppIconSwitch {
  const ChannelAppIconSwitch(this._channel);

  final AppIconChannel _channel;

  @override
  Future<void> choose(BazaarIcon icon) => _channel.choose(icon.name);
}
